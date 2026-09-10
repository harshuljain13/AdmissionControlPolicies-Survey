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
TBD

## Baselines
"State-of-the-art baselines" — identify from paper

## Evaluation setup
- Model(s): TBD
- Engine: TBD
- Workload: 4 open-source datasets + 1 industrial dataset
- Metrics: system gain (proprietary), SLO attainment

## Claimed headline numbers
Up to 35% system gain, 52% SLO attainment improvement

## Fidelity / reproducibility
- Code: TBD
- Notes: two-tier design (batching + routing) is broader than pure admission; deep read needed to isolate admission contribution

## Relevance to survey
Cluster 5.1 (request-level SLO) with priority as a distinctive axis. Notable — combines batching and routing under a single gain function. May belong in 5.6 as scheduling with admission component rather than admission-primary.

## Open questions surfaced
TBD deep read
