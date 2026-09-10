# Continuum

**Full title**: Continuum: Efficient and Robust Multi-Turn LLM Agent Scheduling with KV Cache Time-to-Live
**Authors**: Hanchen Li, Runyuan He, Qiuyang Mang, Qizheng Zhang, Huanzhi Mao, Xiaokun Chen, Hangrui Zhou, Huanchen Zhang, Alvin Cheung, Joseph Gonzalez, Ion Stoica (Berkeley / Tsinghua)
**Venue**: arXiv preprint (cs.OS) — venue TBD
**Links**: arXiv:2511.02230
**Code**: TBD (no repo in abstract)
**Fetched**: 2026-09-10

## Abstract
KV cache management for LLM inference on agentic workloads. Traditional systems evict cached KV when new requests arrive — inefficient for multi-turn agents that pause during tool execution. Proposes time-to-live mechanism for KV cache retention; selectively retains cache based on reload costs + queueing delays; auto-evicts when TTL expires. 8× average job completion time improvement + throughput gain.

## Taxonomy placement
- Unit of admission: **agent-session** (adjacent — this is more KV mgmt than admission)
- Setting: **online serving** (agent workloads)
- SLO-awareness: JCT-oriented, not deadline
- Signal used: KV cache reload cost + queueing delay estimate

## Contribution (deep-read summary — Days 2-6)
TBD

## Baselines
Not specified in abstract — check paper. Note: CONCUR treats Continuum as its primary SOTA baseline per ICML rebuttal.

## Evaluation setup
- Model(s): **Llama-3.1 (8B and 70B), Gemma-3 (12B), GLM-4.5 (355B)**
- Engine: TBD
- Workload: **SWE-Bench, BFCL (Berkeley Function Calling Leaderboard), OpenHand**
- Metrics: average job completion time, throughput

## Claimed headline numbers
8× average JCT improvement; throughput improvement

## Fidelity / reproducibility
- Code: TBD (check paper body)
- Notes: authoritative baseline for agent-level cluster (CONCUR's designated comparison target)

## Relevance to survey
Agent-level cluster (5.2). Complement to CONCUR: Continuum optimizes KV *after* admission (TTL), CONCUR gates admission *before* KV pressure. Their relationship is layered per CONCUR's rebuttal.

## Open questions surfaced
TBD deep read
