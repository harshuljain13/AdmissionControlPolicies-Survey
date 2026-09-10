# ProServe

**Full title**: ProServe: Unified Multi-Priority Request Scheduling for LLM Serving
**Authors**: Weizhe Huang, Tao Peng, Tongxuan Liu, Donghe Jin, Kang Meng, Xianzhe Dong, Ke Zhang
**Venue**: arXiv preprint (cs.DC) — venue TBD
**Links**: arXiv:2512.12928
**Code**: TBD
**Fetched**: 2026-09-10

## Abstract
Scheduling for LLM serving handling thousands of concurrent requests with varying SLO requirements and client priorities. Formalizes as "service gain maximization" problem (satisfying different-priority latencies contributes varying gain). Two-tier: SlideBatching (engine-layer dynamic batch formation) + GoRouting (service-layer gain-oriented dispatching). Up to 35% system gain, 52% SLO attainment improvement.

## Taxonomy placement
- Unit of admission: **request** (with priority classes)
- Setting: **online serving**
- SLO-awareness: **priority + deadline**
- Signal used: composite gain function + priority class + SLO

## Contribution (deep-read summary — Days 2-6)
- **Formalizes multi-priority LLM scheduling as service-gain maximization** with a Token-level Deadline-aware Gain (TDG) function: `f_TDG(r) = Σ_i w_r(i) · I[t_{r,i} < deadline_{r,i}]` where `deadline_{r,i} = TTFT_SLO + (i-1)·TPOT_SLO` and per-token weight combines a priority weight `w_{p(r)}` with a first-token vs decode-token weight (`w_p`, `w_d`). Prove the problem NP-hard even single-instance, motivating heuristics.
- **SlideBatching (engine tier):** hybrid ordering with a *sliding* Urgent/Normal boundary. A request is Urgent iff `remaining_time < γ·ϕ(Q)` where `ϕ(Q)` estimates queue completion; Urgent requests are sorted by *density* (priority-weighted gain / execution time, descending), Normal by *earliest deadline first*. Batch time budget is `min(smallest remaining deadline, η)`. Under high load the boundary "slides" so density-first dominates (concentrates gain on high-value work); under low load EDF dominates.
- **GoRouting (service tier):** gain-oriented, capability-aware dispatch across prefill instances. For each candidate `p`, estimate marginal gain `Δ_p = gain(queue ∪ r) − gain(queue)`; keep only instances with `Δ_p ≥ α·max(Δ)`. Partition remaining candidates by load: light (`exec_time < μ·TTFT_SLO`) → most-idle; heavy (`> λ·TTFT_SLO`) → fallback load-balance; middle → pick *heaviest* to intentionally reserve light instances for future high-priority or long requests.
- **Unified two-tier design** — engine batching and service routing driven by the *same* TDG objective, closing the loop that prior work leaves open (batching-only or routing-only priority handling).
- **Deploys inside JD.com's xLLM engine** on Ascend 910B NPUs; validated on a real industrial trace with actual client priority labels.

## Baselines
- **vLLM-FCFS** — default vLLM: prefill-priority + FCFS.
- **Weighted VTC** — token-based proportional fairness weighted by priority.
- **Sarathi-FCFS** — chunked prefill + decode-first FCFS.
- **Sarathi-Priority** — decode-first + priority-ordered + FCFS fallback.
- **FairBatching** — EDF variant: decode-urgency > prefill > remaining-decode.
- **MinLoad** — least-loaded-instance dispatch (service-tier / global baseline).

## Evaluation setup
- **Models**: Qwen2-7B and Qwen3-32B.
- **Engine**: xLLM (JD.com's inference framework) — *not* vLLM/SGLang; SlideBatching and GoRouting are integrated inside it.
- **Hardware**: Ascend 910B NPUs (16 per server), 96 CPU cores, 2 TB RAM. PD co-location (single-node) and PD disaggregation (multi-node) settings.
- **Workload**: 4 open datasets — ShareGPT, Azure (LLM inference trace), BurstGPT, QwenTrace — plus 1 industrial trace from JD.com with real client priority labels.
- **Metrics**: TDG_Ratio (captured / ideal gain) and SLO attainment (TTFT and TPOT jointly).

## Claimed headline numbers
- **Up to 35% system gain**: single-node PD co-location, Qwen3-32B, high-load; SlideBatching vs vLLM-FCFS (adaptive urgency partition + block mgmt).
- **Up to 52% SLO attainment**: multi-node PD disaggregation, Azure trace, high request rate; GoRouting vs MinLoad (gain-oriented capacity reservation for future high-priority/long requests).
- Improvements are *not uniform* across settings (Figs 12–19); light-load regimes show much smaller deltas because EDF-only baselines are already near-optimal.

## Fidelity / reproducibility
- **Code**: no public release identified; implementation lives in xLLM (referenced but repository not linked in paper).
- **Hardware barrier**: Ascend 910B NPUs limit external replication; xLLM engine internals are proprietary. Reported numbers are engine-specific and may not transfer cleanly to vLLM/SGLang.
- **Trace**: industrial dataset is proprietary; only 4 open datasets are reproducible, and priority labels on those must be synthesized.
- **Hyperparameters** `γ, α, μ, λ, η, w_p, w_d` are introduced but sensitivity is only partially reported.

## Relevance to survey
Two-tier *scheduling-primary* paper: admission is implicit (no explicit reject/defer action — heavy-load requests still dispatch, just to intentionally-loaded instances). The core lever is *ordering and dispatch under a shared gain objective*, not gating. Belongs in **§5.6 (multi-tier scheduling with priority)** rather than §5.1 (request-level SLO admission). Keep referenced from §5.1 as an example of priority-weighted deadline objectives that admission controllers could adopt as their utility function.

## Open questions surfaced
- **Starvation of low-priority classes** under sustained high load: density-first ordering plus GoRouting's "reserve for high-priority" bias could indefinitely defer low-priority requests. Paper does not report tail latency or completion rate for the lowest priority class.
- **Sensitivity to the priority-weight vector `w_{p(r)}`**: how much of the 35%/52% gain is an artifact of a favorable weight assignment vs the algorithm itself?
- **Interaction with preemption**: SlideBatching reorders queued requests but the paper is silent on whether an in-flight low-priority decode can be preempted when an Urgent arrival lands.
- **Portability off xLLM/Ascend**: does the density heuristic hold when block-manager and scheduler internals differ (e.g., vLLM's continuous batching with paged attention)?
- **NEW**: The gain objective `f_TDG` is *token-indexed with per-token indicators* — this is effectively a per-token admission decision made implicitly by scheduling. Formalizing that connection could bridge ProServe-style utility functions with classical admission-control literature (a survey angle worth calling out in §5.6 → §5.1 cross-reference).
