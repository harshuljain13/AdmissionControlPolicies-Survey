# Flow-Controlled Scheduling

**Full title**: Flow-Controlled Scheduling for LLM Inference with Provable Stability Guarantees
**Authors**: Zhuolun Dong, Junyu Cao
**Venue**: arXiv preprint (cs.LG) — venue TBD
**Links**: arXiv:2604.11001
**Code**: TBD
**Fetched**: 2026-09-10

## Abstract
Flow-control framework regulating prompt admission rates. Derives necessary condition for stable operation + sufficient conditions for algorithm's stability. Reports improvements in token/request throughput, average + tail latency, and more stable KV cache utilization vs commonly used strategies.

## Taxonomy placement
- Unit of admission: **request** (rate-controlled)
- Setting: **online serving**
- SLO-awareness: stability + tail-latency
- Signal used: admission rate control loop

## Contribution (deep-read summary — Days 2-6)
- **Flow-control mechanism**: per-class *activation budget* b_k that caps how many waiting requests of type k the scheduler moves from the waiting queue Q into the active set P per time slot; selection within a class is FIFO. Token-bucket style with a static (offline-computed) budget rather than AIMD or reactive queue-length feedback — the "loop" is a per-slot admit-up-to-b_k gate, and correctness comes from choosing b_k > λ_k while keeping the aggregate KV footprint under memory M.
- **Necessary condition for stability (any algorithm)**: if Σ_k λ_k · (l^(k) o^(k) + ½(o^(k) + (o^(k))²)) > M then no scheduler can keep latency bounded — a workload-vs-KV-capacity inequality that gives a hard upper bound on admissible arrival rate (unknown-length version replaces the sum with an expectation over the decode-length distribution).
- **Algorithm 1 + Theorem 3.3 (known decode length)**: with b_k > λ_k and Σ_k b_k · (l^(k) o^(k) + ½(o^(k)+(o^(k))²)) < M, the system is stable (queue-length drift negative, latency bounded in expectation).
- **Algorithm 2 + Theorem 3.6 (unknown decode length)**: dynamic activation budget {B_t} with **LIFO eviction on KV overflow** (evict most-recently-activated to minimize wasted decode work); expected number of overflow events over horizon T is bounded by T·exp(−C(A,ε)·M²) whenever b·E[lo + ½(o+o²)] ≤ (1−ε)M — i.e. exponentially rare overflow under a slack condition.
- **Positioning**: closes the gap between the empirical "keep KV utilization moderate" folklore and a formal admission-control theorem, and cleanly separates the *feasibility frontier* (necessary condition, algorithm-agnostic) from *achievability* (sufficient condition for the specific budget-gated policy).

## Baselines
- **α-protection greedy** — grid-searched KV-headroom threshold (reserves α·M for in-flight growth)
- **MC benchmark** — FCFS with a future-memory feasibility check before admission
- **MC-SF** — memory-checked variant that prioritizes shorter predicted decode length (Jaillet et al. 2025)
- **Amin** — greedy activation assuming shortest-possible decode (Chen et al. 2025)
- **Hindsight optimal** — per-metric integer program with full future knowledge (upper bound, not a real policy)

## Evaluation setup
- Model(s): Llama2-70B (used to parameterize synthetic workloads); real-world runs use the workload trace, not a specific served model
- Engine: **discrete-time simulator** with continuous-time refinement via **Microsoft Vidur**; two-A100 target hardware profile
- Workload: synthetic (Poisson arrivals, horizons T ∈ {1000…10000}, known/unknown decode length regimes) and real-world **LMSYS-Chat-1M** (~210K prompts, 50K sampled, λ ∈ {10, 50} req/s)
- Metrics: token throughput, request throughput, average latency, 95th-percentile latency, KV cache utilization stability

## Claimed headline numbers
No explicit Δ% or x-fold numbers in the paper. Reported directionally: outperforms α-protection, MC, MC-SF, and Amin on token throughput, request throughput, mean latency, and p95 latency in the synthetic regime under both known and unknown decode length. On real-world LMSYS the gap narrows because longer decodes force a smaller feasible b_k, compressing the advantage over memory-checked FCFS variants.

## Fidelity / reproducibility
- Code: not linked in the paper
- Theory: fully specified (algorithms, assumptions A3.1/A3.4 on finite second moments and bounded l,o, Theorems 3.3 and 3.6) — reproducible on paper alone
- Empirical: simulator-only (Vidur), no real serving engine (no vLLM/SGLang/TGI numbers). Reproducing requires re-implementing the four baselines and the hindsight IP; workload trace is public (LMSYS-Chat-1M)
- Gap: no wall-clock numbers, no GPU-cost accounting, no KV-utilization variance number despite it being an abstract-level claim

## Relevance to survey
Cluster 5.4 (queueing theory). Represents the "provable stability" branch — different from empirical AIMD (CONCUR) or fluid-threshold (Fluid-WAIT). Sits alongside Service-Induced Congestion as a formal admission-control paper.

## Open questions surfaced
- Static per-class budget b_k assumes a **known type distribution and known decode-length moments per class** — how brittle is the stability guarantee under distribution shift (drift in prompt mix)? No online-learning variant of b_k is offered.
- LIFO eviction in Algorithm 2 wastes the *least* KV work but potentially the *most recent user's* tokens — the paper does not analyze fairness / starvation of newly arrived short requests.
- All results are simulator-based on Vidur; no end-to-end integration with a paged-attention runtime, so the interaction between flow control and continuous batching / chunked prefill is unexamined.
- The necessary condition treats prefill+decode uniformly under one forward pass — unclear how the bound tightens under disaggregated prefill/decode serving.
- No comparison against **preemption-based** policies (SRPT-style, LAPS, or the AIMD family) — only against FCFS-with-memory-check variants, which understates the competitive baseline.
