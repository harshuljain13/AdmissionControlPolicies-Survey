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
- **Three-stage lifecycle observation.** Traces of agentic batch inference decompose into (i) *warmup* — low context, ~90% prefix-cache hit rate, throughput climbs monotonically; (ii) *middle-phase thrashing* — sustained low hit rate as the system enters an eviction/recomputation cycle, which dominates >90% of end-to-end execution time; (iii) *cooldown* — agents finish, KV pressure drops, hit rate recovers. The failure mode is cumulative KV pressure across long-horizon agent sessions, not per-request memory blowup — this is why request-level admission misses it.
- **Cache-pressure signal (dual gate).** The controller reads two runtime metrics: `U_t` (KV cache utilization, fraction of GPU KV memory occupied) and `H_t` (prefix-cache hit rate over the current window). Congestion is declared only when *both* `U_t > U_high` AND `H_t < H_thresh` — utilization alone is not enough because high U with high hit rate is healthy reuse, not thrashing.
- **AIMD concurrency window at the agent-session granularity.** A TCP-Reno-style controller adapts the number of *concurrently admitted agent sessions* (not requests). Additive-increase probes for extra capacity by `α = 2` sessions per interval when the system is uncongested; multiplicative-decrease pauses/defers sessions by factor `β = 0.5` when the dual-gate fires. Fixed thresholds `U_low = 0.2`, `U_high = 0.5`, `H_thresh = 0.2` are used across all experiments.
- **Proactive admission, not reactive eviction.** Unlike LRU/HiCache which react after KV is already thrashing, CONCUR holds back agent sessions at admission so the working set of active sessions fits the cache — trading a small queueing delay for large throughput gain by keeping hit rate high.
- **Positioning vs Continuum (rebuttal).** Continuum uses SLO-driven request-level control; CONCUR argues the correct control loop for offline agentic batch is *agent-session-level* congestion, because per-request signals fire too late in a multi-turn agent trajectory.

## Baselines
- **SGLang (default)** — request-level scheduling with LRU KV-cache eviction; no admission control.
- **SGLang + request-level admission control** — the "obvious" ablation: same admission idea applied at request granularity instead of session granularity.
- **SGLang + HiCache** — CPU-offloaded KV cache (reactive: expands capacity instead of gating admission).
- **Continuum** (added in rebuttal, arXiv:2511.02230) — SLO-aware request-level scheduler; strongest concurrent baseline on Qwen3-32B / DeepSeek-V3.

## Evaluation setup
- **Models:** Qwen3-32B, DeepSeek-V3.
- **Engine:** SGLang (CONCUR is implemented as a controller on top; comparisons include SGLang+HiCache).
- **Hardware:** NVIDIA H100 80GB with NVLink.
- **Configurations swept:** batch (concurrent sessions) 16–256, TP 2–16, GPUs 2–16. Headline configs: Qwen3-32B at 256 sessions / TP=8 / 8×H100; DeepSeek-V3 at 40 sessions / TP=16 / 16×H100.
- **Workload:** BrowserComp — long-horizon multi-turn web-agent tasks (sustained cumulative KV pressure, not bursty).
- **Metrics:** aggregate batch execution time / throughput; GPU SM utilization; prefix-cache hit rate over time.

## Claimed headline numbers
- Qwen3-32B, 256 sessions / TP=8 / 8×H100: **4.09× vs SGLang**; **1.69× vs Continuum** (rebuttal table).
- DeepSeek-V3, 40 sessions / TP=16 / 16×H100: **1.90× vs SGLang**.
- GPU SM utilization sustained at **66–70%** under load (vs baselines that collapse into thrash).
- Hyperparameter robustness: perturbing α, β yields <3% throughput swing (per rebuttal), supporting the "fixed constants across models" claim.

## Fidelity / reproducibility
- **Code:** not released as of fetch date (arXiv HTML mentions no repo; OpenReview thread does not list one). Internal name is PACE.
- **Hyperparameters fully disclosed:** α=2, β=0.5, U_low=0.2, U_high=0.5, H_thresh=0.2 — no per-model tuning claimed.
- **Reproducibility blockers:** BrowserComp harness setup is non-trivial; DeepSeek-V3 config requires 16×H100 (out of reach for most academic labs); SGLang version + HiCache commit not pinned in the arXiv version.

## Relevance to survey
Anchor paper for the agent-level cluster (5.2). Load-bearing for Open Problem 1 (request-level vs agent-level) and Open Problem 2 (online serving admission — CONCUR's explicit non-goal).

## Open questions surfaced (from public OpenReview thread)
- Reviewer Afcg: can request-level scheduling address the same problem? (unanswered)
- Meta-review: online serving is out of scope; fairness deferred
- Reviewer DhUu: starvation and GPU underutilization risks

## Open questions surfaced (from paper's own text)
- **U_low calibration.** Appendix A.1 concedes that unlike α, β, U_high, H_thresh (which the ablation shows are robust), `U_low` — the threshold for additive-increase probing — needs more careful calibration per workload. The paper does not characterize how to set it for workloads with different context-length distributions.
- **Signal is aggregate, not per-session.** `U_t` and `H_t` are cluster-wide averages. The paper does not address whether a small number of long-tail agent sessions can poison the hit-rate signal and cause the controller to under-admit healthy sessions.
- **No cost model for AIMD interval.** The control interval is fixed; the paper does not discuss how interval length interacts with agent turn latency (a full multiplicative-decrease can arrive after many turns of damage are already done).
- **Fixed constants across radically different model sizes.** The claim that (α=2, β=0.5) works for both Qwen3-32B and DeepSeek-V3 with unchanged thresholds is stated but not stress-tested on smaller (7B) or MoE-heavy regimes where KV footprint per session differs by an order of magnitude.
