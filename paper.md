---
title: "Admission Control for LLM Inference Serving: A Systematic Review"
author: Harshul Jain
date: 2026-09-11
abstract: |
  Serving large language models at scale is a distributed systems problem
  whose overload behavior is governed at the ingress. Yet an audit of nine
  top-venue scheduling papers from OSDI, SOSP, ASPLOS, EuroSys, MLSys, and
  HPCA between 2022 and 2026 finds that not one includes an explicit
  ingress-level admission control policy. All nine respond to overload
  through batching, migration, placement, autoscaling, or memory
  management (Table 3). In parallel, a distinct thread of
  admission-primary work has grown quickly: thirteen peer-reviewed papers
  at top venues plus one accepted workshop paper and more than a dozen
  preprints propose admission policies operating at request,
  agent-session, or tenant granularity, under online or offline settings,
  guided by cache pressure, deadline slack, queue depth, or joint linear
  programs. No two of these policies have been compared to each other on
  a common trace, engine, or metric (Table 2). This paper surveys
  fifty-two admission and admission-adjacent works. We propose a four-axis taxonomy
  with sub-branches for signal structure, service-level-objective
  granularity, fairness type, and concurrency context. The canonical
  intersection agent-level × online × deadline-aware × fair is empty. We
  audit reproducibility across the corpus and find that thirteen of
  forty deep-read works have released code, refuting the common
  "reproducibility crisis" framing at the artifact level, while a
  methodology-level crisis persists because no two admission-primary
  papers share a baseline set. We propose a minimal common methodology
  contract to close that gap. We derive seven open problems, each
  grounded in either published peer-review discussion or the primary
  source's own limitation statement.
---

# 1. Introduction

On November 8, 2023, OpenAI's inference fleet crossed a soak point after
a day of unusually heavy completion traffic. Routing nodes reached
memory limits and failed readiness checks. Additional replicas were
added, then rolled back. Recovery required cutting inbound traffic,
redeploying, and slowly ramping load back up. The postmortem named
graceful load shedding through stronger rate-limit controls as the
required follow-up (OpenAI status page, incident 00fpy0yxrx1q). Two
years later, on January 21, 2026, Anthropic's Sonnet 4.5 tier degraded
first in latency and then in error rate over roughly ninety minutes. The
postmortem cited insufficient compute capacity for demand and named
earlier detection of capacity constraints as a required change
(status.claude.com, incident yrxt885v63jw). Cloudflare, Azure, and other
production operators have documented similar sequences.

Admission control is the decision made before a request enters the
running batch. It has three actions: admit into service, hold in queue,
or reject with a well-defined error contract. When admission is wrong,
downstream batching, KV cache management, and preemption cannot recover
lost capacity. Requests admitted past a soak point occupy memory until
they miss their deadline, at which point they consume more capacity
being cleaned up.

The literature on LLM inference has produced systems papers on batching
(Yu et al., 2022; Agrawal et al., 2024), disaggregation (Zhong et al.,
2024; Patel et al., 2024), memory management (Kwon et al., 2023; Qin et
al., 2025), and scheduling (Sun et al., 2024; Hong et al., 2025).
Existing surveys cover efficient serving broadly (Zhen et al., 2025; Li
et al., 2024; Heisler et al., 2025) or the queueing-theoretic view of
LLM systems specifically (Mitzenmacher and Shahout, 2025). Table 1
differentiates this survey from those prior works.

This paper contributes:

1. A four-axis taxonomy for admission-control policies with four
   sub-branches added during the reading (Section 3).
2. **AdmitPerf**, the framework this paper contributes: a taxonomy for
   describing admission policies, a methodology contract for reporting
   them, and an open-source reference implementation that instruments
   the contract's reporting requirements and produced the signal-range
   measurement in Section 3.5. The harness shows the contract is
   implementable against a live serving stack and records the provenance
   it asks for; it does not yet satisfy the contract's own baseline,
   trace, and fairness requirements, which remain open (Section 8). We
   refer to the AdmitPerf taxonomy, the AdmitPerf contract and the
   AdmitPerf harness (https://github.com/harshuljain13/AdmitPerf).
3. A per-cluster synthesis of fifty-two admission and admission-adjacent
   works (Section 5).
4. An empirical reproducibility audit across the corpus (Section 6),
   showing thirteen of forty deep-read works have released code and that
   the real crisis is methodological.
5. A proposed minimal common methodology contract that would enable
   cross-paper comparison without demanding that any paper change its
   primary evaluation (Section 6).
6. A mapping of production incidents to admission failure modes (Section
   7, Table 4).
7. Seven open problems, each with cited evidence from either public peer
   review or the primary source's own limitations (Section 8).

We ground three headline observations. First, of nine top-venue
scheduling papers we audited (Table 3), none includes an
ingress-level admission policy; overload is absorbed by batching,
migration, placement, autoscaling, or memory management. Second, of
sixteen admission-primary papers we audited, no two share a baseline
set, and the only baselines shared by more than one paper are
unconfigured serving engines and classical scheduling disciplines.
Exactly one published admission system, SHEPHERD, is used as a baseline
by two papers (QLM and Ascendra). Third, the
taxonomy holds across all fifty-two works with four sub-branches added
during our reading, none of which required backing out an original axis.

## 1.1 Related surveys and differentiation

Four broad surveys of LLM inference serving predate this work. Table 1
summarizes each and states what this paper adds.

| Prior survey | Scope | Admission depth | Taxonomy axes | Reproducibility audit | Open problems grounded in peer-review |
|---|---|---|---|---|---|
| Zhen et al., INLG 2025 "Taming the Titans" | Efficient serving (batching, KV mgmt, scheduling, fairness) | One subsection | Task-oriented | No | No |
| Heisler et al., TechRxiv Nov 2025 "LLM Inference Scheduling Survey" | Scheduling techniques, frameworks, trade-offs | Component of scheduling | Technique-oriented | No | No |
| Li et al., IEEE HPEC 2024 "LLM Inference Serving Survey" | Recent advances in serving | Cited in passing | Chronological | No | No |
| Mitzenmacher and Shahout, SIGMETRICS 2025 tutorial | Queueing theory for LLM serving | Position/tutorial | Queueing-theoretic | No | Enumerates 25 problems |
| Ma et al., SSRN 2026 "Control-Oriented Survey of Load Balancing" | Load balancing as a coupled control problem | Routing and placement, not ingress | Control-theoretic | No | No |
| **This paper** | **Admission control as primary axis** | **Full coverage** | **4 axes + 4 sub-branches** | **Yes, corpus-wide** | **Yes, 7 problems** |

Ma et al. is the closest neighbour and the most recent. It treats
serving as a control problem and organizes the literature by control
loop, covering routing, replica selection and placement. Admission is
adjacent to that work rather than inside it: load balancing decides
where a request goes, admission decides whether it is taken at all.
The two are complementary, and we adopt their framing of phase
asymmetry where it bears on admission signals.

Zhen et al. and Heisler et al. treat admission as one component among
many. Li et al. is a survey of recent advances organized
chronologically. Mitzenmacher and Shahout is a position paper that
enumerates open queueing problems without a taxonomy or per-paper
review. None conducts a reproducibility audit or organizes the literature
by admission granularity, SLO awareness, signal structure, or
concurrency context. This paper is complementary to Mitzenmacher and
Shahout in particular and cites their tutorial as the theoretical
companion to our systems-oriented review.

The paper is aimed at systems and machine-learning-systems researchers
building inference services, and at practitioners evaluating admission
policies for production deployment.

# 2. Background

## 2.1 The inference request lifecycle

A large language model inference request passes through prefill, decode,
and completion. Prefill computes the key-value tensors for every input
token. Decode generates output tokens one at a time, reading the
accumulated KV cache and appending a new pair per step. Continuous
batching (Yu et al., 2022) reuses a single GPU-resident engine across
many concurrent requests by interleaving iterations at token
granularity. PagedAttention (Kwon et al., 2023) manages the KV cache in
fixed-size blocks to reduce fragmentation and enable prefix sharing.

The KV cache is the memory hierarchy's dominant consumer. It grows
monotonically with generated tokens during a request's decode, and it
persists across turns for multi-turn agents. When aggregate KV footprint
approaches available GPU memory, the engine must either evict (recompute
later), swap (page to CPU or disk), or preempt (kill the request and
return an error).

## 2.2 The Admit-Queue-Route model

Every request that reaches an inference cluster passes through three
decision boxes before it produces its first token. Admit decides whether
to accept the request into service. Queue decides in what order accepted
requests are served. Route decides which replica or instance receives
the request. This paper is about the first box.

Admission decisions have three legal outcomes. Admit hands the request
to the engine's running batch or its immediate waiting pool. Queue
delays the request behind other admitted requests, either
first-come-first-served or under a policy that reorders by deadline,
priority, or predicted length. Reject terminates the request at ingress
with an error contract that the client's retry logic will honor.

The error contract matters. HTTP 429 signals a client-side rate limit
exceeded. HTTP 503 signals a temporarily unavailable service. Anthropic
uses HTTP 529 to signal a provider-overloaded state distinct from either
of the above (Anthropic API errors, 2026). A well-designed admission
policy chooses among these codes based on which signal the client's
backoff logic should trust.

## 2.3 Service-level objectives

The community reports admission behavior against a small set of metrics.
Time-to-first-token (TTFT) is the wall-clock delay between arrival and
the first generated token. Time-between-tokens (TBT), sometimes called
inter-token latency or time-per-output-token (TPOT), is the delay
between consecutive generated tokens. Goodput is the completed-request
rate that met their service-level objective, distinct from raw
throughput (Zhong et al., 2024). For agentic workloads, agent-completion
rate measures the fraction of multi-turn sessions that finish within an
end-to-end budget.

Fairness metrics divide across two axes we make explicit in the
taxonomy: fairness between task types (prefill versus decode within one
batch) and fairness between tenants (across users or organizations).
These are structurally different problems and use different mechanisms.

## 2.4 Why admission control is hard

Ao, Dong, Luo, and Simchi-Levi (2026) formalize the core problem. In a
discrete-time model of continuous batching under a memory budget, the
service process itself creates future capacity pressure because each
active request's KV footprint grows with each generated token. They
prove that the natural eviction-free equilibrium is unstable under any
admission rule that only checks instantaneous memory feasibility. Along
the resulting limit cycle, the throughput ratio equals
(2l_0 + l_1 + 1)/(2(l_0 + l_1)) which converges to one half as
l_1/l_0 tends to infinity. Their Theorem 3 further shows that stability
depends on the greatest common divisor of active decoding lengths:
coprime workloads stabilize, workloads with a common divisor synchronize
into eviction cycles. This is a workload-arithmetic property of
admission decisions that no production system currently exposes as a
signal.

# 3. The AdmitPerf taxonomy

We organize admission-control policies along four axes. Sub-branches
were added during our reading and are called out explicitly.

## 3.1 Axis 1: Unit of admission

Admission decisions can be made at three granularities. Request-level
policies admit or reject each incoming prompt independently (QLM, Patke
et al., 2024; Chronos, Marref et al., 2026; FastServe, Wu et al., 2026;
SOLA, Hong et al., 2025). Agent-session-level policies admit or reject
entire multi-turn agent trajectories (CONCUR, Chen et al., 2026;
Continuum, Li et al., 2026; ThunderAgent, Kang et al., 2026).
Tenant-level policies gate admission per user or per organization (VTC,
Sheng et al., 2024).

## 3.2 Axis 2: Setting

Online serving handles interactive latency-sensitive workloads (most of
the field). Offline batch handles throughput-oriented inference where
per-request deadlines are relaxed. CONCUR is explicitly offline per its
ICML 2026 meta-review. Hybrid settings mix both (Aegaeon, SOSP 2025).

### 3.2.1 Sub-branch: Concurrency context

We add a sub-branch after finding that Clairvoyant (Sundaresan, 2026)
solves an admission problem that server-side policies cannot generalize
to. Concurrent-batch servers (vLLM, SGLang, TensorRT-LLM) admit at
iteration granularity, contend for KV blocks across many active
requests, and can preempt mid-decode. Serial edge backends (Ollama,
llama.cpp) execute one request at a time. Head-of-line blocking is the
dominant tail-latency pathology at the edge, and predictive
shortest-job-first admission is the natural response. These policies
share almost no mechanism and belong in distinct clusters.

## 3.3 Axis 3: SLO awareness

Deadline-aware policies condition admission on TTFT or TBT bounds
(Chronos, SOLA, FastServe, Past-Future Scheduler). Throughput-oriented
policies maximize aggregate goodput without per-request deadlines
(CONCUR, Continuum). Fairness-oriented policies enforce per-tenant or
per-task equity (VTC, FairBatching, Equinox). Cost-oriented policies
minimize dollars or energy per token.

### 3.3.1 Sub-branch: SLO granularity

SLOs-Serve (Chen et al., 2025) exposes a design axis nobody else covers.
Job-level SLOs specify a single deadline per multi-turn agent job.
Request-level SLOs specify one deadline per prompt (most of the field).
Per-stage SLOs specify distinct deadlines per stage of a multi-turn
application: tight TTFT on tool-call prefill, loose TPOT on reasoning
decode, tight TPOT on final answer. Only SLOs-Serve models the per-stage
case. Llumnix, DynamoLLM, ExeGPT, and VTC each model a single SLO per
request.

### 3.3.2 Sub-branch: Fairness type

Task-fairness allocates GPU cycles equitably between prefill and decode
tasks within one batch (FairBatching, Lyu et al., 2025). Tenant-fairness
equalizes served tokens or SLO attainment across users (VTC, Equinox).
These two objectives share no mechanism. FairBatching's "fairness" would
mislead a reader looking for multi-tenant isolation.

## 3.4 Axis 4: Signal used

Admission policies read a runtime signal to decide. We identify four
structural forms.

Scalar heuristics compare a single quantity to a threshold (KV
utilization for Fluid-WAIT; queue depth as one input for QLM; predicted
output length for Clairvoyant).

Dual-gate conjunctions require multiple signals to agree before firing.
CONCUR's controller declares congestion only when both KV utilization is
high and prefix cache hit rate is low. The rationale is that high
utilization with high hit rate is healthy reuse rather than thrashing.

Linear-program-based composite signals treat admission as one variable
in a joint optimization. QLM formulates a linear program over virtual
queues. SOLA runs a per-iteration LP over five or more state variables.
SLOs-Serve uses dynamic programming over token allocations.

Formal worst-case-response-time bounds derive an admission test from
real-time-systems theory. Chronos casts prefill as a sporadic job with
worst-case execution time proportional to input length, then derives a
closed-form WCRT bound whose feasibility test decides admission on each
arrival.

## 3.5 What the Signal axis predicts

A taxonomy earns its place by doing more than filing. The Signal axis is
testable: a policy can only act when the quantity it reads moves, and
which quantity moves is a property of the deployment rather than of the
policy. On a small model with a low concurrency cap, the cap binds and
the wait queue moves while KV occupancy stays near zero. On a large
model with long contexts and large batches, KV memory binds and queue
depth is the quieter signal.

This yields a falsifiable prediction: a KV-pressure policy deployed on a
small model cannot refuse anything, whatever threshold it is given, and
its results will be indistinguishable from an uncontrolled baseline.

We tested it. Running a KV-threshold policy with a 0.9 threshold against
Qwen2.5-0.5B on one A10G with a concurrency cap of ten, the observed KV
occupancy across 1,479 admission decisions in three repeats ranged from
0.0000 to 0.0071, two orders of magnitude below the threshold. The
policy admitted every request in all three repeats, and its median SLO
attainment of 0.5537 is within run-to-run spread of the uncontrolled
baseline's 0.5553. The policy was structurally incapable of acting, and
a results table alone would not show it. This is a single deployment
regime, not a general result: it establishes that the failure mode
occurs, not how often.

This is why the methodology contract in Section 6.1 asks for the
observed range of the signal a policy reads. It is also why the Signal
axis is more than descriptive: it tells you in advance which policies
can function in which regime.

## 3.6 The unclaimed intersection

Plotting the corpus on Unit × SLO-awareness shows that
agent-level × online × deadline-aware × fair is empty. CONCUR is
agent-level but offline and throughput-oriented. Chronos is
deadline-aware but request-level. FairBatching is fair but task-level
not tenant-level. No published policy occupies the intersection. This
is the seed for Open Problem 1.

# 4. Method

We conducted a systematic review following an adapted PRISMA workflow.
Search dates ran from May 2022 (Orca) through September 2026. Sources:
DBLP, arXiv, OpenReview, USENIX, ACM Digital Library, IEEE Xplore, ICML
and NeurIPS proceedings, and Google Scholar for cross-references. Search
strings combined admission-control terms ("admission control", "queue
management", "load shedding", "request rejection", "request dropping",
"SLO-aware admission", "throttling", "backpressure") with LLM-serving
terms ("LLM inference", "LLM serving", "language model inference",
"agentic inference", "continuous batching").

## 4.1 Inclusion and exclusion rules

A paper was included if all four conditions held:
1. Published or preprinted between 2022-05-01 and 2026-09-11.
2. Primary application domain is LLM inference (not general DNN serving
   or generic queueing theory).
3. Either (a) admission control is the primary contribution, or (b) the
   paper is a top-venue scheduling / KV-management / fairness work
   whose mechanism has direct admission-adjacency.
4. Full text was accessible (arXiv HTML, venue PDF, or OpenReview).

A paper was excluded if any held:
1. Pure model-side optimization (quantization, pruning, distillation)
   without a serving-time admission component.
2. Vision or speech inference without LLM applicability.
3. Marketing materials or blog posts without a peer-reviewed or
   arXiv-preprint anchor.

## 4.2 Tier structure

We organized the corpus into six tiers based on admission-primacy:

- **Tier 1 (16 papers)**: admission-primary, one policy per paper.
- **Tier 2 (9 papers)**: queueing theory or fairness-primary with
  admission-adjacency.
- **Tier 3 (6 papers)**: KV-cache-management papers whose mechanism has
  admission implications.
- **Tier 4 (9 papers)**: top-venue scheduling papers with admission as a
  secondary or missing component (Table 3).
- **Tier 5 (6 papers)**: foundational works (Orca, PagedAttention,
  SHEPHERD, PreQuaL, Kleinrock, Little's Law) cited for background.
- **Tier 6 (6 papers)**: prior broad surveys used for differentiation
  (Table 1).

Tiers 1 through 4 are the deep-read corpus: 40 papers. Tiers 5 and 6
are 12 further works read for background and differentiation. Roughly 50
additional references are cited without deep reading (Section 9).

## 4.3 Per-paper protocol

For each work we recorded venue, authors, arXiv or DOI identifier, code
availability, taxonomy placement across all four axes, primary
contribution, baseline set, evaluation setup (model, engine, workload,
hardware), claimed headline numbers with configuration qualifiers,
fidelity notes, and open questions surfaced. Notes were written in a
common markdown template to make cross-work comparison tractable. The
complete per-paper corpus is public at the survey's artifact repository.

We did not run experiments. Where papers report conflicting numbers we
report each source's number as stated with the operating-point
qualifier the source specifies, and flag the conflict rather than
adjudicate.

## 4.4 Reviewer discussion evidence

For several open problems (Section 8) we cite public OpenReview
discussion or venue meta-reviews as evidence that a gap is
practitioner-recognized. Where a peer reviewer explicitly asked a
question that the paper's rebuttal did not answer, we treat that as
grounded evidence for an open problem.

# 5. Policy clusters

## 5.1 Request-level SLO-aware admission

QLM (Patke et al., SoCC 2024) is the canonical peer-reviewed
admission-primary paper for online serving. It maintains virtual queues
per model and formulates request scheduling as a linear program that
minimizes SLO-violation penalty. A Request Waiting Time Estimator
predicts per-request wait using Central Limit Theorem bounds over
historical output-token distributions, with reliable predictions once
the queue holds at least four request groups. Four load-steering
operators (request pull, request eviction preserving KV, model swap,
cross-GPU load balance) are exposed to the LP. Reported improvements
are 40 to 90 percent SLO attainment lift and 20 percent
(single-model) to 400 percent (multi-model) throughput gain over vLLM
and EDF baselines on a heterogeneous 30-A10 plus 50-A100 cluster,
serving Mistral-7B, Vicuna-13B, and LLaMA-70B on ShareGPT. Code is
public at github.com/QLM-project/QLM. QLM is deployed inside IBM's
internal routing service.

Chronos (Marref et al., Frontiers in Computer Science 2026) derives a
formal schedulability condition for LLM inference. Each request becomes
a sporadic prefill job with per-request WCET
C_pre,i = p_i·(αB + γ). The WCRT bound is
ρP·D_TTFT/(1−ρP) + p_i·(αB + γ) provided prefill utilization
ρP < 1. Algorithm 1 runs on each arrival and rejects if prefill
utilization exceeds one, if the WCRT bound exceeds the TTFT deadline,
or if a TBT capacity check fails. On a 7B model in a discrete-event
simulator against 50,000 sampled Azure conversational-service requests,
Chronos delivers 0.00 percent TTFT miss rate at 5× nominal load while
FCFS and EDF miss 99.44 percent at 10× load. A throughput-matched
token-bucket baseline (AC-FCFS) still misses 15.4 percent at the same
admission volume, isolating the value of formal feasibility testing over
matched rate limiting. Simulator code is public at
github.com/am-research/rtss-ttft-tbt. Chronos is one of two papers we
found that couple LLM serving with real-time-systems response-time
theory; the other is Flow-Controlled Scheduling (Section 5.4).

SOLA (Hong et al., MLSys 2025) formalizes fine-grained scheduling as an
LP over per-request and systemic state. Empirical scheduling raises SLO
attainment from 45.5 percent to 99.4 percent and serves 1.04-1.27×
more requests. The constraint-relaxation mechanism at the α-percentile
is an implicit admission decision hidden inside a scheduler: when the
LP is infeasible, the system sacrifices (1-α) percent of requests to
preserve the guarantee for the rest.

FastServe (Wu et al., NSDI 2026) argues for token-granularity preemption
rather than reject-on-arrival admission. A skip-join multi-level
feedback queue promotes short-remaining requests, and proactive KV
offload keeps preempted state cheaply resumable. The headline of 31.4×
average-latency throughput improvement is measured on OPT-175B across
16 A100 GPUs against vLLM v0.1.7 on ShareGPT; reproduction on modern
vLLM releases and smaller models produces smaller gains. Code is public
at github.com/LLMServe/FastServe, though the SwiftTransformer engine
dependency means porting to vLLM or SGLang is a multi-week engineering
task.

SLOs-Serve (Chen et al., 2025) is the only paper in our corpus that
handles per-stage-of-agent SLOs. Its multi-SLO DP algorithm optimizes
token allocations under joint deadlines, admits requests whose SLOs are
jointly attainable, and declines the rest through soft admission. On
six workload scenarios (ChatBot, Coder, Summarizer, Mixed, ToolLLM,
Reasoning) across OPT-7B/13B/30B, ToolLlama-7B, and DeepSeek-R1-1.5B, it
reports 2.2× geometric-mean per-GPU serving capacity. Preprint only as
of September 2026.

Scorpio (WISE 2026, arXiv:2505.23022) is the most recent
admission-primary entry and splits the decision across three stages:
admission, queue management, and batch selection. Its TTFT Guard
reorders by least deadline first and rejects requests whose first-token
deadline is unattainable, estimating attainability from the cumulative
prefill time of everything already queued. Its TPOT Guard admits only
when the predicted per-token latency for the resulting virtual batch
stays under the tightest TPOT target in the running set. Both guards
read a predicted output length from a fine-tuned OPT-125M classifier
over 100 bins, which places Scorpio in the dual-gate signal class with
learned rather than analytic grounding. It is evaluated on vLLM with
Llama-3.1-8B and Gemma-2-27B on four A100s, against vLLM, S3 and
Mooncake, and reports up to 14.4 times goodput and 46.5 percent better
SLO adherence under high load.

Two details matter beyond the numbers. First, Mooncake is itself an
early-rejection admission mechanism, which makes Scorpio one of the few
policy-versus-policy comparisons in the corpus. Second, Scorpio computes
goodput with every arriving request in the denominator, so a rejected
request counts as an SLO miss. That is the same discipline we adopt in
Section 2.3 for goodput-under-admission, arrived at independently. A
metric that counts only admitted requests flatters shedding: a policy
that refuses 95 percent of traffic and serves the rest perfectly scores
100 percent. Two efforts reaching the same denominator by separate
routes is the strongest argument we have that this is the right one.

## 5.2 Agent-session-level admission

CONCUR (Chen et al., ICML 2026) identifies middle-phase thrashing in
agentic batch inference: sustained low prefix-cache hit rate during the
middle of a long-horizon session, driven by cumulative KV pressure
across turns. The controller reads two signals, KV utilization U_t and
hit rate H_t, and declares congestion only when both fire (U_t > U_high
AND H_t < H_thresh). Additive-increase-multiplicative-decrease adjusts
the number of concurrently admitted agent sessions with α=2 and β=0.5.
Fixed hyperparameters work across Qwen3-32B and DeepSeek-V3 with less
than three percent throughput swing. Headline gains are 4.09× throughput
against SGLang on Qwen3-32B at 256 sessions, tensor parallelism 8, 8
H100 GPUs, and 1.90× against SGLang on DeepSeek-V3 at 40 sessions,
tensor parallelism 16, 16 H100 GPUs. Against Continuum as a baseline,
CONCUR shows 1.69× on Qwen3-32B; this comparison was added in rebuttal.
The meta-review states the paper targets offline throughput-oriented
inference and that online serving is out of scope.

Continuum (Li et al., ICLR 2026 Workshop on Lifelong Agents poster;
concurrent full-conference submission pending) manages KV retention
rather than gating admission. Per-session time-to-live is set by
maximizing expected benefit minus cost, using an empirical CDF of
tool-call durations. A two-part cost model adds an out-of-order term
that InferCept (Abhyankar et al., ICML 2024) does not, which the paper
identifies as its key delta over prior art. Continuum operates entirely
after admission and reports 1.12-3.66× JCT improvement across
Llama-3.1, Gemma-3, and GLM-4.5 on SWE-Bench, BFCL, and OpenHands, with
a peak of 8.18× on an internal Tensormesh deployment. Public vLLM fork
at github.com/Hanchenli/vllm-continuum.

ThunderAgent (Kang et al., ICML 2026 Spotlight, integrated into NVIDIA
Dynamo 2.0) treats disk, ports, and sandboxes as first-class scheduled
resources alongside GPU. A central scheduler pauses and restores
programs with explicit state migration, providing agent-level admission
through admission gating and cross-node migration for HBM balance. This
is the first paper in our corpus to model tool-side admission as a
first-class contribution alongside LLM-side admission.

## 5.3 Fairness-aware admission and scheduling

VTC (Sheng et al., OSDI 2024) formalizes LLM-serving fairness through a
cost function over tokens processed rather than requests, defaulting to
w_p=1 for input and w_q=2 for output. The Virtual Token Counter
prioritizes the least-served backlogged client at each
continuous-batching step. Counter-lift on client return prevents
accumulated credit exploits. The theoretical guarantee bounds service
difference between any two continuously-backlogged clients at
2·max(w_p·L_input, w_q·M), and a matching lower bound of w_q·M proves
the 2× factor is tight. Empirically VTC halves max unfairness versus
FCFS while matching throughput (779 versus 777 tok/s on 27 Chatbot
Arena clients), whereas RPM(5) rate limiting collapses throughput to
340 tok/s. Artifact-evaluated code at github.com/Ying1123/VTC-artifact.

FairBatching (Lyu et al., 2025) attacks a different fairness axis:
between prefill and decode tasks within a batch. Sarathi-Serve's
stall-free batching excessively prioritizes decode; FairBatching's
enhanced-EDF adaptive-capacity batch formation achieves 2.29× tail
latency reduction, 20 percent single-node capacity improvement, and
54.3 percent cluster-level capacity improvement. The implementation is
only 90 lines of invasive vLLM changes.

Equinox (Lu et al., 2025) argues that equal tokens do not imply equal
user experience. A dual counter combines a user-facing fairness counter
(latency-penalized served tokens) and a resource fairness counter
(throughput times GPU utilization) into a holistic score. Equinox
requires a Model of Prediction Ensemble (three BERT-base plus a
router) to predict output length, latency, throughput, and GPU
utilization from prompt text. Reported thirteen percent fairness
improvement is measured against Equinox's own holistic fairness metric,
not a mechanism-independent metric.

Niyama (Goel et al., 2025) sits adjacent to admission rather than inside
it. It co-schedules mixed workloads on shared infrastructure with
fine-grained QoS classes and a hybrid fairness-efficiency priority
policy, and under overload it applies selective request relegation,
degrading service for lower classes rather than refusing work at the
door. We include it because relegation and admission answer the same
question with different verbs, and because its overload behaviour is
directly comparable to a deferring admission policy.

## 5.4 Queueing-theoretic and algorithmic

Service-Induced Congestion (Ao et al., 2026) provides the theoretical
justification for the entire field. Section 2.4 already discussed the
50 percent asymptotic throughput bound and the GCD stability criterion.
The paper's scheduling design principles include using coprimality of
active decoding lengths as a diagnostic for synchronization risk and
injecting mild jitter into decode-length distributions to break the GCD.
Numerical experiments in a Vidur simulator with real-GPU validation
confirm the effect. No public code.

Flow-Controlled Scheduling (Dong and Cao, 2026) proves necessary and
sufficient stability conditions for admission-controlled LLM serving.
The mechanism is a static token-bucket sized offline per class, with
FIFO within class. LIFO eviction under overflow minimizes wasted decode
work but inverts fairness for interactive workloads, a starvation
property the paper does not analyze. No code.

Fluid-WAIT (Ao et al., 2025) derives a threshold admission rule from a
fluid-model equilibrium analysis. Nested WAIT handles unknown output
lengths with a safety buffer. Evaluation is in the Vidur simulator with
appendix validation on real GPUs.

Shen et al. (ICML 2026) prove Õ(√KT) regret for joint online
configuration selection and admission control under an
independent-and-identically-distributed reward-resource assumption per
configuration. The paper motivates via LLM serving but validates
empirically on Alibaba cluster traces with three pricing regimes. Code
public at github.com/owenshens/A-Two-Layer-Framework-for-Joint-Online-Configuration-Selection-and-Admission-Control.

Jaillet et al. (arXiv 2502.07115, revised through 2026) target online
scheduling under KV-cache constraints with per-request memory that grows
monotonically during decode. Their memory-cognizant policies achieve
competitive-ratio bounds under structured arrivals plus α-accurate
predictions; exact bound structure varies across the paper's regimes
and should be checked directly against the source before use in
downstream work.

Mitzenmacher and Shahout (SIGMETRICS 2025 tutorial) enumerate 25 open
problems at the intersection of queueing theory and LLM serving,
including practical Gittins-index policies, distributional service-time
predictions, tail-behavior analysis of prediction-augmented queues, and
heterogeneous-GPU prefill-decode balance. Our Section 8 draws on this
enumeration.

Clairvoyant (Sundaresan, 2026) is the sole entry in the serial-edge
concurrency-context sub-branch. Predictive shortest-job-first uses an
XGBoost classifier over 19 lexical features to route around
head-of-line blocking on Ollama and llama.cpp backends, delivering 70
to 76 percent short-request p50 latency reduction on an RTX 4090 under
mixed bursts. The paper's negative result on curated instruction
datasets (Alpaca has four Long-class examples out of 52,000 responses,
or 0.008 percent) is a reusable finding for anyone training length
predictors.

Ascendra (Elnikety et al., 2025) uses an SLO-risk predictor to promote
requests between low-priority and high-priority queues and drops
requests reactively when queue TTFT is already blown. The predictor
exists but is not turned into a proactive admission gate.

## 5.5 KV-cache management adjacent

KVFlow (Pan et al., NeurIPS 2025) is pure cache management with a
steps-to-execution ranking over SGLang's radix tree and CPU-to-GPU
prefetch overlap. No admission logic. Complementary to CONCUR, not a
substitute.

Cake (Jin et al., ICML 2025) optimizes single-request TTFT via hybrid
compute-versus-load KV decisions. An adaptive scheduler arbitrates GPU
between prefix-hit and non-prefix requests, which is resource-class
arbitration rather than admit-reject.

InferCept (Abhyankar et al., ICML 2024) chooses between preserving,
swapping, and discarding KV during tool-call intercepts. The cost model
prices GPU-memory-bytes-times-time locally and does not account for
queue length or waiting requests, which Continuum identifies as its key
limitation.

Pie (Gim et al., SOSP 2025) provides a programmable serving substrate
with generation-loop handlers and KV page management. There is no
cross-inferlet scheduler API, no admit-reject hook, and no per-tenant
fairness state. Admission policies would require developer-added host
extensions. FCFS-terminate-newest is the only built-in overload
response.

## 5.6 Scheduling papers with admission-adjacent components

We audited nine top-venue scheduling papers. Table 3 summarizes what
each does under overload. The row that matters most for this paper's
motivation is the "ingress admission?" column: no cell answers yes.

**Table 3.** Overload response mechanisms in nine top-venue LLM serving papers.

| Paper | Venue | Overload mechanism | Ingress admission? | Code |
|---|---|---|---|---|
| Orca | OSDI 2022 | FCFS + KV-slot cap (implicit backpressure) | No | Yes |
| Sarathi-Serve | OSDI 2024 | Chunked prefill batching | No | Partial |
| Llumnix | OSDI 2024 | Live request migration | No | Yes |
| DistServe | OSDI 2024 | P/D disaggregation, static split | No | Yes |
| Past-Future | ASPLOS 2025 | Memory projection at batch boundary | Internal only | In LightLLM |
| Aegaeon | SOSP 2025 | Per-token autoscaling ("admission by elasticity") | No | Yes |
| Jenga | SOSP 2025 | Memory heterogeneity mgmt | No | Yes |
| AdaServe | EuroSys 2026 | SLO-customized speculative decoding | No (INVALID signal unused) | No |
| PASCAL | HPCA 2026 | Runtime phase detection for reasoning | No (post-admission) | Partial |

Past-Future's memory-projection gate at the batching boundary is the
closest of the nine to admission, and it operates on already-queued
requests rather than at ingress. This 9-for-9 result is our motivation
for treating admission as an under-explored primary contribution.

# 6. Reproducibility and comparison methodology

We audited public code availability across our corpus. Thirteen of
forty deep-read works have released code as of September 2026:
QLM, Chronos (simulator), FastServe (on SwiftTransformer engine),
Shen et al., Continuum, Clairvoyant, AQUA, VTC, KVFlow, InferCept, Pie,
ThunderAgent, and Cake. This is higher than the "reproducibility crisis"
framing common in prior surveys of the space would suggest.

The real crisis is at the methodology level. Table 2 shows the baseline
set used by each admission-primary paper. No two papers share a
baseline *set*; the baselines that do recur across papers are
unconfigured serving engines and classical scheduling disciplines, not
admission policies.

**Table 2.** Baseline sets for the admission-primary papers whose
evaluation names its baselines. Rows are papers; columns are the systems
they compare against. Empty cells indicate no comparison. Ten of the
sixteen Tier 1 papers are listed; the remainder do not name a baseline
set precisely enough to tabulate, which is itself part of the finding.

| Paper | vLLM | SGLang | Sarathi | Orca | EDF | FCFS | SHEPHERD | CONCUR | QLM | Continuum | HiCache | AC-FCFS | SLAI | DistServe | Llumnix |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| QLM (SoCC 2024) | ✓ | | | (cite) | ✓ | (implicit) | ✓ | | self | | | | | | |
| CONCUR (ICML 2026) | | ✓ | | | | | | self | | ✓ (rebuttal) | ✓ | | | | |
| Chronos (Frontiers 2026) | | | | | ✓ | ✓ | | | | | | ✓ | ✓ | | |
| SOLA (MLSys 2025) | ✓ | | ✓ (reimpl SplitFuse) | | | | | | | | | | | ✓ | |
| FastServe (NSDI 2026) | ✓ (v0.1.7) | | | | | | | | | | | | | | |
| SLOs-Serve (2025) | ✓ | | ✓ | | | | | | | | | | | ✓ | (cite Llumnix) |
| FairBatching (2025) | | | ✓ | | | | | | | | | | | | |
| Ascendra (2025) | | | | | | | ✓ | | | | | | | | |
| Fluid-WAIT (2025) | (unnamed "widely used baselines") | | | | | | | | | | | | | | |
| Scorpio (WISE 2026) | ✓ | | | | | | | | | | | | | | |

Read the columns by what they contain. vLLM, SGLang, Sarathi, Orca,
DistServe and Llumnix are engines and schedulers: comparing against them
measures a policy against the absence of admission control, not against
an alternative to it. The columns that hold actual admission policies
are almost empty. Exactly one published admission policy, SHEPHERD, is
used as a baseline by more than one paper (QLM and Ascendra). Every
policy in this corpus is measured against doing nothing, and almost
never against another policy. Model choices, engine choices, workload traces, and metric
definitions also diverge across the corpus. Reading the literature top
to bottom, a practitioner cannot answer "which admission policy wins on
my workload."

## 6.1 Proposed minimal methodology contract

We propose that future admission-control papers commit to reporting
against a minimum common configuration:

- **Baseline set**: vLLM default (control), plus at least one policy
  from each of {CONCUR, Chronos, QLM} covering agent-level,
  deadline-aware, and queue-managed admission.
- **Trace set**: Azure LLM Inference Trace (request-level, chat-shaped)
  plus at least one agentic trace corpus (SWE-Bench, τ-bench, GAIA, or
  BrowserComp).
- **Metric suite**: goodput at target SLO, TTFT p50/p95/p99, agent-
  completion rate for agentic workloads, per-tenant Jain fairness index,
  admission-decision histogram.
- **Reporting**: every headline number quoted with model, engine
  version, hardware, workload subset, and SLO target.

This is a methodology contract, not a benchmark, and is compatible with
each paper's own primary evaluation. It costs each new paper roughly
one additional experiment configuration to satisfy.

# 7. Production evidence

Real inference-fleet incidents map directly onto admission failure
modes. Table 4 lists eight public postmortems and identifies the leading
signal that would have prevented each.

**Table 4.** Production incidents mapped to admission signals.

| Incident | Failure mode | Trusted signal (was) | Leading signal (needed) |
|---|---|---|---|
| Azure 2016 | Control-plane inferred backend unavailability, concentrated traffic to one region, returned 429 for 3.5–4 hours | HTTP 400 responses (spurious) | Cross-validation of backend health with independent liveness check |
| OpenAI DALL·E queue collapse | Work admitted past client cancellation timeout, cache queue filled with expired jobs, success rate 10 → 25 → 0 percent | Queue depth | Queue age at admission |
| OpenAI Nov 8 2023 | Routing nodes crossed soak point, additional replicas insufficient, required shed-then-ramp recovery | Utilization | Rate of change of utilization crossing readiness-check threshold |
| OpenAI Dec 11 2024 | Telemetry caused control-plane API storm; data plane used stale DNS for 20 minutes then failed at TTL expiry | Aggregate utilization dashboards | Control-plane health independent of data-plane cached state |
| OpenAI Apr 2025 | Control-plane OOM, traffic moved to healthy cluster, pod churn overloaded that cluster's control plane, misleading errors | Cluster availability | Correct 429/503 propagation on failover |
| Anthropic Jan 21 2026 | Insufficient compute allocated for demand; latency degraded first, then errors for ~90 min | Metrics dashboard refresh cycle | Sub-minute capacity-constraint detection |
| Anthropic Aug 29 2025 | Load-balancer moved short-context traffic to servers configured for one-million-token contexts; impact grew 0.8 → 16 percent of Sonnet 4 traffic | Pool-level utilization | Per-configuration utilization decomposition |
| Anthropic 2025 (HTTP 529 introduction) | Provider-overloaded distinct from client-rate-limited; aggressive retry amplifies pressure | Single 429/503 signal | Dedicated 529 semantics |

The recurring pattern across incidents is that the admission decision
trusted a signal that was either delayed, spatially aggregated over the
wrong pool, or inferred from a proxy quantity. Anthropic and OpenAI
have both introduced or documented signal improvements after their
incidents; the community lacks a shared classification of which signals
are leading, lagging, or corrupted under what conditions.

## 7.1 Practitioner checklist

For operators evaluating an admission policy, we suggest four questions:

1. **Signal validity**: what does the policy admit against, and can that
   signal be corrupted by the failure modes in Table 4?
2. **Error contract**: does the policy return 429, 503, or 529, and does
   the choice match your client retry logic?
3. **Time to detection**: how quickly does the policy respond to a
   capacity change smaller than your metric-dashboard refresh interval?
4. **Pool decomposition**: does the policy see per-configuration
   utilization, or only pool-level averages?

Table 4 rows map directly to failure modes each question addresses.

# 8. Open problems

Seven high-signal open problems. Each cites concrete evidence from
either published peer review or the primary source's own limitations.
The survey artifact contains a longer catalog of 37 candidate open
problems.

## 8.1 Request-level versus agent-level admission head-to-head

The CONCUR reviewer discussion at ICML 2026 (submission 14315,
OpenReview forum mmdqUrEY24) contains this exchange: Reviewer Afcg
maintained a weak-accept score with the final justification "the
underlying problem can be addressed through more effective request-level
scheduling (e.g., deciding whether to admit or defer a request under
current memory constraints). I would therefore suggest that the paper
include a discussion of this perspective in the final version." CONCUR
added a Continuum comparison in rebuttal but did not add a request-level
baseline. The empirical question of whether request-level admission
(QLM, Chronos, Fluid-WAIT) can match agent-level admission (CONCUR) on
agentic workloads remains unresolved.

## 8.2 Online serving admission for agentic workloads

The CONCUR meta-review states "the authors should explicitly state that
the paper targets offline throughput-oriented agentic inference, and
expand the discussion of fairness, online serving, and the relationship
to complementary cache-management and scheduling approaches." All
published agent-level admission systems (CONCUR, Continuum,
ThunderAgent) target offline batch. Online agent-level admission with
SLO awareness is an open design point.

## 8.3 Multi-tenant admission with per-tenant SLOs

VTC handles fairness in served tokens across tenants. FairBatching
handles fairness between prefill and decode tasks within a batch.
Neither handles per-tenant deadline SLOs with tenant-aware admission
decisions. Two tenants with equal served-token counts under VTC can
have wildly different perceived TTFT variance.

## 8.4 Reasoning-trace-aware admission at ingress

PASCAL (HPCA 2026) addresses phase-aware scheduling for
reasoning-augmented LLMs, but its phase detection is entirely runtime:
the scheduler observes the reasoning-to-answering transition after
decoding has started. Ingress-level reasoning-versus-chat classification
would let admission control gate long-CoT traffic before KV pressure
accumulates. The literature does not include this.

## 8.5 Coupling admission with autoscaling and routing

Chiron (Patke et al., 2025) autoscales replicas across a heterogeneous
GPU fleet. QLM (same Patke research group, SoCC 2024) does per-replica
SLO-aware queueing. The two never appear in the same evaluation. A
future policy that jointly optimizes across replica count, replica
routing, and per-replica admission would close a gap that both papers
individually acknowledge as future work.

## 8.6 Formal schedulability with LLM-specific WCRT

Chronos derives closed-form WCRT bounds under a linear kernel model
(τ = αn_P + βn_D + γ) with roofline-derived parameters, never measured
on real silicon. Deterministic WCET is known to be conservative for
LLM workloads because prefill-chunk boundaries, tensor-core alignment
effects, and KV fragmentation break linearity in practice. Probabilistic
WCET analysis, mixed-criticality models with per-tenant SLO classes, and
formal analysis under disaggregated prefill/decode topologies are all
open.

## 8.7 Reproducibility at the methodology level

Thirteen of forty deep-read works have released code, refuting
the common framing that the field has no artifacts. What the field
lacks is a common methodology contract: a shared baseline set, trace
subset, and metric suite that would make cross-paper comparison
tractable (Section 6.1). Without this, released code enables
reproducing each paper's own numbers but not comparing them to a
competing paper.

# 9. Conclusion

Admission control for LLM inference serving is a distinct sub-problem
that governs whether downstream batching, KV management, and preemption
have the capacity headroom to succeed. Between 2022 and 2026 the field
produced thirteen admission-primary works at peer-reviewed top venues
(CONCUR ICML 2026, Shen et al. ICML 2026, QLM SoCC 2024, Chronos
Frontiers CS 2026, SOLA MLSys 2025, FastServe NSDI 2026, AQUA ASPLOS
2025, VTC OSDI 2024, KVFlow NeurIPS 2025, Cake ICML 2025, InferCept
ICML 2024, Pie SOSP 2025, ThunderAgent ICML 2026 Spotlight) plus one
accepted workshop paper (Continuum ICLR 2026 Workshop on Lifelong
Agents) and more than a dozen preprints. We surveyed fifty-two works
across admission-primary, admission-adjacent, and scheduling clusters.

Our four-axis taxonomy (unit, setting, SLO-awareness, signal used) with
four sub-branches (signal structure, SLO granularity, fairness type,
concurrency context) organizes the corpus without redundancy. The
canonical agent-level × online × deadline-aware × fair intersection is
empty.

Nine top-venue scheduling papers from OSDI, SOSP, ASPLOS, EuroSys,
MLSys, and HPCA do not include ingress-level admission control (Table
3). Production postmortems from OpenAI, Anthropic, Cloudflare, and
Azure (Table 4) show that overload originating from a mis-specified
admission signal propagates faster than downstream batching, migration,
or autoscaling can absorb, so these techniques are insufficient on
their own.

Reproducibility of individual artifacts is higher than commonly framed
at thirteen of forty. Reproducibility of cross-paper comparison
is essentially zero (Table 2). The methodology contract we propose in
Section 6.1 would close this gap without demanding that any paper
change its primary evaluation.

Seven open problems (Section 8) each carry either public peer-review
evidence or the primary source's own limitation statement. The most
tractable candidates for near-term progress are the
request-level-versus-agent-level cross-comparison (Open Problem 1),
online admission for agentic workloads (Open Problem 2), and the
methodology contract itself (Open Problem 7). Each is a plausible next
contribution for a small research group.

We call for the community to converge on a common methodology contract
so that the next admission-control paper's numbers can be compared to
its predecessors. Without that convergence, this survey's per-paper
notes are a taxonomy of incompatible measurements rather than a
comparison of policies.

# References

Full BibTeX references live in references.bib. Selected citations
(complete listing forthcoming in v0.2):

- Abhyankar et al., "InferCept: Efficient Intercept Support for Augmented Large Language Model Inference," ICML 2024.
- Agrawal et al., "Sarathi-Serve: Taming Throughput-Latency Tradeoff in LLM Inference," OSDI 2024.
- Anthropic API Documentation, "Errors," 2026. docs.anthropic.com/en/api/errors.
- Ao, Dong, Luo, and Simchi-Levi, "Service-Induced Congestion in Memory-Constrained LLM Serving," arXiv:2606.15555, 2026.
- Ao, Luo, Simchi-Levi, and Wang, "Optimizing LLM Inference: Fluid-Guided Online Scheduling with Memory Constraints," arXiv:2504.11320, 2025.
- Chen et al., "CONCUR: High-Throughput Agentic Batch Inference of LLM via Congestion-Based Concurrency Control," ICML 2026.
- Chen et al., "SLOs-Serve: Optimized Serving of Multi-SLO LLMs," arXiv:2504.08784, 2025.
- Dong and Cao, "Flow-Controlled Scheduling for LLM Inference with Provable Stability Guarantees," arXiv:2604.11001, 2026.
- Elnikety et al., "Ascendra: Dynamic Request Prioritization for Efficient LLM Serving," arXiv:2504.20828, 2025.
- Gim et al., "Pie: A Programmable Serving System for Emerging LLM Applications," SOSP 2025.
- Heisler et al., "LLM Inference Scheduling: A Survey of Techniques, Frameworks, and Trade-offs," TechRxiv, November 2025.
- Hong et al., "SOLA: Optimizing SLO Attainment for LLM Serving with State-Aware Scheduling," MLSys 2025.
- Jaillet et al., "Online Scheduling for LLM Inference with KV Cache Constraints," arXiv:2502.07115, 2026.
- Jin et al., "Cake: Compute or Load KV Cache? Why Not Both?," ICML 2025.
- Kang et al., "ThunderAgent: A Simple, Fast and Program-Aware Agentic Inference System," ICML 2026 Spotlight.
- Kumar, Antichi, and Singh, "AQUA: Network-Accelerated Memory Offloading for LLMs in Scale-Up GPU Domains," ASPLOS 2025.
- Kwon et al., "Efficient Memory Management for LLM Serving with PagedAttention," SOSP 2023.
- Li et al., "Continuum: Efficient and Robust Multi-Turn LLM Agent Scheduling with KV Cache Time-to-Live," ICLR 2026 Workshop on Lifelong Agents.
- Li et al., "LLM Inference Serving: Survey of Recent Advances and Opportunities," IEEE HPEC 2024.
- Lu et al., "Equinox: Holistic Fair Scheduling in Serving Large Language Models," arXiv:2508.16646, 2025.
- Lyu et al., "FairBatching: Fairness-Aware Batch Formation for LLM Inference," arXiv:2510.14392, 2025.
- Marref, Tarmissi, and Chaibi, "Formal Schedulability Analysis for LLM Inference: TTFT and TBT Deadline Guarantees via Response-Time Theory (Chronos)," Frontiers in Computer Science, June 2026.
- Mitzenmacher and Shahout, "Queueing, Predictions, and LLMs: Challenges and Open Problems," SIGMETRICS 2025 tutorial (arXiv:2503.07545).
- Pan et al., "KVFlow: Efficient Prefix Caching for Accelerating LLM-Based Multi-Agent Workflows," NeurIPS 2025.
- Patke et al., "Hierarchical Autoscaling for LLM Serving with Chiron," arXiv:2501.08090, 2025.
- Patke et al., "Queue Management for SLO-Oriented Large Language Model Serving," SoCC 2024.
- Qin et al., "Mooncake: Trading More Storage for Less Computation," FAST 2025.
- Shen, Xu, Ye, Glynn, and Jaillet, "A Two-Layer Framework for Joint Online Configuration Selection and Admission Control," ICML 2026.
- Sheng et al., "Fairness in Serving Large Language Models," OSDI 2024.
- Sun et al., "Llumnix: Dynamic Scheduling for Large Language Model Serving," OSDI 2024.
- Sundaresan, "Clairvoyant: Predictive Shortest-Job-First Admission for Serial LLM Inference," arXiv:2606.07248, 2026.
- Wu et al., "FastServe: Fast Distributed Inference Serving for Large Language Models," NSDI 2026.
- Yu et al., "Orca: A Distributed Serving System for Transformer-Based Generative Models," OSDI 2022.
- Zhen et al., "Taming the Titans: A Survey of Efficient LLM Inference Serving," INLG 2025.
- Zhong et al., "DistServe: Disaggregating Prefill and Decoding for Goodput-Optimized Large Language Model Serving," OSDI 2024.

Production incident references (postmortems):
- OpenAI incident history at status.openai.com: DALL·E queue collapse (rllgb3r2rqsf); November 8 2023 tipping point (00fpy0yxrx1q); April 10 2025 failover (01JMYB59DYSH9TF6JV52TWBGRG); December 11 2024 delayed cliff (ctrsv3lwd797); November 25 2024 large-cluster cliff (01JMYB4BYHJWDV9A51ZPA86YBQ).
- Anthropic incident history at status.claude.com: January 21 2026 capacity miss (yrxt885v63jw); November 25 2025 529 overloaded (5g213mxxlbsw); August 29 2025 wrong-pool routing; engineering postmortem at www.anthropic.com/engineering/a-postmortem-of-three-recent-issues.
- Cloudflare rate limiting posts (2017, 2022) at blog.cloudflare.com.
- Azure 2016 systems talk on capacity signals.

---

*Version: v0.2 draft, 2026-09-11. Prepared for arXiv preprint and CSUR Emerging Topics submission. Companion artifacts: survey outline (docs/outline.md), taxonomy (docs/taxonomy.md), open problems catalog (docs/open-problems.md), per-paper notes (notes/), reproducibility audit rows and evaluation log (docs/eval-log.md).*
