# Equinox — Holistic Fair Scheduling in Serving LLMs

**Full title**: Equinox: Holistic Fair Scheduling in Serving Large Language Models
**Authors**: Zhixiang Wei, James Yen, Jingyi Chen, Ziyang Zhang, Zhibai Huang, Chen Chen, Xingzi Yu, Yicheng Gu, Chenggang Wu, Yun Wang, Mingyuan Xia, Jie Wu, Hao Wang, Zhengwei Qi (Shanghai Jiao Tong University et al.)
**Venue**: **arXiv preprint** (v1, 19 Aug 2025) — no publicly disclosed acceptance as of 2026-09-10 (adjacent submissions in the same arXiv batch carry explicit "submitted to IAAI26" comments; Equinox's record has no such note).
**Links**: [arXiv:2508.16646](https://arxiv.org/abs/2508.16646) · [HTML v1](https://arxiv.org/html/2508.16646v1) · [PDF](https://arxiv.org/pdf/2508.16646)
**Code**: Paper claims "open-source" but **no repository URL is provided** in v1. Not artifact-evaluated.
**Fetched**: 2026-09-10

## Abstract
Equinox argues that token-centric fair schedulers (VTC and descendants) mis-serve users because equal token allocations produce unequal user-perceived outcomes — identical token counts diverge sharply in latency, throughput, and GPU utilization depending on prefill/decode mix and batch composition. Equinox proposes a **dual-counter** fairness framework: a **User Fairness Counter (UFC)** that weights served tokens by user-perceived latency, and a **Resource Fairness Counter (RFC)** that credits requests contributing to system throughput and GPU utilization. Because both counters need quantities only known post-execution (output length, latency, TPS, GPU-util), Equinox introduces **MoPE (Mixture of Prediction Experts)** — three BERT-base regressors gated by a length router (short <53 tok, medium 53–210, long >210) — to predict these four signals per incoming prompt. A tunable **Holistic Fairness (HF) score = α·UFC + β·RFC** (default α=0.7, β=0.3) drives scheduling; the least-HF user's request is prioritized inside continuous batching, with adaptive batching and stall-free execution on top. On ShareGPT/LMSYS traces the authors report 1.3× higher throughput, 60% lower TTFT, 13% higher fairness, and 94% GPU utilization vs. VTC.

## Taxonomy placement
- Unit of admission: **tenant** (per-user counters; VTC-lineage)
- Setting: **online serving**
- SLO-awareness: **fairness-oriented, not SLO-guaranteed** (no per-request deadline; no soft-decline)
- Signal used: **predicted** user latency + predicted output tokens + predicted TPS + predicted GPU-util (from MoPE), combined into HF = α·UFC + β·RFC

## Contribution — fairness mechanism vs VTC
- **Dual-counter, not single counter.** VTC tracks a single per-user token counter W = w_p·n_p + w_q·n_q. Equinox splits fairness into **user-perceived** (UFC, latency-weighted tokens) and **resource-side** (RFC, throughput × GPU-util), then combines them: `HF = α·UFC + β·RFC`. Fairness is defined jointly over what the user *feels* and what the operator *pays for*.
- **Prediction-driven, not reactive.** VTC updates counters after each generated token (no prediction needed). Equinox needs unknown post-hoc quantities (output length, latency, TPS, util), so it introduces **MoPE**: a length-router + 3 BERT-base experts predicting all four signals from prompt text alone. L1 error 33 with 3 experts vs 80 with a single monolithic predictor; <1% latency overhead (~4.5 ms vs 2.4 s avg request time).
- **Explicit UFC/RFC formulas** — `UFC ← UFC + ω_f·(Tokens_in + 4·Tokens_out) / (1 + δ·(WaitTime + PredictTime))` and `RFC ← RFC + ω_f·TPS·UtilGPU`. Latency shows up as a denominator penalty on user counter, throughput/util as a multiplicative credit on resource counter.
- **Scheduling primitive**: at each continuous-batching step, admit the request from the user with the lowest HF (VTC-analog), but the "least-served" definition now encodes latency and resource-efficiency, not raw tokens.
- **Systems layer**: adaptive batching + stall-free scheduling on top of the fairness policy. Implementation: ~1000 LoC Python atop vLLM/SGLang/S-LoRA.
- **What is *not* new vs VTC**: still per-user, still no admission gate (never declines), still no per-tenant SLO, still no counter-lift analog discussed for idle-then-return users (a regression risk vs VTC).

## Baselines
- **VTC** (Sheng et al., OSDI '24) — primary comparison.
- **FCFS** — engine default.
- Implicitly compared against underlying engines (**vLLM**, **SGLang**, **S-LoRA**) since Equinox is layered on all three.

## Evaluation setup
- **Models**: Llama-2-7B (synthetic workloads, single A100-80GB); **Llama-2-70B** on 8×A100-40GB with TP=8 (real traces).
- **Engines**: vLLM, SGLang, S-LoRA (Equinox implemented atop each).
- **Workloads**: ShareGPT, LMSYS Chatbot Arena (lmsys-chat-1m); synthetic Poisson + balanced + overload scenarios.
- **Hardware**: NVIDIA A100 (40 GB & 80 GB); Intel Xeon Gold 5218 @ 2.30 GHz, 256 GB DRAM.
- **Metrics**: service rate, response time, TTFT, **Jain's Fairness Index**, GPU utilization, throughput.
- **MoPE training**: LMSYS; tested zero-shot on unseen ShareGPT.

## Claimed headline numbers
- vs VTC on production traces (Llama-2-70B, 8×A100): **1.3× throughput**, **60% lower TTFT**, **+13% fairness score** (Jain's index basis), **94% GPU utilization** sustained.
- MoPE prediction: L1 error **33** (3-expert mixture) vs **80** (single expert); routing overhead **0.02 ms**, total prediction **4.5 ms** vs **~2400 ms** avg request latency (<1%).

## Fidelity / reproducibility
- **No code released** as of 2026-09-10 despite "open-source" claim. Not artifact-evaluated.
- Workloads (ShareGPT, LMSYS) and hardware (A100) are standard; models are open Llama-2 weights.
- MoPE requires a trained BERT-base × 3 mixture plus a length-router classifier — training procedure sketched but no released checkpoints. **Reproducibility is a real risk**: the whole scheduling gain depends on prediction accuracy, and prediction accuracy is hard to reproduce without the trained models. Adds to Open Problem 5 (reproducibility crisis).

## Relevance to survey
Fairness cluster (§5.3), **tenant-fairness sub-branch** alongside VTC (and distinct from FairBatching's per-task batch-time-budget fairness). Direct successor / rival to VTC. Load-bearing for Open Problem 23 (fairness composability with other objectives — here, latency and GPU utilization instead of prefix-cache locality) and Problem 24 (VTC never says no — Equinox inherits the same gap). Introduces a new axis worth surfacing: **fairness-of-perception vs fairness-of-tokens**, which motivates a new open problem below.

## Open questions surfaced
- **Prediction fragility.** Every scheduling decision now depends on MoPE. What happens on distribution shift (a new tenant with a workload MoPE has never seen — code-heavy prompts, non-English, reasoning-CoT)? VTC needs zero prediction; Equinox degrades gracefully to what? Not measured. This is the same fragility Clairvoyant flagged for length prediction (see Problem 22).
- **No counter-lift analog for idle users.** VTC's key correctness result — a bounded 2× service gap and the "counter-lift" that prevents an idle user from banking and bursting — has no discussed analog in HF. What stops a user who was offline for 10 min from suddenly holding the lowest HF and monopolizing the scheduler? Paper is silent.
- **α, β are magic numbers.** HF = 0.7·UFC + 0.3·RFC is fixed by hand. In a multi-tenant system, whose interest do these weights encode — SRE (RFC) or user (UFC)? No sensitivity study.
- **Fairness metric drift.** Equinox's own reported fairness "+13%" is measured on a Jain-style index computed *over Equinox's own HF definition*. Fair comparison to VTC would require both systems measured against a definition-neutral fairness metric (e.g., latency-percentile spread across users). Currently the metric is entangled with the mechanism.
- **No admission gate.** Same VTC limitation (Problem 24): Equinox reorders, never declines. Under sustained overload, HF just decays uniformly — no principled tenant eviction.
- **Untested against DLPM (arXiv:2501.14312).** DLPM already reports 2.87× throughput vs VTC by exploiting prefix-cache locality — a completely different axis than Equinox's latency/util axis. Neither system compares to the other; the fair-scheduling frontier is fragmenting along orthogonal axes with no head-to-head.
