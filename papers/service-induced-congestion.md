# Service-Induced Congestion

**Full title**: Service-Induced Congestion in Memory-Constrained LLM Serving
**Authors**: Ruicheng Ao, Jing Dong, Gan Luo, David Simchi-Levi
**Venue**: arXiv preprint (math.OC) — venue TBD
**Links**: arXiv:2606.15555
**Code**: **No**
**Fetched**: 2026-09-10

## Abstract
Discrete-time dynamical model of GPU-memory-constrained LLM serving. Key insight: the service process itself creates future capacity pressure as KV caches grow during token generation. Analyzes admission + memory dynamics + eviction under continuous batching. Homogeneous workloads converge to limit cycles with throughput losses up to 50%. Heterogeneous workloads have stability criteria — workload heterogeneity desynchronizes completions and stabilizes performance.

## Taxonomy placement
- Unit of admission: **request**
- Setting: theoretical (both online + batch modeled)
- SLO-awareness: throughput-oriented (stability)
- Signal used: dynamical-system analysis — service completion timing

## Contribution (deep-read summary — Days 2-6)
TBD

## Baselines
None (theoretical dynamical model, no empirical eval per abstract)

## Evaluation setup
- Model(s): theoretical
- Metrics: limit cycle throughput loss (up to 50%); stability criteria

## Claimed headline numbers
Up to 50% throughput loss under homogeneous myopic admission; heterogeneity stabilizes

## Fidelity / reproducibility
- Code: none needed (theoretical)
- Notes: the "50% throughput loss under myopic admission" is a citable data point for the survey's motivation

## Relevance to survey
Cluster 5.4 (queueing theory / algorithmic). Provides the theoretical justification for why admission control matters at all — "service creates its own congestion." Load-bearing citation for Section 2 Background (Little's Law + service dynamics).

## Open questions surfaced
TBD deep read
