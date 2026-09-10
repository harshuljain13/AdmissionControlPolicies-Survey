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
TBD

## Baselines
**Sarathi** (stall-free batching)

## Evaluation setup
- Model(s): TBD (realistic traces)
- Engine: TBD
- Workload: realistic traces
- Metrics: tail latency, single-node capacity, cluster-level capacity

## Claimed headline numbers
2.29× tail latency reduction; 20% single-node; 54.3% cluster-level

## Fidelity / reproducibility
- Code: **not released**
- Notes: deep scheduler rewrite (modifies batch formation in engine); per Feasibility Audit this is ~800-1200 LoC to re-implement in vLLM. Adaptive batch capacity requires calibration.

## Relevance to survey
Cluster 5.3 (fairness). Notable — fairness *between task types* (prefill vs decode), not between tenants. Different fairness axis from VTC (across users). Deserves its own subsection.

## Open questions surfaced
TBD deep read
