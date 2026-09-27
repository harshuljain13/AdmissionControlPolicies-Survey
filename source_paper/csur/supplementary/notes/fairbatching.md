# FairBatching

**Full title**: FairBatching: Fairness-Aware Batch Formation for LLM Inference
**Authors**: Hongtao Lyu, Boyue Liu, Mingyu Wu, Haibo Chen
**Venue**: arXiv preprint (cs.DC) — venue TBD
**Links**: arXiv:2510.14392
**Code**: **No** (no repo mentioned)
**Fetched**: 2026-09-10

## Abstract
Existing stall-free batching schedulers (Sarathi) create computational unfairness by excessively prioritizing decode tasks. FairBatching enforces fair resource allocation between prefill and decode via adaptive batch capacity determination + dynamic batch formation. Up to 2.29× tail latency reduction, 20% single-node capacity improvement, 54.3% cluster-level capacity improvement.

## Taxonomy placement
- Unit of admission: **request** (via batch formation)
- Setting: **online serving**
- SLO-awareness: **fairness-oriented** (between prefill and decode tasks — not tenant fairness)
- Signal used: current batch composition + prefill/decode fairness metric

## Contribution (deep-read summary — Days 2-6)
- **Reframes prefill-vs-decode as a fairness problem**: identifies that Sarathi's stall-free batching over-prioritizes decode, wasting decode slack while queuing prefill and hurting TTFT — root cause is non-monotonic TBT as a scheduling signal plus a rigid decode-first policy.
- **Adaptive batch capacity** replaces a static TokenBudget with a *time budget* per iteration: `init_time_budget = max(min_slack_i, min_tpot_slo_i)` (smallest decode slack or min TPOT SLO). Iteration runtime is modeled as `a + b·total_new_tokens + c·total_context` (KV-cache-aware), giving ±1.3% batch-time prediction vs. ±5.2% for token-only budgets.
- **Three-phase (three-group) packing** within the time budget: (1) *urgent decode* — decodes whose slack < init_time_budget + min_tpot_slo; (2) *TTFT-critical prefill* — new arrivals; (3) *non-urgent decode* — fills remaining slack. Each group internally sorted by slack ascending; greedy fill until capacity exhausts.
- **PAB-aware load balancing** (Prefill-Aware Balancing) extends the fairness signal to cluster level, driving the 54.3% cluster gain.
- **Effective RPS** as evaluation metric: RPS at which *both* TTFT and TPOT SLOs hold simultaneously — a stricter yardstick than either alone.

## Baselines
- **vLLM-vanilla** (prefill-prioritized default)
- **vLLM-sarathi** (decode-prioritized stall-free chunked-prefill with tuned TokenBudget)
- No comparison to DistServe or other prefill/decode-disaggregated systems.

## Evaluation setup
- **Models**: LLaMA3.1-8B, Qwen3-14B, Qwen3-32B, LLaMA3.3-70B
- **Hardware**: A800-80GB and H20-96GB (single- and multi-GPU configs)
- **Engine**: vLLM v0.10.1.1
- **Workloads**: BurstGPT, Qwen-Bailian Anonymous Dataset, Azure LLM Inference Trace 2024
- **SLOs**: TTFT 500–2000 ms; TPOT 50–200 ms
- **Metric**: Effective RPS (both SLOs met) + P99 TTFT

## Claimed headline numbers
- **2.29× P99 TTFT reduction** vs. vLLM-sarathi under tight SLOs on the traced workloads.
- **20.0% single-node effective-RPS gain** (geometric mean across the four models × traces).
- **54.3% cluster-level capacity gain** when combined with PAB-aware load balancing.
- Gains **diminish under relaxed SLOs** (TTFT ≥ 2 s, TPOT ≥ 200 ms) — sweet spot is latency-sensitive regimes.

## Fidelity / reproducibility
- **Code**: not released as of preprint (Oct 2025). Author IPADS page still lists arXiv only; no OSDI/SOSP/EuroSys acceptance yet.
- **Implementation cost**: 1,639 LoC of scheduler in Python, but only **90 LoC of invasive framework changes** to vLLM v0.10.1.1 — much lighter than the Feasibility-Audit estimate of 800–1200 LoC. Re-implementation is tractable.
- **Calibration**: linear runtime model (a, b, c) must be fit per model × hardware pair; paper notes manual `gc.freeze()` needed to suppress Python GC jitter that corrupts the runtime predictor.

## Relevance to survey
Cluster 5.3 (fairness). Notable — fairness *between task types* (prefill vs decode), not between tenants. Different fairness axis from VTC (across users). Deserves its own subsection.

## Open questions surfaced
- **Is "prefill-vs-decode fairness" really fairness, or just SLO-aware scheduling relabeled?** No principled fairness axiom (max-min, proportional share, envy-freeness) is proven; the "fairness" is operationalized as slack-balanced packing.
- **Interaction with disaggregated serving**: if prefill and decode run on different pools (DistServe/Splitwise), the whole premise dissolves. Paper does not address when co-located batching still wins.
- **Runtime-model portability**: linear `a + b·tokens + c·context` fit — does it survive speculative decoding, MoE routing, or long-context (>32k) regimes where attention is super-linear?
- **PAB-aware balancer details are thin** — how does it interact with replica-level KV cache locality (prefix caching)?
- **NEW open problem**: the time-budget formulation implicitly assumes decode SLOs are per-token (TPOT); it is unclear how it degrades under end-to-end deadline SLOs or streaming-perception SLOs (e.g., voice agents needing bounded inter-chunk gaps rather than per-token TPOT).
