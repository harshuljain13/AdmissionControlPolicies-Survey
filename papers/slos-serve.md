# SLOs-Serve

**Full title**: SLOs-Serve: Optimized Serving of Multi-SLO LLMs
**Authors**: Siyuan Chen, Zhipeng Jia, Samira Khan, Arvind Krishnamurthy, Phillip B. Gibbons
**Venue**: arXiv preprint, submitted Apr 5, 2025 — venue TBD (check for updates)
**Links**: arXiv:2504.08784
**Code**: TBD (no repo mentioned in abstract)
**Fetched**: 2026-09-10

## Abstract
Multi-stage LLM requests with application- and stage-specific SLOs. Multi-SLO dynamic-programming-based algorithm optimizes token allocations under SLO constraints, exploring chunked prefill + optional speculative decoding. Multi-replica serving + dynamic routing + bursty arrivals. 2.2× per-GPU serving capacity vs prior.

## Taxonomy placement
- Unit of admission: **request** (with soft admission control per abstract)
- Setting: **online serving**
- SLO-awareness: **multi-SLO deadline-aware**
- Signal used: token-allocation DP + SLO constraint

## Contribution (deep-read summary — Days 2-6)
TBD

## Baselines
"Prior state-of-the-art systems" — identify from paper (Llumnix, DynamoLLM, ExeGPT, VTC per prior context)

## Evaluation setup
- Model(s): TBD
- Engine: TBD
- Workload: 6 application scenarios (summarization, coding, chatbot, tool calling, reasoning) + first comparison on tool-based + reasoning LLMs
- Metrics: SLO attainment, per-GPU serving capacity

## Claimed headline numbers
2.2× per-GPU serving capacity on average

## Fidelity / reproducibility
- Code: TBD
- Notes: multi-stage SLO framing is novel; reproduction depends on chunked prefill + spec decoding integration

## Relevance to survey
Request-level SLO cluster (5.1). Notable for multi-stage SLOs (each stage of a multi-turn app has its own SLO) — this is a design point most single-SLO admission policies miss.

## Open questions surfaced
TBD deep read
