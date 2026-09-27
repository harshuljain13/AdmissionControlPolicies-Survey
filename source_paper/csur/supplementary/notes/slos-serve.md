# SLOs-Serve

**Full title**: SLOs-Serve: Optimized Serving of Multi-SLO LLMs
**Authors**: Siyuan Chen, Zhipeng Jia, Samira Khan, Arvind Krishnamurthy, Phillip B. Gibbons
**Venue**: arXiv preprint (2504.08784), submitted Apr 5, 2025. Still listed as "Preprint" on lead author's page as of 2026-09-10 — no MLSys/OSDI/NSDI acceptance yet found.
**Links**: arXiv:2504.08784
**Code**: No public repo linked in paper. Implementation described as ~10K LoC Python (orchestration) + ~1.5K LoC C++ (resource-planning algorithm), built on top of vLLM backend.
**Fetched**: 2026-09-10

## Abstract
Multi-stage LLM requests with application- and stage-specific SLOs. Multi-SLO dynamic-programming-based algorithm optimizes token allocations under SLO constraints, exploring chunked prefill + optional speculative decoding. Multi-replica serving + dynamic routing + bursty arrivals. 2.2× per-GPU serving capacity vs prior.

## Taxonomy placement
- Unit of admission: **request** (with soft admission control per abstract)
- Setting: **online serving**
- SLO-awareness: **multi-SLO deadline-aware**
- Signal used: token-allocation DP + SLO constraint

## Contribution (deep-read summary — Days 2-6)
- **Multi-SLO DP scheduler.** Formulates admission + token allocation as a constrained optimization: state `DP[i, m, pb, n]` = best value serving first `i` requests with `m` KV-memory units and `pb` prefill budget remaining. Admitted requests' cumulative token demand must never exceed the per-deadline token budget. Complexity `O(N · N_new^(L+1) · M)`; authors report <10 ms scheduling overhead per invocation.
- **Soft admission control.** Scheduler runs periodically (on timeouts / threshold crossings), picks a subset of requests whose SLOs are jointly attainable, and *guarantees* those SLOs while declining or rerouting the rest. Avoids the cascading-failure mode of greedy per-stage prioritization where one late request drags an entire batch past SLO.
- **SLO-adaptive chunked prefill.** Algorithm 2 sizes each prefill chunk against the tightest TPOT SLO among currently-decoding requests, yielding variable batch sizes (>512 tokens ~25% of steps vs. Sarathi-Serve's fixed cap).
- **SLO-adaptive speculative decoding.** Per-TPOT-tier speculation length chosen via optimization (Appendix D), lengthened when a request has TPOT slack and shortened when it is falling behind. Speculation is optional, not always-on.
- **Multi-replica routing.** Sequential replica-by-replica admission across replicas; declined requests can flow to the next replica. Authors flag this as "one of many" possible routing rules.

## Baselines
Directly evaluated against: **vLLM** (greedy, prefill-biased), **Sarathi-Serve** (chunked prefill with fixed chunk sizing), **DistServe** (prefill/decode disaggregation with static device split). Llumnix, DynamoLLM, ExeGPT, and VTC are cited in related work but not run as head-to-head baselines.

## Evaluation setup
- **Models**: OPT-7B / 13B / 30B, ToolLlama-7B, DeepSeek-R1-Distill-Qwen-1.5B.
- **Engine**: Custom scheduler on top of vLLM (chunked prefill + optional spec decode integrated).
- **Hardware**: GCP `a2-highgpu-4g` (4× A100-40GB, NVLink) for main results; `a3-highgpu-8g` (8× H100-80GB) for scaling.
- **Workloads — 6 scenarios**: ChatBot (stable, decode-heavy), Coder (bursty, short outputs), Summarizer (prefill-heavy), Mixed (union of the three), ToolLLM (multi-turn tool loops), Reasoning (long thinking + decode). ToolLLM and Reasoning are highlighted as first-of-kind benchmarks for multi-stage SLOs.
- **Metrics**: per-GPU *serving capacity* = max sustained request rate at ≥90% SLO attainment; SLO attainment rate; scheduling overhead.

## Claimed headline numbers
- **2.2× per-GPU serving capacity on average** (geo-mean across scenarios + models).
- Per-baseline: **1.76× over vLLM, 1.94× over Sarathi-Serve, 2.6× over DistServe** (geometric mean).
- Bursty regimes: **~2.1× (Coder), ~1.9× (ToolLLM)**.
- Multi-replica scaling: **6.2× capacity at 4 replicas vs. 1 replica** (super-linear from admission pooling).

## Fidelity / reproducibility
- **Code**: not open-sourced at time of reading. LoC counts published but no artifact link.
- **Reproduction risk**: performance model needs per-GPU-family profiling (A100 vs. H100 coefficients differ); requires prior knowledge / estimator of decode length; spec-decode benefits depend on draft-model availability. Chunked-prefill + spec-decode integration on top of vLLM is non-trivial but plausible for a determined reimplementer.

## Relevance to survey
Request-level SLO cluster (5.1). Notable for multi-stage SLOs (each stage of a multi-turn app has its own SLO) — this is a design point most single-SLO admission policies miss.

## Open questions surfaced
- Decode-length prediction is assumed as input; how sensitive is the DP to mis-estimation? Paper does not run a robustness ablation.
- Sequential multi-replica routing is admitted to be a simple heuristic; global joint scheduling across replicas is open.
- No fairness / starvation analysis: which requests get systematically declined under overload?
- Spec-decode integration assumes a draft model exists per target — cost/quality of the draft is out of scope.
- Performance model is GPU-family-specific and re-profiling is required for new hardware.
- Multi-tenant / multi-model co-serving on shared replicas is not evaluated.
