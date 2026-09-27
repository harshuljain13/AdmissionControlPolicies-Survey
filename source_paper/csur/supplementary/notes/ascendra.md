# Ascendra: Dynamic Request Prioritization for Efficient LLM Serving

- **Full title**: Ascendra: Dynamic Request Prioritization for Efficient LLM Serving
- **Authors**: Azam Ikram (Purdue), Xiang Li (Purdue), Sameh Elnikety (Microsoft Research), Saurabh Bagchi (Purdue)
- **Venue**: arXiv preprint (CoRR abs/2504.20828), submitted 2025-04-29 (v2 2025-04-30). No peer-reviewed venue listed on DBLP as of fetch date.
- **Links**: [abs](https://arxiv.org/abs/2504.20828) | [html](https://arxiv.org/html/2504.20828) | [pdf](https://arxiv.org/pdf/2504.20828)
- **Code**: None released as of fetch date (no repo link in abstract or HTML landing).
- **Fetched**: 2026-09-10

## Abstract

Ascendra targets the joint optimization of Time-To-First-Token (TTFT) and Time-Between-Tokens (TBT) SLOs in LLM serving. It partitions GPU resources into two instance pools — **low-priority (LP)** instances that maximize throughput via out-of-order scheduling, and **high-priority (HP)** instances tuned for latency-sensitive execution. A performance model predicts which in-flight or queued requests are at risk of missing their TTFT deadline and proactively migrates them from LP to HP. Under transient overload, requests whose TTFT deadline has already been exceeded in the waiting queue are dropped outright to prevent cascading SLO violations. The system claims up to 1.7x goodput improvement over vLLM and Sarathi-Serve while jointly meeting TTFT and TBT SLOs.

## Taxonomy placement

- **Unit of admission**: request (per-request TTFT deadline check drives the drop decision).
- **Signal type**: **admission-adjacent / hybrid**. The primary mechanism is a two-tier priority scheduler with LP→HP promotion (a scheduling/routing decision, not a gate). However, the explicit "drop if TTFT deadline exceeded in queue" rule is a genuine **admission-side action** — it removes work from the system rather than reordering it. This is one of the few serving papers that surfaces drop as a first-class action rather than an implicit consequence of timeout.
- Best fit in the survey: cross-listed in **§5.1 (request-level admission)** as an example of explicit drop-on-deadline, and in **§5.6 (priority scheduling)** as the mechanism's primary framing.

## Contribution

- **Two-tier instance partitioning** (LP vs HP) with distinct scheduling policies per tier — LP is throughput-first (out-of-order, larger batches), HP is latency-first for at-risk requests.
- **Predictive SLO-risk model** that estimates per-request TTFT slack and triggers LP→HP migration before the deadline is missed, rather than reacting after violation.
- **Explicit drop mechanism** (Shepherd-inspired): when transient load exceeds capacity, requests that have already blown their TTFT budget while queued are dropped, freeing capacity for still-servable requests. This bounds tail damage under bursts.
- **Joint TTFT + TBT optimization**: unlike prefill/decode disaggregation work (DistServe, Llumnix) that assumes fast cross-instance KV transfer, Ascendra operates without high-bandwidth interconnect assumptions.
- **Goodput-centric evaluation** rather than raw throughput, tying performance directly to SLO attainment.

## Baselines

- **vLLM** (continuous batching baseline).
- **Sarathi-Serve** (chunked-prefill baseline, strong on TBT).
- Authors explicitly **exclude DistServe and Llumnix** from head-to-head comparison, citing their dependence on high-bandwidth interconnect for KV migration.
- No explicit FCFS-only or admission-control baseline (e.g., Llumnix's queue management, or a classical AC gate) — a gap for the survey to flag.

## Evaluation setup

- **Models**: Mistral-7B, LLaMA-3.1-8B, Qwen-14B.
- **Hardware**: 3x NVIDIA A100 80GB, 100 Gbps Infiniband/Ethernet.
- **Workloads**: Openchat-ShareGPT4 (chat), LongBench (document summarization) — mixes short-context chat with long-context summarization to stress both TTFT and TBT.
- **Arrival**: Poisson with varying arrival rate to sweep load levels including overload.
- **Metrics**: goodput (SLO-satisfying requests per second), TTFT SLO attainment, TBT SLO attainment, request drop rate.

## Claimed numbers

- Up to **1.7x goodput** vs vLLM and Sarathi-Serve while meeting both TTFT and TBT SLOs.
- **1.74x more requests served under SLO** vs baselines under heavy load.
- **~19.1% goodput improvement** over vLLM for Mistral-7B on ShareGPT.
- Maintains higher SLO attainment across load-sweep range; baselines collapse earlier under overload.

## Fidelity

- Real system, real GPUs (3x A100 80GB), real open-source models — not simulator-only. This is a strong-fidelity data point.
- Small cluster scale (3 GPUs) limits claims about datacenter-scale routing; results may not extrapolate to 100+ instance deployments where LP/HP partitioning ratios become a live tuning problem.
- Poisson arrivals are synthetic; no production-trace replay reported. Bursty/heavy-tailed real traces (Azure LLM Inference Trace) would stress the drop mechanism harder.
- No ablation isolating the drop mechanism's contribution vs the LP→HP migration — hard to attribute how much of the 1.7x comes from dropping vs prioritization.

## Relevance to survey

Fits **cluster 5.1 (request-level admission)** as a rare example of a modern LLM serving system that treats **request dropping as a first-class, explicit action** rather than an implicit consequence of timeout, backpressure, or client disconnect. Most contemporaneous work (vLLM, Sarathi-Serve, DistServe, Llumnix) never drops — they queue indefinitely or rely on client-side timeouts. Ascendra's Shepherd-lineage explicit drop is a useful counterpoint and a citation anchor for the "admission-primary vs scheduling-primary" axis. Also relevant to **§5.6 (priority scheduling)** for the two-tier LP/HP design.

## Open questions surfaced

- **Drop policy is reactive, not predictive.** Requests are dropped only *after* their TTFT deadline is already blown in queue. Why not drop at admission time when the SLO-risk model already predicts violation is unavoidable? A predictive-drop variant would save even the wasted prefill on the eventually-doomed request.
- **No fairness / starvation analysis for dropped requests.** Are long-prompt requests systematically dropped more often (since their queued TTFT budget burns faster relative to expected prefill cost)? This would be a fairness bug.
- **LP/HP capacity split is static in the eval.** How should the LP:HP ratio adapt online to workload mix (chat-heavy vs summarization-heavy)? Not addressed.
- **Interaction with retries.** If a client retries a dropped request, does it re-enter LP or bypass to HP? Not specified — but this matters for end-to-end user-visible latency, which is the actual SLO the operator cares about.
- **No comparison to a pure admission-control baseline** (e.g., token-bucket AC + FCFS). Without this, we cannot isolate whether Ascendra's win comes from smart admission or smart scheduling.
- **NEW open problem for the survey**: *predictive drop-at-admission using the same SLO-risk model that drives LP→HP promotion* — Ascendra has all the machinery in place but only uses the predictor for promotion, not for gating. This is a natural next step and, to our knowledge, not yet studied in the LLM serving literature.
