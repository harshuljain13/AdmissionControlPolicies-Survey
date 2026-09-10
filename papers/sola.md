# SOLA

**Full title**: SOLA: Optimizing SLO Attainment for Large Language Model Serving with State-Aware Scheduling
**Authors**: Ke Hong, Xiuhong Li, Lufang Chen, Qiuli Mao, Xuefei Ning, Guohao Dai, Shengen Yan, Yun Liang, Yu Wang (Tsinghua, Infinigence-AI, SJTU, PKU)
**Venue**: **MLSys 2025** (poster, presented May 14 2025)
**Links**: [MLSys Proceedings hash bc82dbfbfa43232be85b8d9838f49c3e](https://proceedings.mlsys.org/paper_files/paper/2025/hash/bc82dbfbfa43232be85b8d9838f49c3e-Abstract-Conference.html) · [OpenReview ubIvpetAd6](https://openreview.net/forum?id=ubIvpetAd6) · [Slides](https://mlsys.org/media/mlsys-2025/Slides/3231.pdf) · [Full PDF](https://nicsefc.ee.tsinghua.edu.cn/nics_file/pdf/ce55a1f2-ff0d-45f6-8985-f4f251b2a0d4.pdf)
**Code**: Not released as of publication; no GitHub link in the paper. Implemented as a standalone Python framework layered on vLLM v0.4.2 (§5).
**Fetched**: 2026-09-10

## Abstract
Existing serving systems apply a coarse-grained, fixed-principle scheduling policy (e.g., always prefill-prioritized or always decode-prioritized) that causes (a) a systemic latency-distribution bias between TTFT and TPOT (one metric near-perfect, the other overflowing) and (b) large inter-request variance (some requests fail SLOs while others have slack to spare). SOLA formalizes the fine-grained scheduling design space, then introduces a **state-aware** policy that monitors both per-request state and system-wide state and solves a per-iteration constrained optimization to jointly balance TTFT and TPOT and to redistribute slack across requests. On vLLM v0.4.2, SOLA raises SLO attainment from 45.5% to 99.4% in the headline configuration and serves 1.04-1.27x more requests than SOTA schedulers.

## Taxonomy placement
- Unit of admission: **request**
- Setting: **online serving**
- SLO-awareness: **deadline-aware** (TTFT + TPOT)
- Signal used: composite (per-request state + systemic state; distinct from Chronos's slack-only and QLM's queue-only signals)

## Contribution (deep-read summary — Days 2-6)
- **Formal design space for fine-grained iteration-level scheduling.** Every iteration i is parameterized by three orthogonal knobs (Table 1): a sorting/priority function F_i over the waiting queue, a per-iteration request cap n_i, and a per-iteration token cap k_i. Existing systems are recovered as fixed settings (e.g., vLLM default is n_i=256, k_i=512, prefill-first sort); SOLA lets these vary at every iteration.
- **State monitor with two state classes.** *Single-request state*: real-time TTFT t_TTFT_{i,r}, real-time TPOT t_TPOT_{i,r}, generated length l_out_{i,r}, predicted remaining length l_left_{i,r}, input length l_in_r. *Systemic state*: KV-cache used ratio m_ratio_i, waiting queue Q_wait, running queue Q_run, system-wide attainment ratios p_TTFT_i = max_r(t_TTFT_{i,r})/T_TTFT and p_TPOT_i analogously, and output-length distribution D_i.
- **Strategy generator as a per-iteration constrained optimization** (Table 2, Fig. 5). Depending on which of {p_TTFT, p_TPOT} is worse, SOLA either (i) minimizes worst-case TPOT subject to worst-case TTFT <= T_TTFT, or (ii) minimizes worst-case TTFT subject to worst-case TPOT <= T_TPOT. When neither SLO can be satisfied, the constraint is *loosened to an alpha-percentile* max so the LP remains feasible. This drives the state transition toward the (p_TTFT<=1, p_TPOT<=1) corner.
- **Hierarchical prioritization F_i (§4.4.2).** First, phase-level ordering flips between prefill-first and decode-first based on which SLO is binding, smoothed by a sliding window over iterations to damp oscillation. Second, request-level ordering within a phase: prefills sorted descending by (t_TTFT_{i,r} + C_p(r)) predicted TTFT; decodes sorted descending by predicted TPOT (t_TPOT_{i,r} * l_out + C_d(Q_run)*l_left)/(l_out+l_left).
- **Peak-memory prediction to eliminate preemption** (§5.1, borrowed from LightLLM). Admits a new request only if projected peak KV memory <= M*(1 - m_ratio). Two polynomial cost models C_p (prefill FLOPs) and C_d (decode memory-bandwidth) are fit offline from profiling and online-tuned via a linear scaling ratio gamma_i = alpha * t(r)/C_0(r) + (1-alpha)*gamma_{i-1}; average absolute latency-prediction error 4.98-5.92% (8.91% on very-long-input arXiv workload).

## Baselines
Three schedulers, all integrated on vLLM v0.4.2 for apples-to-apples comparison:
- **vLLM-D** — default vLLM, prefill-prioritized continuous batching (Kwon et al. 2023).
- **vLLM-S** — vLLM with **SplitFuse / Sarathi-Serve-style chunked-prefill** (Agrawal et al. 2024; Holmes et al. 2024) reimplemented on vLLM v0.4.2 (authors reimplement rather than compare against upstream Sarathi to avoid operator-level noise; chunk size = 1024 for chatbot, 4096 for long-context).
- **SJF** — shortest-job-first prioritization on top of vLLM (representing FastServe (Wu et al. 2023) and Fu et al. 2024 learning-to-rank).

## Evaluation setup
- **Testbed**: 8x NVIDIA A100 80GB SXM4, CUDA 12.1, NCCL 2.18, PyTorch 2.3.0.
- **Models & parallelism** (Table 3): Llama3-8B (TP=1), Qwen1.5-14B (TP=2), Llama3-70B (TP=4), Vicuna1.5-7B-16k (TP=1), Qwen1.5-72B (TP=4).
- **Engine**: vLLM v0.4.2 backend for all systems.
- **Workloads**: **ShareGPT** — chatbot, 2000 sampled requests, used with Llama3-8B / Qwen1.5-14B / Llama3-70B. **LongBench** — long-context, all 832 requests (avg input 3.3k tokens), used with Vicuna1.5-7B-16k and Qwen1.5-72B. Arrivals are Poisson.
- **SLO definitions** (Table 3): tight = 10x single-request latency for 7B-14B, 5x for 70B-72B; loose = 15x / 10x. Concrete pairs (TTFT/TPOT in seconds): Llama3-8B 0.4/0.15 tight, 0.6/0.225 loose; Llama3-70B 0.5/0.2 tight, 1.0/0.4 loose; Qwen1.5-14B 0.8/0.2s tight, 1.2/0.3s loose; Vicuna1.5-7B-16k 2.55/0.16s tight, 3.825/0.24s loose; Qwen1.5-72B 2.425/0.2s tight, 4.85/0.4s loose. Also a "very tight" (5x) and "very loose" (20x) sensitivity sweep for the two smaller models.
- **Metric**: **goodput** = maximum input request rate under 90% and 99% SLO attainment (Zhong et al. 2024 DistServe definition). Reports attainment vs. request rate and normalized goodput vs. baselines.

## Claimed headline numbers
- Headline **45.5% -> 99.4%** attainment corresponds to Fig. 1 (Llama3-70B / ShareGPT / 4x A100 / 4.6 req/s / SLO 500 ms TTFT + 200 ms TPOT): vLLM default attains 45.5% (called "65%" in the illustrative subplot with a different point; the 45.5-> 99.4 pair is the abstract's paired quote), SOLA attains 99.4%.
- **Throughput uplift under 90% attainment**: SOLA serves **1.27x** vs vLLM-S, **1.11x** vs vLLM-D, **1.08x** vs SJF on average (Fig. 8a).
- **Under the stricter 99% attainment**: 1.11x / 1.06x / 1.04x respectively (Fig. 8b) — this is the source of the "1.04-1.27x" range in the abstract.
- **Scheduling overhead**: 1.62% (Llama3-70B + ShareGPT), 1.28% (Vicuna1.5-7B + LongBench); i.e., 0.45%/0.40% delta over vLLM-S baseline (Table 4).
- **Ablation on Qwen1.5-72B / LongBench @ 0.45 req/s**: full SOLA 96.5% -> 93.5% without state-aware scheduling -> 93.0% without peak-memory prediction; both mechanisms contribute.
- **Sensitivity**: SOLA matches best baseline under very tight SLO (little slack to trade) and significantly outperforms all under very loose SLO (more room for trade-offs).

## Fidelity / reproducibility
- No public code release announced in the paper; no GitHub URL in the references. Implementation is described as a "standalone Python framework" replacing vLLM's scheduler; dependencies listed (vLLM v0.4.2, LightLLM peak-memory prediction, CUDA 12.1, NCCL 2.18, PyTorch 2.3.0). No released cost-model coefficients (a_0..d_0, a_1..c_1). Reproducibility depends on re-fitting the polynomial cost models per hardware/model — moderate engineering effort but not turnkey. LongBench and ShareGPT are public; Poisson arrival + seed not specified.

## Relevance to survey
Request-level SLO cluster (5.1). Represents the **"systemic state + per-request state fused via constrained optimization"** signal branch — distinct from Chronos (per-request deadline slack only) and QLM (queue-depth only). SOLA is the first paper in the cluster to make the scheduling *policy itself* a decision variable that varies every iteration, rather than a fixed principle. Also the only one in the cluster to use a per-iteration LP formulation with explicit constraint loosening when infeasible.

## Open questions surfaced
- **Length prediction dependency**: TPOT ordering uses predicted remaining output length l_left; SOLA punts to prior work for the predictor (Fu 2024, Hu 2024) and does not evaluate degradation when the predictor is bad. On the extreme-long-input arXiv workload, cost-model error already jumps from ~5% to 8.91% — how does end-to-end attainment respond?
- **LP feasibility & oscillation under bursty arrivals**: The alpha-percentile constraint loosening keeps the LP feasible, but the paper only shows steady-state Poisson arrivals. Bursty or heavy-tailed arrival patterns (which are exactly when admission control matters most) are not evaluated.
- **No admission control, only scheduling**: SOLA *reorders* the waiting queue but never rejects a request or applies backpressure. Under sustained overload where even the loosened LP is infeasible for many iterations, behavior is undefined — this is the natural bridge to the survey's admission-control axis.
- **Preemption excluded by design**: Algorithm 1 explicitly forbids preemption/swapping and relies on peak-memory prediction. Correctness assumption is that the predictor never under-estimates; failure mode under mis-prediction (OOM vs. quality) is not characterized.
- **Cost-model portability**: The two polynomial cost models are fit per (model, hardware, parallelism) offline. No study of how many profiling points are needed or whether the online gamma scaling can recover from a bad initial fit.
- **Comparison scope**: SOLA is only compared against vLLM-D, a reimplemented SplitFuse (vLLM-S), and SJF. No comparison against disaggregated systems (DistServe, Splitwise, TetriInfer) — the paper explicitly scopes to co-located prefill+decode and defers disagg. as orthogonal.
- **Fairness / starvation**: Descending-priority sort by predicted TTFT/TPOT can indefinitely defer short-slack requests when the system is saturated; the alpha-percentile loosening implicitly allows (1-alpha)% requests to be sacrificed, but no per-user fairness guarantee is analyzed (contrast with Sheng et al. 2024).
