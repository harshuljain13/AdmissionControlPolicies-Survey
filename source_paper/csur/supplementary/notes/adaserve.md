# AdaServe: Accelerating Multi-SLO LLM Serving with SLO-Customized Speculative Decoding

- **Authors**: Zikun Li, Zhuofu Chen, Remi Delacourt, Gabriele Oliaro, Zeyu Wang, Qinghan Chen, Shuhuai Lin, April Yang, Zhihao Zhang, Zhuoming Chen, Yi-Hsiang Lai, Xinhao Cheng, Xupeng Miao, Zhihao Jia (CMU, Princeton, EPFL, AWS, Purdue)
- **Venue**: EuroSys '26 (Edinburgh, Apr 27-30 2026) — cited as EuroSys '25 in tasking; DOI **10.1145/3767295.3769315**
- **Links**: [ACM DL](https://dl.acm.org/doi/10.1145/3767295.3769315) · [arXiv 2501.12162](https://arxiv.org/abs/2501.12162) · [CMU author PDF](https://www.cs.cmu.edu/~zhihaoj2/papers/AdaServe_EuroSys26.pdf)
- **Code**: not linked in the paper (no public repo surfaced as of fetch date)
- **Fetched**: 2026-09-10
- **Tier**: 4 — SLO-serving-primary
- **Cluster**: 5.6 (multi-SLO serving)

## Abstract

Modern LLM applications exhibit diverse SLOs, from low-latency interactive coding assistants to relaxed data-wrangling tasks. Existing serving systems using uniform batching and scheduling fail to meet heterogeneous SLOs concurrently. AdaServe is the first LLM serving system designed for efficient multi-SLO serving through *SLO-customized speculative decoding*. It formulates multi-SLO serving as a constrained optimization problem and introduces a hardware-aware algorithm that constructs a speculation tree tailored to each request's TPOT target. A speculate-select-verify pipeline enables fine-grained per-request decoding-speed control while maximizing throughput; speculation parameters are dynamically re-tuned as workload varies. Evaluations show up to **4.3x fewer SLO violations** and **1.9x higher goodput** vs. best baselines.

## Admission-adjacent component?

**Not classical admission control, but a related "feasibility check" is present.** The paper's primary SLO lever is per-request speculation tree shape (depth x width), not request rejection. However, Algorithm 1 (optimal token-tree construction, §4.1) explicitly returns **INVALID** when the aggregate TPOT constraints across the current batch cannot be simultaneously satisfied within the hardware token budget B — i.e., the scheduler *does* detect infeasibility of the currently active batch. The paper does not describe what the runtime does with INVALID (drop request, defer to next iteration, degrade SLO). It is not framed as an admission-control paper: there is no queue-time SLO check, no explicit reject-on-arrival policy, no priority-based dropping. Overload is instead absorbed by (a) shrinking speculation aggressiveness under high RPS (Fig. 12 shows mean accepted tokens degrading as RPS rises) and (b) SLO attainment gracefully declining rather than being enforced by admission.

**Bottom line for the survey**: speculation-length tuning is the primary SLO lever; the INVALID signal is a latent admission hook that the paper leaves unexploited. Worth citing as an example of *implicit* admission surface inside a scheduler that is otherwise "keep everything, adapt speculation."

## Contributions

- **Formalizes multi-SLO serving as constrained optimization** over per-request speculation trees {T_i} with a hardware token budget B and per-request TPOT constraints; proves an optimal greedy tree-construction algorithm (Thm. 3.1 decomposes expected accepted tokens as a sum over node path-probabilities).
- **SLO-customized speculative decoding** — a practical "speculate → SLO-customized selection → throughput-optimized selection → verify" pipeline. Draft-model logits approximate f(v) path probabilities, so trees can be built without an oracle. First pass allocates tokens to satisfy each request's A(r_i); remaining budget is filled to maximize throughput.
- **Hardware-aware dynamic adaptation** — roofline profiling sets the token budget B; speculation depth/width dynamically re-tune as batch composition shifts. Architecture-agnostic to drafter (small LM, EAGLE, MTP heads).

## Baselines

- **vLLM** (continuous batching, no SD)
- **vLLM + Priority** (constrains batch size, preempts non-urgent)
- **Sarathi-Serve** (chunked prefill)
- **vLLM-Spec** with fixed speculation lengths {4, 6, 8}
- **SpecInfer** (static tree SD, low-latency native SD engine)
- (Fig. 1 also references FastServe, VTC as continuous-batching-family failure cases; not run head-to-head throughout §6)

## Evaluation setup

- **Models**: Llama-3.1-70B-Instruct, Qwen2.5-32B-Instruct. Drafters: Llama-3.2-1B, Qwen2.5-0.5B.
- **Workloads**: 3-category mix — Cat.1 coding copilot (HumanEval, TPOT = 1.2x baseline, ~40 ms/tok), Cat.2 chatbot (Alpaca, 50 ms), Cat.3 summarization (CNN/DailyMail, 150 ms). Default mix 60/20/20. Real trace timestamps rescaled to varying RPS; also a synthetic bursty trace where per-app rates peak at different times (Fig. 13).
- **Metrics**: SLO attainment (fraction of requests meeting per-token TPOT); goodput (tokens/s from SLO-satisfying requests only). TTFT explicitly excluded.
- **Sweeps**: RPS (2.4–4.8), urgent-request proportion (30–90%), SLO scale (1.6x → 0.6x). Ablations for CUDAGraph, SLO-customized vs. equal token allocation, throughput-optimized fill.

## Relevance to survey (cluster 5.6)

Sibling to **SLOs-Serve** (concurrent, arXiv 2504.08784 [ref 8] — "addresses the multi-SLO challenge using dynamic programming to schedule SD"). Both target multi-SLO LLM serving with speculative decoding as the elasticity knob. **Design difference**:

- **SLOs-Serve**: DP-based *scheduler* over speculation decisions — per-iteration decision problem framed globally, tuning *how many* speculative tokens each request gets.
- **AdaServe**: constructs *token trees* (not linear speculation lengths) per request, provably optimal under known path probabilities, with a two-phase selection (SLO-fill then throughput-fill) and drafter-logit approximation for the unknown-probability case. Explicitly tree-based, not sequence-based.

Also positioned against **SpecServe** (arXiv 2503.05096, another SLO-aware adaptive SD system) and **SmartSpec** (SD length tuning without SLO awareness). AdaServe's differentiator inside cluster 5.6 is *tree topology as the SLO knob* and the constrained-optimization framing.

For the survey's admission-control taxonomy: file AdaServe under **"SLO-adaptive computation allocation, no explicit admission"**, but flag Algorithm 1's INVALID branch as a *latent admission signal* worth contrasting against systems that actually reject (Llumnix, Concord, etc.).
