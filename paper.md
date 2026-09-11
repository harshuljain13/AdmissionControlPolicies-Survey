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
  management. In parallel, a distinct thread of admission-primary work has
  grown quickly: fourteen peer-reviewed papers at top venues plus more
  than a dozen preprints propose admission policies operating at request,
  agent-session, or tenant granularity, under online or offline settings,
  guided by cache pressure, deadline slack, queue depth, or joint linear
  programs. No two of these policies have been compared to each other on
  a common trace, engine, or metric. This paper surveys forty admission
  and admission-adjacent works. We propose a four-axis taxonomy with
  sub-branches for signal structure, service-level-objective granularity,
  fairness type, and concurrency context. We audit reproducibility across
  the corpus and find a methodology gap that persists even where code is
  released. We derive seven open problems, each grounded in either
  published peer-review discussion or the primary source's own limitation
  statement.
---

# 1. Introduction

On November 8, 2023, OpenAI's inference fleet crossed a soak point after
a day of unusually heavy completion traffic. Routing nodes reached
memory limits and failed readiness checks. Additional replicas were
added, then rolled back. Recovery required cutting inbound traffic,
redeploying, and slowly ramping load back up. Two years later, on
January 21, 2026, Anthropic's Sonnet 4.5 tier degraded first in latency
and then in error rate over roughly ninety minutes. The postmortem cited
insufficient compute capacity for demand and named earlier detection of
capacity constraints as a required change. Cloudflare, Azure, and other
production operators have documented similar sequences: a system whose
service process itself creates future capacity pressure, an admission
decision made against the wrong signal, and a control plane that
responds to the wrong metric.

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
LLM systems specifically (Mitzenmacher and Shahout, 2025). No published
survey treats admission control as the primary organizing axis.

This paper fills that gap. We deep-read forty works between 2022 and
2026 across admission-primary, admission-adjacent, scheduling, memory
management, fairness, and queueing-theoretic clusters. Contributions:

- A four-axis taxonomy with four sub-branches (Section 3).
- A per-cluster synthesis of the admission literature (Section 5).
- An empirical audit of reproducibility across the corpus, showing that
  the crisis is at the methodology level rather than the artifact level
  (Section 6).
- A mapping of production incidents to admission failure modes (Section
  7).
- Seven open problems, each with cited evidence from either public peer
  review or the primary source's own limitations (Section 8).

We ground three headline observations. First, of nine top-venue serving
papers we audited, none includes an ingress-level admission policy;
overload is absorbed by batching or elasticity. Second, of fourteen
admission-primary papers we audited, no two share a baseline system,
metric definition, trace, model, or engine, making cross-policy
comparison impossible from the literature alone. Third, the taxonomy
holds across all forty works with four sub-branches added during our
reading, none of which required backing out an original axis.

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
admission rule that only checks instantaneous memory feasibility, and
that throughput along the resulting limit cycle can drop by up to fifty
percent under long-output workloads. Their Theorem 3 further shows that
stability depends on the greatest common divisor of active decoding
lengths: coprime workloads stabilize, workloads with a common divisor
synchronize into eviction cycles. This is a workload-arithmetic property
of admission decisions that no production system currently exposes.

# 3. Taxonomy

We organize admission-control policies along four axes. Sub-branches
were added during our reading and are called out explicitly.

## 3.1 Axis 1: Unit of admission

Admission decisions can be made at three granularities. Request-level
policies admit or reject each incoming prompt independently (QLM, Patke
et al., 2024; Chronos, Marref et al., 2026; FastServe, Wu et al., 2026;
SOLA, Hong et al., 2025). Agent-session-level policies admit or reject
entire multi-turn agent trajectories, treating each session as the
atomic unit (CONCUR, Chen et al., 2026; Continuum, Li et al., 2026;
ThunderAgent, Kang et al., 2026). Tenant-level policies gate admission
per user or per organization (VTC, Sheng et al., 2024).

## 3.2 Axis 2: Setting

Online serving handles interactive latency-sensitive workloads (most of
the field). Offline batch handles throughput-oriented inference where
per-request deadlines are relaxed (CONCUR is explicitly offline per its
meta-review). Hybrid settings mix both (Aegaeon, Yang et al., 2025).

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
minimize dollars or energy per token (EconoServe, Wu et al., 2024).

### 3.3.1 Sub-branch: SLO granularity

SLOs-Serve (Chen et al., 2025) exposes a design axis nobody else covers.
Job-level SLOs specify a single deadline per multi-turn agent job
(Continuum's job-completion-time framing). Request-level SLOs specify
one deadline per prompt (most of the field). Per-stage SLOs specify
distinct deadlines per stage of a multi-turn application: tight TTFT on
tool-call prefill, loose TPOT on reasoning decode, tight TPOT on final
answer. Only SLOs-Serve models the per-stage case, and this is a
genuine taxonomy gap: Llumnix, DynamoLLM, ExeGPT, and VTC each model a
single SLO per request.

### 3.3.2 Sub-branch: Fairness type

Task-fairness allocates GPU cycles equitably between prefill and decode
tasks within one batch (FairBatching, Lyu et al., 2025). Tenant-fairness
equalizes served tokens or SLO attainment across users (VTC, Equinox).
These two objectives share no mechanism. FairBatching's "fairness" would
mislead a reader looking for multi-tenant isolation. The two must be
distinct in any survey.

## 3.4 Axis 4: Signal used

Admission policies read a runtime signal to decide. We identify four
structural forms.

Scalar heuristics compare a single quantity to a threshold (KV
utilization for Fluid-WAIT; queue depth as one input for QLM; predicted
output length for Clairvoyant; deadline slack for Chronos in one of its
tests).

Dual-gate conjunctions require multiple signals to agree before firing.
CONCUR's controller declares congestion only when both KV utilization is
high and prefix cache hit rate is low, because high utilization with
high hit rate is healthy reuse rather than thrashing. This is a
structural refinement of scalar admission.

Linear-program-based composite signals treat admission as one variable
in a joint optimization. QLM formulates a linear program over virtual
queues, minimizing total SLO-violation penalty subject to
one-to-one-request-group-to-position constraints. SOLA runs a per-iteration
LP over five or more state variables. SLOs-Serve uses dynamic programming
over token allocations.

Formal worst-case-response-time bounds derive an admission test from
real-time-systems theory. Chronos casts prefill as a sporadic job with
worst-case execution time proportional to input length, then derives a
closed-form WCRT bound whose feasibility test decides admission on each
arrival.

## 3.5 The unclaimed intersection

Plotting the corpus on Unit × SLO-awareness shows that
`agent-level × online × deadline-aware × fair` is empty. CONCUR is
agent-level but offline and throughput-oriented. Chronos is deadline-aware
but request-level. FairBatching is fair but task-level not tenant-level.
No published policy occupies the intersection. This is the seed for
Open Problem 1.

# 4. Method

We selected forty works spanning the period from Orca (Yu et al., OSDI
2022) through ThunderAgent (Kang et al., ICML 2026 Spotlight). Selection
proceeded in three passes.

The first pass surveyed all papers whose title or abstract explicitly
names admission control, queue management, request rejection, load
shedding, or SLO-oriented scheduling. This produced fifteen tier-one
candidates.

The second pass extended to fairness papers, queueing-theory tutorials,
and KV-cache-management papers whose mechanism has direct admission
implications. This added eight tier-two and six tier-three works.

The third pass extended to top-venue serving papers where admission
appears as a component of a broader scheduling contribution. This added
nine tier-four works and confirmed the 9-for-9 headline finding.

For each work we recorded venue, authors, arXiv or DOI identifier, code
availability, taxonomy placement across all four axes, primary
contribution, baseline set, evaluation setup, claimed headline numbers,
fidelity notes, and open questions surfaced. Notes were written in a
common template to make cross-work comparison tractable. The complete
per-paper corpus lives in the survey's public artifact.

We did not run experiments. Where papers report conflicting numbers, we
report each source's number as stated and flag the conflict rather than
adjudicate.

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
range from forty to ninety percent SLO attainment lift and twenty to
four-hundred percent throughput gain over vLLM and EDF baselines. Code
is public at `github.com/QLM-project/QLM`. QLM is deployed inside IBM's
internal routing service.

Chronos (Marref et al., Frontiers in Computer Science 2026) is the first
paper to derive a formal schedulability condition for LLM inference.
Each request becomes a sporadic prefill job with WCRT bound
`ρP·DTTFT/(1−ρP) + pᵢ·(αB + γ)` where ρP is prefill utilization and
pᵢ is the number of chunks. Algorithm 1 runs on each arrival and
rejects if prefill utilization exceeds one, if the WCRT bound exceeds
the TTFT deadline, or if a TBT capacity check fails. On a 7B model
evaluated in a discrete-event simulator against 50,000 sampled Azure
requests, Chronos delivers 0.00% TTFT miss rate at 5× nominal load
while FCFS and EDF miss 99.44% at 10× load. A throughput-matched
token-bucket baseline (AC-FCFS) still misses 15.4% at the same admission
volume, showing that formal feasibility testing dominates matched rate
limiting. Simulator code is public.

SOLA (Hong et al., MLSys 2025) formalizes fine-grained scheduling as an
LP over per-request and systemic state. Empirical scheduling raises SLO
attainment from 45.5% to 99.4% and serves 1.04-1.27× more requests. The
constraint-relaxation mechanism at the α-percentile is an implicit
admission decision hidden inside a scheduler: when the LP is
infeasible, the system sacrifices (1-α)% of requests to preserve the
guarantee for the rest.

FastServe (Wu et al., NSDI 2026) argues for token-granularity preemption
rather than reject-on-arrival admission. A skip-join multi-level
feedback queue promotes short-remaining requests, and proactive KV
offload keeps preempted state cheaply resumable. Reported throughput is
31.4× versus vLLM v0.1.7 under average latency requirements. The
headline is against a pre-continuous-batching vLLM release and should be
read accordingly.

SLOs-Serve (Chen et al., 2025) is the only paper in our corpus that
handles per-stage-of-agent SLOs. Its multi-SLO DP algorithm optimizes
token allocations under joint deadlines, admits requests whose SLOs are
jointly attainable, and declines the rest through soft admission. On
six workloads across OPT-7B/13B/30B, ToolLlama-7B, and DeepSeek-R1-1.5B,
it reports 2.2× geometric-mean per-GPU serving capacity. Preprint only.

## 5.2 Agent-session-level admission

CONCUR (Chen et al., ICML 2026) identifies middle-phase thrashing in
agentic batch inference: sustained low prefix-cache hit rate during the
middle of a long-horizon session, driven by cumulative KV pressure
across turns. The controller reads two signals, KV utilization U_t and
hit rate H_t, and declares congestion only when both fire (U_t high AND
H_t low). Additive-increase-multiplicative-decrease adjusts the number
of concurrently admitted agent sessions with α=2 and β=0.5. Fixed
hyperparameters work across Qwen3-32B and DeepSeek-V3 with less than
three percent throughput swing. Headline gains are 4.09× throughput
against SGLang on Qwen3-32B at batch 256, tensor parallelism 8, on 8
H100 GPUs, and 1.90× against SGLang on DeepSeek-V3 at 16 H100 GPUs.
Against Continuum as a baseline, CONCUR shows 1.69× on Qwen3-32B. The
meta-review states the paper targets offline throughput-oriented
inference and that online serving is out of scope.

Continuum (Li et al., ICLR Workshop on Lifelong Agents 2026) manages KV
retention rather than gating admission. Per-session time-to-live is set
by maximizing expected benefit minus cost, using an empirical CDF of
tool-call durations. A two-part cost model adds an out-of-order term
that InferCept (Abhyankar et al., ICML 2024) does not, which the paper
identifies as its key delta over prior art. Continuum operates entirely
after admission and reports 1.12-3.66× JCT improvement across
Llama-3.1, Gemma-3, and GLM-4.5 on SWE-Bench, BFCL, and OpenHands, with
a peak of 8.18× on an internal deployment. Public vLLM fork at
`github.com/Hanchenli/vllm-continuum`.

ThunderAgent (Kang et al., ICML 2026 Spotlight, integrated into NVIDIA
Dynamo 2.0) treats disk, ports, and sandboxes as first-class scheduled
resources alongside GPU. A central scheduler pauses and restores
programs with explicit state migration, providing agent-level admission
through admission gating and cross-node migration for HBM balance. This
is the first paper in our corpus to model tool-side admission as a
first-class contribution alongside LLM-side admission. Sub-branch of the
agent-level cluster.

## 5.3 Fairness-aware admission and scheduling

VTC (Sheng et al., OSDI 2024) formalizes LLM-serving fairness through a
cost function over tokens processed rather than requests, defaulting to
w_p=1 for input and w_q=2 for output (matching OpenAI's 1:2 pricing
ratio). The Virtual Token Counter prioritizes the least-served backlogged
client at each continuous-batching step. Counter-lift on client return
prevents accumulated credit exploits. The theoretical guarantee bounds
service difference between any two continuously-backlogged clients at
2·max(w_p·L_input, w_q·M), with a matching lower bound proving the
factor is tight. Empirically VTC halves max unfairness versus FCFS while
matching throughput (779 versus 777 tok/s on 27 Chatbot Arena clients),
whereas RPM(5) rate limiting collapses throughput to 340 tok/s.
Artifact-evaluated code at `github.com/Ying1123/VTC-artifact`.

FairBatching (Lyu et al., 2025) attacks a different fairness axis:
between prefill and decode tasks within a batch. Sarathi-Serve's
stall-free batching excessively prioritizes decode; FairBatching's
enhanced-EDF adaptive-capacity batch formation achieves 2.29× tail
latency reduction and 20% single-node capacity improvement. The
implementation is only 90 LoC of invasive vLLM changes, correcting an
earlier feasibility estimate of 800-1200 LoC.

Equinox (Lu et al., 2025) argues that equal tokens do not imply equal
user experience. A dual counter combines a user-facing fairness counter
(latency-penalized served tokens) and a resource fairness counter
(throughput times GPU utilization) into a holistic score. Equinox
requires a Model of Prediction Ensemble (three BERT-base plus a
router) to predict output length, latency, throughput, and GPU
utilization from prompt text. Reported thirteen percent fairness
improvement is measured against Equinox's own holistic fairness metric,
not a mechanism-independent metric.

## 5.4 Queueing-theoretic and algorithmic

Service-Induced Congestion (Ao et al., 2026) provides the theoretical
justification for the entire field. Section 2.4 already discussed the
50% throughput bound and the GCD stability criterion. The paper's
scheduling design principles include using coprimality of active
decoding lengths as a diagnostic for synchronization risk and injecting
mild jitter into decode-length distributions to break the GCD.
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
public at
`github.com/owenshens/A-Two-Layer-Framework-for-Joint-Online-Configuration-Selection-and-Admission-Control`.

Jaillet et al. (2026) target online scheduling under KV-cache
constraints with per-request memory that grows monotonically during
decode. The MC-SF policy achieves an Ω(√n) lower bound and O(1) upper
bound under structured arrival plus α-accurate predictions.

Mitzenmacher and Shahout (SIGMETRICS 2025 tutorial) enumerate 25 open
problems at the intersection of queueing theory and LLM serving,
including practical Gittins-index policies, distributional service-time
predictions, tail-behavior analysis of prediction-augmented queues, and
heterogeneous-GPU prefill-decode balance. Our Section 8 draws on this
enumeration.

Clairvoyant (Sundaresan, 2026) is the sole entry in the serial-edge
concurrency-context sub-branch. Predictive shortest-job-first uses an
XGBoost classifier over 19 lexical features to route around
head-of-line blocking on Ollama and llama.cpp backends, delivering 70-76%
short-request p50 latency reduction on an RTX 4090 under mixed bursts.
The paper's negative result on curated instruction datasets (Alpaca has
four Long-class examples out of 52,000 responses, or 0.008%) is a
reusable finding for anyone training length predictors.

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
limitation. No admission logic.

Pie (Gim et al., SOSP 2025) provides a programmable serving substrate
with generation-loop handlers and KV page management. There is no
cross-inferlet scheduler API, no admit-reject hook, and no per-tenant
fairness state. Admission policies would require developer-added host
extensions. FCFS-terminate-newest is the only built-in overload
response.

## 5.6 Scheduling papers with admission-adjacent components

We audited nine top-venue scheduling papers (Sarathi-Serve OSDI 2024,
Llumnix OSDI 2024, DistServe OSDI 2024, Orca OSDI 2022, Aegaeon SOSP
2025, Jenga SOSP 2025, Past-Future ASPLOS 2025, AdaServe EuroSys 2026,
PASCAL HPCA 2026). None includes ingress-level admission control. All
respond to overload via batching (Sarathi-Serve, Orca), live migration
(Llumnix), placement (DistServe), autoscaling (Aegaeon), memory
management (Jenga), batch-boundary memory projection (Past-Future),
speculative decoding tuning (AdaServe), or runtime phase detection
(PASCAL). Past-Future's memory-projection gate at the batching boundary
is the closest of the nine to admission, and it operates on already-queued
requests rather than at ingress. This 9-for-9 result is our motivation
for treating admission as an under-explored primary contribution.

# 6. Reproducibility and comparison methodology

We audited public code availability across our corpus. Thirteen of
thirty-four deep-read papers have released code as of September 2026:
QLM, Chronos (simulator), FastServe (on SwiftTransformer engine, not
vLLM), Shen et al., Continuum, Clairvoyant, AQUA, VTC, KVFlow,
InferCept, Pie, ThunderAgent, and Cake. This is higher than the
"reproducibility crisis" framing common in prior surveys of the space
would suggest.

The real crisis is at the methodology level. We compared the baseline
sets used by each admission-primary paper across our corpus. No two
papers share a baseline system. CONCUR compares against SGLang, HiCache,
and Continuum. QLM compares against vLLM, EDF, and SHEPHERD. Chronos
compares against FCFS, EDF, SLAI, and AC-FCFS. SOLA compares against
vLLM-D, vLLM-S (their own SplitFuse reimplementation to control for
operator noise), and SJF. Fluid-WAIT compares against "widely used
baseline algorithms" without naming them. FairBatching compares against
Sarathi. Ascendra compares against SHEPHERD. Zero overlap.

Model choices, engine choices, workload traces, and metric definitions
also diverge. Chronos evaluates a 7B model on a discrete-event simulator
against 50,000 Azure requests. CONCUR evaluates Qwen3-32B and DeepSeek-V3
on SGLang against BrowserComp on 16 H100 GPUs. QLM evaluates Mistral-7B,
Vicuna-13B, and LLaMA-70B on vLLM against ShareGPT on a heterogeneous
80-GPU cluster. SOLA evaluates OPT-7B/13B/30B on vLLM v0.4.2 on 8 A100s
against ShareGPT and LongBench. Reading the literature top to bottom,
a practitioner cannot answer "which admission policy wins on my
workload."

We propose that future admission papers commit to reporting against a
minimum common baseline set (vLLM default, one from CONCUR/Chronos/QLM),
a common trace subset (Azure LLM inference trace plus at least one
agentic trace such as SWE-Bench), and a common metric suite (goodput at
target SLO, agent-completion rate, per-tenant Jain fairness index). This
is a methodology contract, not a benchmark, and is compatible with each
paper's own primary evaluation.

# 7. Production evidence

Real inference-fleet incidents map directly onto admission failure
modes. We draw on public postmortems from OpenAI, Anthropic,
Cloudflare, and Azure.

**Wrong capacity signal (Azure 2016).** A model-configuration bug
produced HTTP 400 responses. A metadata fetcher failed. The scheduler
inferred that most backends were unavailable and concentrated traffic
in one region. Rate limiting returned HTTP 429 for approximately
3.5-4 hours. The control plane created the overload; user request rate
did not. Admission and routing decisions based on the wrong signal can
be worse than no signal at all.

**Soak cliff after cache expiry (OpenAI DALL·E 2023, OpenAI December
2024).** DALL·E's queue collapsed after five-minute cancellation
windows: work already past its client timeout continued to consume
capacity. Success rate progressed 10% → 25% → 0%. In December 2024, new
telemetry caused every node to contact the Kubernetes API. The control
plane failed but the data plane continued using stale DNS for
approximately twenty minutes. When TTLs expired, the data plane failed.
Dashboards can look healthy until a TTL expires. Aggregate utilization
can appear safe while tail latency has already collapsed.

**Failover with wrong error contract (OpenAI April 2025).** A
control-plane out-of-memory failure moved traffic to a healthy cluster.
Pod churn overloaded the second cluster's control plane. Rate limiting
kicked in and users received misleading errors. Failover without
shedding moves the cliff rather than fixing it.

**Capacity miss followed by ninety-minute error window (Anthropic
January 2026).** Insufficient compute was allocated for demand. Latency
degraded first, then errors. Additional serving resources resolved the
issue. Earlier detection of capacity constraints was named as required.
Admission that continues past the pool's real capacity accumulates
requests that will miss their deadline in queue rather than shedding
early enough to preserve those already admitted.

**Wrong-pool traffic (Anthropic August 2025).** A routine load-balancer
change moved short-context traffic to servers configured for
one-million-token contexts. Impact grew from 0.8% to 16% of Sonnet 4
traffic. Placement decisions are admission-adjacent: a healthy
utilization number for the wrong pool can hide an approaching cliff.

**Provider-overloaded error contract (Anthropic 2025).** Anthropic
introduced HTTP 529 as a distinct provider-overloaded state, separate
from HTTP 429 (client rate limit exceeded) and HTTP 503 (temporarily
unavailable). The distinction matters: aggressive retries after a
provider-overloaded response amplify the pressure, whereas backoff after
a client-rate-limit response is correct.

For each incident type, we identify the leading capacity signal that
would have prevented it. The DALL·E soak cliff needed queue-age at
admission, not just queue depth. The December 2024 delayed cliff needed
control-plane health independent of data-plane cached state, not stale
DNS. The April 2025 failover needed correct error contract propagation.
The January 2026 capacity miss needed earlier detection than the
metrics-dashboard update interval.

# 8. Open problems

Section 8 lists seven high-signal open problems. Each cites concrete
evidence from either published peer review or the primary source's own
limitations. The survey artifact contains a longer catalog of 37
candidate open problems.

## 8.1 Request-level versus agent-level admission head-to-head

The CONCUR reviewer discussion at ICML 2026 (submission 14315,
OpenReview forum `mmdqUrEY24`) contains this exchange: Reviewer Afcg
maintained a weak-accept score with the final justification "the
underlying problem can be addressed through more effective request-level
scheduling (e.g., deciding whether to admit or defer a request under
current memory constraints). I would therefore suggest that the paper
include a discussion of this perspective in the final version." CONCUR
added a Continuum comparison in rebuttal but did not add a request-level
baseline. The empirical question of whether request-level admission
(QLM, Chronos, Fluid-WAIT) can match agent-level admission (CONCUR) on
agentic workloads remains unresolved in the literature.

## 8.2 Online serving admission for agentic workloads

The CONCUR meta-review states "the authors should explicitly state that
the paper targets offline throughput-oriented agentic inference, and
expand the discussion of fairness, online serving, and the relationship
to complementary cache-management and scheduling approaches." All
published agent-level admission systems (CONCUR, Continuum,
ThunderAgent) target offline batch. Online agent-level admission with
SLO awareness is an open design point that the field has not yet
attempted.

## 8.3 Multi-tenant admission with per-tenant SLOs

VTC handles fairness in served tokens across tenants. FairBatching
handles fairness between prefill and decode tasks within a batch.
Neither handles per-tenant deadline SLOs with tenant-aware admission
decisions. Real production workloads are multi-tenant. Two tenants with
equal served-token counts under VTC can have wildly different perceived
TTFT variance. No policy in the corpus explicitly models tenant-SLO
fairness under admission control.

## 8.4 Reasoning-trace-aware admission at ingress

PASCAL (HPCA 2026) addresses phase-aware scheduling for
reasoning-augmented LLMs, but its phase detection is entirely runtime:
the scheduler observes the reasoning-to-answering transition after
decoding has started. Ingress-level reasoning-versus-chat classification
would let admission control gate long-CoT traffic before KV pressure
accumulates. The literature does not include this. o1-, R1-, and
DeepSeek-R1-style workloads have KV-growth profiles that break
chat-optimized admission assumptions.

## 8.5 Coupling admission with autoscaling and routing

Chiron (Patke et al., 2025) autoscales replicas across a heterogeneous
GPU fleet. QLM (same Patke research group, SoCC 2024) does per-replica
SLO-aware queueing. The two never appear in the same evaluation. A
future policy that jointly optimizes across replica count, replica
routing, and per-replica admission would close a gap that both papers
individually acknowledge as future work. Ao et al.'s stability analysis
gives the theoretical hook: admission and routing decisions interact
through KV pressure that neither can control alone.

## 8.6 Formal schedulability with LLM-specific WCRT

Chronos derives closed-form WCRT bounds under a linear kernel model
(τ = αn_P + βn_D + γ) with roofline-derived parameters, never measured
on real silicon. Deterministic WCET is known to be conservative for
LLM workloads because prefill-chunk boundaries, tensor-core alignment
effects, and KV fragmentation break linearity in practice. Probabilistic
WCET analysis, mixed-criticality models with per-tenant SLO classes,
and formal analysis under disaggregated prefill/decode topologies are
all open.

## 8.7 Reproducibility at the methodology level

Thirteen of thirty-four deep-read papers have released code, refuting
the common framing that the field has no artifacts. What the field
lacks is a common methodology contract: a shared baseline set, trace
subset, and metric suite that would make cross-paper comparison
tractable. Without this, released code enables reproducing each paper's
own numbers but not comparing them to a competing paper. We proposed a
minimal common methodology contract in Section 6.

# 9. Conclusion

Admission control for LLM inference serving is a distinct sub-problem
that governs whether downstream batching, KV management, and preemption
have the capacity headroom to succeed. Between 2022 and 2026, the field
produced fourteen admission-primary works at peer-reviewed top venues
(CONCUR ICML 2026, Shen et al. ICML 2026, QLM SoCC 2024, Chronos
Frontiers CS 2026, SOLA MLSys 2025, FastServe NSDI 2026, AQUA ASPLOS
2025, VTC OSDI 2024, Continuum ICLR 2026 workshop, KVFlow NeurIPS 2025,
Cake ICML 2025, InferCept ICML 2024, Pie SOSP 2025, ThunderAgent ICML
2026 Spotlight) plus more than a dozen preprints. We surveyed forty
works across admission-primary, admission-adjacent, and scheduling
clusters.

Our four-axis taxonomy (unit, setting, SLO-awareness, signal used) with
four sub-branches (signal structure, SLO granularity, fairness type,
concurrency context) organizes the corpus without redundancy. The
canonical `agent-level × online × deadline-aware × fair` intersection
is empty, a direct gap for future work.

Nine top-venue scheduling papers from OSDI, SOSP, ASPLOS, EuroSys,
MLSys, and HPCA do not include ingress-level admission control, absorbing
overload through batching, migration, placement, autoscaling, or memory
management. This is not because those techniques suffice; production
postmortems from OpenAI, Anthropic, Cloudflare, and Azure show
repeatedly that overload originating from the wrong admission signal
propagates faster than downstream mechanisms can absorb.

Reproducibility of individual artifacts is higher than commonly framed;
reproducibility of cross-paper comparison is essentially zero because no
two admission-primary papers share a baseline set, model, engine, trace,
or metric definition. A minimal common methodology contract (Section 6)
would close this gap without demanding that any paper change its
primary evaluation.

Seven open problems (Section 8) each carry either public peer-review
evidence or the primary source's own limitation statement. The most
tractable are the request-level-versus-agent-level cross-comparison
(Open Problem 1), online admission for agentic workloads (Open Problem
2), and the methodology contract itself (Open Problem 7). Each is a
plausible next contribution for a small research group without
requiring a full new system.

The survey artifact (per-paper notes, taxonomy tables, reproducibility
audit rows, complete open-problem catalog) is available at the arXiv
preprint URL and at the survey's public git repository.

# References

Full BibTeX references live in `references.bib`. Selected citations
(complete listing forthcoming in v0.2):

- Abhyankar et al., "InferCept: Efficient Intercept Support for Augmented Large Language Model Inference," ICML 2024.
- Agrawal et al., "Sarathi-Serve: Taming Throughput-Latency Tradeoff in LLM Inference," OSDI 2024.
- Anthropic API Documentation, "Errors," 2026. `docs.anthropic.com/en/api/errors`.
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
- OpenAI incident history at `status.openai.com`: DALL·E queue collapse; November 8 2023 tipping point; April 10 2025 failover; December 11 2024 delayed cliff; November 25 2024 large-cluster cliff.
- Anthropic incident history at `status.claude.com`: January 21 2026 capacity miss; November 25 2025 529 overloaded; August 29 2025 wrong-pool routing; engineering postmortem at `www.anthropic.com/engineering/a-postmortem-of-three-recent-issues`.
- Cloudflare rate limiting posts (2017, 2022).
- Azure 2016 systems talk on capacity signals.

---

*Version: v0.1 draft, 2026-09-11. Prepared for arXiv preprint and CSUR Emerging Topics submission. Companion artifacts: survey outline (`outline.md`), taxonomy (`taxonomy.md`), open problems catalog (`open-problems.md`), per-paper notes (`papers/`), reproducibility audit rows and evaluation log (`eval-log.md`).*
