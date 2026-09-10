# CONCUR / PACE

**Full title**: CONCUR: High-Throughput Agentic Batch Inference of LLM via Congestion-Based Concurrency Control
**Authors**: Qiaoling Chen, Zhisheng Ye, Tian Tang, Peng Sun, Boyu Tian, Guoteng Wang, Shenggui Li, Yonggang Wen, Zhenhua Han, Tianwei Zhang
**Venue**: **ICML 2026 (accept regular)** — poster + oral
**Links**: arXiv:2601.22705 · [ICML poster page](https://icml.cc/virtual/2026/poster/63743) · [OpenReview mmdqUrEY24](https://openreview.net/forum?id=mmdqUrEY24)
**Code**: Not verified (fetched abstract mentions no repo)
**Fetched**: 2026-09-10

## Abstract
Batch inference for agentic workloads stresses the GPU key-value cache in a sustained cumulative manner, causing severe throughput degradation before memory is exhausted — "middle-phase thrashing." Authors propose proactive agent-level admission control via AIMD-style feedback on cache pressure signals. Up to 4.09× throughput on Qwen3-32B, 1.90× on DeepSeek-V3.

## Taxonomy placement
- Unit of admission: **agent-session**
- Setting: **offline batch** (explicit, per meta-review)
- SLO-awareness: throughput-oriented (not deadline-aware)
- Signal used: KV cache utilization + hit rate

## Contribution (deep-read summary — Days 2-6)
TBD

## Baselines
SGLang (default) · HiCache · Continuum (added in rebuttal, arXiv:2511.02230)

## Evaluation setup
- Model(s): Qwen3-32B, DeepSeek-V3
- Engine: SGLang (+ HiCache), vLLM
- Workload: BrowserComp (long-horizon web agent tasks)
- Metrics: throughput (aggregate execution time), GPU SM utilization

## Claimed headline numbers
Qwen3-32B (256/8/8): 4.09× vs SGLang, vs Continuum 1.69× ratio. DeepSeek-V3 (40/16/16): 1.90× vs SGLang. GPU SM util 66-70% under load.

## Fidelity / reproducibility
- Code: not yet released (verify updated status)
- Hyperparameters: paper claims robustness (α, β vary → <3% throughput change per rebuttal)
- Notes: BrowserComp benchmark required; setup non-trivial

## Relevance to survey
Anchor paper for the agent-level cluster (5.2). Load-bearing for Open Problem 1 (request-level vs agent-level) and Open Problem 2 (online serving admission — CONCUR's explicit non-goal).

## Open questions surfaced (from public OpenReview thread)
- Reviewer Afcg: can request-level scheduling address the same problem? (unanswered)
- Meta-review: online serving is out of scope; fairness deferred
- Reviewer DhUu: starvation and GPU underutilization risks
