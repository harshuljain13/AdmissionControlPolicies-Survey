# Chronos

**Full title**: Formal schedulability analysis for LLM inference: TTFT and TBT deadline guarantees via response-time theory
**Authors**: Amine Marref (Univ. Saïda – Dr. Moulay Tahar, Algeria; corresponding), Khaled Tarmissi (Prince Sultan Univ., Riyadh, KSA), Hassene Chaibi (Univ. Saïda – Dr. Moulay Tahar, Algeria)
**Venue**: **Frontiers in Computer Science**, Volume 8, June 29, 2026 (peer-reviewed; edited by Yi Dong; reviewed by Sabina Rossi + Boxuan Wang)
**Links**: [Frontiers DOI 10.3389/fcomp.2026.1873627](https://www.frontiersin.org/journals/computer-science/articles/10.3389/fcomp.2026.1873627/full)
**Code**: **Yes** — [github.com/am-research/rtss-ttft-tbt](https://github.com/am-research/rtss-ttft-tbt) (simulator)
**Fetched**: 2026-09-10

## Abstract
Applies classical real-time-systems response-time theory to LLM inference. Provides schedulability condition + admission test + WCRT bound for TTFT and TBT. Sporadic-task model: prefill = sporadic job with TTFT deadline; decode = task with TBT-bounded iterations.

## Taxonomy placement
- Unit of admission: **request**
- Setting: **online serving**
- SLO-awareness: **deadline-aware** (TTFT + TBT)
- Signal used: WCRT bound + deadline slack

## Contribution (deep-read summary — Days 2-6)
- **Sporadic-task formalization of LLM inference.** Each request rᵢ becomes a prefill *job* with WCET Cpre,i = pᵢ·(αB + γ) where pᵢ = ⌈ℓᵢ/B⌉ chunks, released at arrival aᵢ with absolute deadline aᵢ + DTTFT. On completion it spawns a *decode task* modeled as an infinite-horizon recurrent task under continuous batching, WCET per iteration βn_D + γ, per-iteration bound = TBT SLO sᵢ. Job count nᵢ is bounded at admission by Nmax.
- **Closed-form WCRT bound (Theorem 1).** Derived via a 4-step busy-period argument: (i) identify longest continuously-non-empty prefill busy period, (ii) upper-bound interfering work from arrivals in that window using worst-case chunk count, (iii) apply work-balance inequality on GPU work = backlog + initiating chunk, (iv) sum interference and own service. Result: WCRT ≤ ρP·DTTFT / (1 − ρP) + pᵢ·(αB + γ), valid iff prefill utilization ρP < 1.
- **Admission test (Algorithm 1)** runs on each arrival: (a) reject if ρP ≥ 1, (b) reject if Theorem-1 WCRT exceeds DTTFT, (c) reject if TBT capacity check n*_D(n_act + 1) ≤ s is violated. Uses a 60-second sliding-window λmax estimator for arrival rate.
- **TBT capacity theorem (Theorem 3).** Bounds maximum concurrent decode tasks; e.g. n*_D ≈ 731 at s = 200 ms on the modeled A100.
- **Bridge contribution.** First paper to port real-time schedulability theory (Liu-Layland lineage) onto the prefill/decode split — provides *guarantees*, not just empirical SLO tracking. Load-bearing for our Open Problem 8.

## Baselines
- **FCFS** — arrival-order scheduling; no admission control; represents the vanilla vLLM baseline.
- **EDF** — earliest TTFT deadline first; classic real-time policy without a formal capacity bound (no admission test).
- **SLAI** (SLO-Aware LLM Inference) — empirical TBT-deadline tracking plus prefill reordering by *estimated* output length; represents the "learned/heuristic SLO-aware" family.
- **AC-FCFS** — token-bucket rate limiter matched to Chronos' throughput, then FCFS service; isolates the value of formal per-request feasibility testing vs. plain rate-limiting at the same admission volume.

## Evaluation setup
- **Model**: 7B-parameter dense model (single-node) on an NVIDIA A100 80 GB, fp16, 2 TB/s HBM bandwidth. Roofline-derived kernel parameters α=0.080 ms/token (prefill), β=0.250 ms/token (decode), γ=7.0 ms (fixed overhead).
- **Engine**: custom discrete-event Python simulator (Python 3.10+, CPU-only, ~2 min runtime on a laptop). *Not* vLLM/SGLang; hardware parameters are roofline-derived, not measured on real silicon.
- **Workload**: Azure LLM inference traces, 1 week May 2024, CC-BY. Code-completion service: 16.8M requests, 27.8 RPS mean / 98.1 RPS peak. Conversational service: 27.3M requests, 45.1 RPS mean / 85.2 RPS peak. Each experiment replays 50,000 uniformly sub-sampled requests (seed=42).
- **SLOs**: DTTFT = 2,000 ms; TBT = 200 ms (i.e. 10 tokens/sec streaming); TBT stress test also at 50 ms.
- **Metrics**: TTFT miss rate, TBT miss rate, admission rate, P99 TTFT, throughput.

## Claimed headline numbers
- **5× nominal load, Conversational trace**:
  - Chronos: 0.00% TTFT miss / 0.00% TBT miss, 88.9% admitted, P99 TTFT = 161 ms.
  - FCFS/EDF: 0.00% miss but 100% admitted with P99 TTFT = 400 ms.
  - SLAI: 0.03% TTFT miss, 100% admitted, P99 TTFT = 548 ms.
  - AC-FCFS (throughput-matched to Chronos): 6.80% TTFT miss, 88.9% admitted, P99 TTFT = 4,127 ms — shows rate-limiting alone is insufficient.
- **10× nominal load**:
  - Chronos: 0.00% / 0.00% miss, 53.9% admitted, P99 TTFT = 111 ms.
  - FCFS/EDF: **99.44% TTFT miss** (collapse).
  - SLAI: 22.55% TTFT miss.
  - AC-FCFS: 15.40% TTFT miss at the same 53.9% admission — again, formal test dominates rate matching.
- **Tight TBT (s = 50 ms) at 5× load**: Chronos 0.0% TBT violations vs. 29.8–41.3% for the uncontrolled schedulers.

## Fidelity / reproducibility
- Code: **available**, discrete-event simulator only. Implements all four schedulers (FCFS, EDF, SLAI, Chronos). CPU-only, no GPU required. Ships scripts for hardware-parameter fitting (Table 2), trace characterization (Table 1, Figure 1), and full scheduler comparison (Tables 3–4). Outputs LaTeX tables, JSON results, five PDF figures. Fixed seed=42.
- **No integration with vLLM/SGLang.** README notes real-vLLM measurements *could* replace the roofline-derived α/β/γ but the artifact does not do so.
- Trace download via `curl` from public Azure release; both 2024 weekly (~1.1 GB + ~700 MB) and 2023 samples supported.
- Second-strongest reproducibility position in the cluster (after QLM): everything is deterministic and laptop-runnable, but nothing is validated on a real serving engine.

## Relevance to survey
Anchor for the formal-real-time cluster within §5.1. The only paper that gives a formal schedulability condition — bridge between systems and real-time-theory communities. Load-bearing for Open Problem 8 (formal schedulability with LLM-specific WCRT). AC-FCFS baseline is a clean lever for arguing that per-request feasibility tests beat throughput-matched rate limiting.

## Open questions surfaced
- **Simulator↔silicon gap.** α/β/γ are roofline-derived; the authors flag that real-A100 validation is future work. Any deployed system will see non-linear effects (tensor-core boundaries, KV-cache fragmentation, prefill chunk-boundary stalls) that the linear τ = αn_P + βn_D + γ model doesn't capture.
- **Single-node, single-GPU only.** Disaggregated prefill/decode (à la DistServe, Splitwise) and multi-GPU/multi-node schedulability are open — inter-node KV-cache transfer latency has no formal treatment yet.
- **Long-context regime.** Beyond a crossover output length the workload becomes compute-bound, breaking the memory-bandwidth-dominance assumption; piecewise-linear extension needed.
- **Deterministic WCET conservatism.** Probabilistic WCET / stochastic response-time analysis could tighten bounds and raise admission rate.
- **Mixed criticality.** All requests share one SLO class; heterogeneous per-tenant SLOs are unmodeled.
- **Output-length prediction dependency.** Nmax is set at admission from a length estimate; robustness to mis-prediction is not characterized.
- **NEW open problem (mine).** The AC-FCFS comparison is the paper's cleanest ablation and it is done *inside the same simulator* with the same α/β/γ. On a real engine, a token-bucket at matched throughput may behave very differently (queueing at the KV-cache admission point, not just at the request queue). A real-engine reproduction is the obvious next study.
