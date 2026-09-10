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
TBD

## Baselines
"Commonly used strategies in practice" (unspecified)

## Evaluation setup
- Model(s): TBD
- Engine: TBD
- Workload: TBD
- Metrics: token throughput, request throughput, average latency, tail latency, KV utilization stability

## Claimed headline numbers
TBD — no specific x-fold in abstract

## Fidelity / reproducibility
- Code: TBD
- Notes: rate-control mechanisms are standard queueing theory — should be reproducible from paper alone if stability proofs are clean

## Relevance to survey
Cluster 5.4 (queueing theory). Represents the "provable stability" branch — different from empirical AIMD (CONCUR) or fluid-threshold (Fluid-WAIT). Sits alongside Service-Induced Congestion as a formal admission-control paper.

## Open questions surfaced
TBD deep read
