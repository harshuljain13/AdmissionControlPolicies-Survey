# PASCAL: A Phase-Aware Scheduling Algorithm for Serving Reasoning-based Large Language Models

- **Authors**: Eunyeong Cho, Jehyeon Bang, Ranggi Hwang, Minsoo Rhu (KAIST)
- **Venue**: HPCA 2026 (Jan 31, 2026)
- **Links**: arXiv PDF: https://arxiv.org/pdf/2602.11530 ; HPCA 2026 main track: https://2026.hpca-conf.org/track/hpca-2026-main-conference
- **Code**: Not released as of fetch date
- **Fetched**: 2026-09-10
- **Tier**: 4 — reasoning-serving-primary

## Abstract

PASCAL is a scheduling algorithm for serving reasoning-based LLMs, which exhibit an internally-divided decoding stage: a **reasoning phase** producing latent (user-invisible) chain-of-thought tokens, followed by an **answering phase** producing user-visible output. Because users see nothing until the reasoning phase finishes, perceived TTFT is dramatically inflated relative to conventional LLMs. PASCAL exploits the asymmetric performance and SLO requirements of the two phases: it prioritizes reasoning to shrink perceived TTFT, then applies controlled preemption and token pacing during the answering phase to preserve TPOT and quality-of-experience.

## Admission-adjacent component?

**No admission-time classification.** PASCAL does **not** classify incoming requests as reasoning-vs-chat at ingress. Phase identification happens **during execution** — the scheduler monitors decoding and detects the reasoning→answering transition as it unfolds, then re-orders / preempts already-running requests accordingly. There is no ingress gate that predicts, from the prompt alone, whether a request will trigger extended reasoning or how many reasoning tokens it will emit. All phase-awareness is post-hoc, applied to requests that have already been admitted and are executing.

## Contribution

- Characterizes the two-phase decoding structure of reasoning LLMs (latent reasoning phase + user-visible answering phase) and shows conventional TTFT/TPOT metrics mis-map onto this structure.
- Proposes a **phase-aware scheduler**: prioritize reasoning-phase execution to compress perceived TTFT; apply controlled preemption + token-pacing on the answering phase to hold TPOT SLO.
- Demonstrates throughput and tail-latency wins over prior serving systems on reasoning workloads without model modification.

## Baselines

vLLM, ANDES, AQUA, FastServe, DistServe.

## Evaluation setup

- **Models**: DeepSeek-R1, Qwen-32B (reasoning variant), o4-mini.
- **Workloads**: MATH-500, AIME (math reasoning); LiveCodeBench (code); GPQA (general reasoning).
- **Hardware**: GPU inference cluster (details in paper's experimental section).
- **Metrics**: throughput, TTFT (perceived), TPOT, resource utilization.

## Relevance to survey (cluster 5.6 — reasoning-aware serving)

PASCAL is the canonical HPCA'26 exemplar for **reasoning-phase-aware scheduling**, and is directly load-bearing for **Open Problem 4 (reasoning-trace-aware admission)**. Crucially, PASCAL operates entirely *after* admission: it re-orders and preempts requests once decoding has begun and phase transitions become observable. It does not attempt to predict reasoning length, reasoning-vs-chat routing, or expected KV footprint from the input prompt at ingress.

This is exactly the gap Open Problem 4 names. Even the most sophisticated reasoning-aware serving system in the 2026 literature treats phase-awareness as a *runtime scheduling* concern, not an *admission* concern. The ingress-side questions — "should this request even be admitted given its likely reasoning trace length?", "should this be routed to a reasoning-optimized replica vs a chat replica?", "what is the probability this prompt triggers extended CoT and blows the KV budget?" — remain **unclaimed** in the surveyed literature. PASCAL's post-hoc phase detection is a lower bound on what's possible; a reasoning-trace-aware *admission controller* that predicts trace length from prompt features (difficulty classifier, self-consistency proxy, learned length regressor) is an open research direction the survey should explicitly call out.

Cite PASCAL in §5.6 as the state-of-the-art reasoning-aware scheduler, and in the Open Problem 4 discussion as evidence that the community has moved on reasoning-aware *scheduling* but not reasoning-aware *admission*.
