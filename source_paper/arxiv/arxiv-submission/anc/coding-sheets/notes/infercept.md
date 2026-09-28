# InferCept: Efficient Intercept Support for Augmented Large Language Model Inference

- **Authors:** Reyna Abhyankar*, Zijian He*, Vikranth Srivatsa, Hao Zhang, Yiying Zhang (UC San Diego; *equal contribution)
- **Venue:** ICML 2024 (PMLR v235, pp. 81–95)
- **Links:**
  - arXiv: https://arxiv.org/abs/2402.01869 (v2, 30 May 2024)
  - PMLR: https://proceedings.mlr.press/v235/abhyankar24a.html
  - ICML poster: https://icml.cc/virtual/2024/poster/32755
- **Code:** https://github.com/WukLab/InferCept (built on vLLM)
- **Fetched:** 2026-09-10

## Abstract

LLMs are increasingly integrated with external environments, tools, and agents (ChatGPT plugins, etc.) that intercept generation. Today's inference systems treat each external interaction as request termination and re-submit a fresh request on return, causing recomputation of already-computed context that consumes **37–40% of total model forwarding time**. InferCept is the first LLM inference framework targeting augmented LLMs; it minimizes GPU resource waste caused by interceptions and reallocates the saved memory to more requests, delivering **1.6×–2× higher serving throughput** and **2× more completed requests per second** vs. SOTA baselines.

## Taxonomy placement

- **Primary cluster (5.5):** KV-cache management for tool-call / external interception. The problem InferCept invents: what to do with a request's KV cache while it is paused waiting for a tool/human/env response.
- **Adjacent cluster (5.2, agent serving):** Foundational prior art for agent-aware serving. Continuum, TokenCake, AugServe, and follow-ups explicitly extend or contrast against InferCept's preserve/swap/discard framework.

## Contribution

1. **Formalizes "interception" as a first-class scheduling event** in LLM serving and characterizes six augmentation types (Math, QA, VE, Chatbot, Image, TTS) with empirical interception-time and context-length distributions (Table 1) — showing wide variance that defeats any single static policy.
2. **Three closed-form GPU-memory *waste* equations** (per intercepted request `i` at interception `j`, with `M` = per-token KV bytes, `C_i^j` = context tokens, `C_other` = sum of other running contexts, `T_fwd`/`T_swap` = profiled functions):
   - **WasteDiscard** = `T_fwd(C_i^j)·C_i^j·M  +  T_fwd(C_i^j)·C_other·M` (recompute self-cost + blocking-others cost)
   - **WastePreserve** = `T_INT^j · C_i · M` (context sits idle for the entire interception duration)
   - **WasteSwap** = `2·T_swap(C_i^j)·C_batch·M` (swap-out + swap-in, blocking whole batch)
   - Chunked variant **WasteChunkD** cuts recompute-self by ~2× via GPU-saturation-point (`S`) chunking.
3. **Improved primitives:** (a) **Swap pipelining/chunking** — layer-by-layer overlap of swap kernels with forward pass; (b) **Recomputation chunking** — split context into chunks ≤ `S` query tokens and hide inside underutilized decoding iterations; (c) **Dynamic interception-duration estimator** `T̂_INT = t_now − t_call` (achieves 93% of oracle performance).
4. **Min-waste inter-request scheduler:** at each iteration, per request pick `min(WastePreserve_i, WasteChunkD_i)`; sort intercepted requests by waste descending, assign swap-out budget to top-waste requests until budget exhausted, preserve/discard the rest. Uses three queues (running, swap, waiting), all sorted by original arrival time (FCFS for fairness).
5. **End-to-end system on vLLM** with PagedAttention, orthogonal to Sarathi chunked-prefill, prefix sharing (SGLang/Preble), and DistServe disaggregation.

## Baselines

- **vLLM** (v0.2-era, Kwon et al. SOSP'23) — vanilla Discard, FCFS re-inserts intercepted requests at tail of wait queue.
- **ImprovedDiscard** — vLLM Discard but re-inserts with the *original* arrival time (fair FCFS).
- **Preserve** — naive full-KV retention across the entire interception.
- **Swap** — naive synchronous swap-out/in to host memory.

## Evaluation setup

- **Models:** GPT-J-6B, Vicuna-13B, Llama3-70B.
- **Hardware:** NVIDIA A100. 6B on 1×A100; 13B on 1× and 2× A100 (TP); 70B on 4× A100 (TP).
- **Workloads:** Mixed workload uniformly sampled from six augmentations — GSM8K (math+calculator), Multihop-QA over Wikipedia (QA), ALFWorld (VE), ShareGPT (chatbot), ChatGPT-prompt→Stable Diffusion (image), ChatGPT-prompt→Bark TTS. Also two single-augment stress tests (QA, Chatbot).
- **Metrics:** normalized latency (median end-to-end latency / output length, interception time subtracted), throughput (req/s), TTFT, per-technique GPU-memory waste %.

## Claimed numbers

- **6B / 1 GPU:** up to **1.6×** higher sustained arrival rate at iso-latency vs. vLLM; **1.9–5.7×** lower normalized latency; **1.7×** higher rate at smallest TTFT. Eliminates >60% of recompute waste and 96% of swap waste vs. improved variants.
- **13B / 1 GPU:** up to **1.25×** higher rate, **3.1×** at smallest TTFT (gains capped by weight memory).
- **13B / 2 GPU:** up to **1.8×** rate, **1.6–10×** normalized latency (gains grow with TP because more KV headroom → more concurrent intercepts).
- **Llama3-70B / 4 GPU:** **2×** rate, **1.3–12×** lower normalized latency, **2.4×** load at iso-TTFT. GQA shrinks per-request KV → Preserve/Swap look better, so InferCept's edge is mainly from optimal per-request decisions.
- **Technique ablation** (Fig. 3, 6B at 2 req/s): vanilla vLLM waste ≈ 25%; full InferCept waste = **0.69%**. ImprovedDiscard −24.5% latency; +chunked recompute −7.8%; +budgeted swap −12.7%; +heuristic Preserve −46.1%; +min-waste dynamic schedule −46.4% additional.
- **Single-augment:** 2.3× (QA), 1.9× (Chatbot) latency improvement over vLLM.

## Fidelity

- Strong. Real workloads, three model scales, distributed TP, ablation isolates each technique's contribution.
- Estimation-vs-oracle interception-duration study (93% recovery) is exactly the honest sensitivity study a survey wants.
- Weakness: swap bandwidth is A100-PCIe specific; H100/NVLink numbers not reported. All eval on A100; no H100. FCFS-only scheduler comparison — authors explicitly defer multi-level feedback queue (FastServe) and other policies to future work.

## Relevance to survey

- **Cluster 5.5 (KV cache during tool intercepts):** *foundational*. Every subsequent agent-serving paper (Parrot, Autellix, Continuum, TokenCake, AugServe) either builds on or benchmarks against InferCept's preserve/swap/discard trichotomy.
- **Cluster 5.2 (agent-level serving):** the direct ancestor Continuum extends. Per the Continuum deep read, Continuum's core delta is *adding a queueing / memory-occupation term* to InferCept's per-request waste equation — i.e., InferCept's `WastePreserve` charges only `T_INT × C_i × M` for holding memory, but does **not** price in the opportunity cost of waiting requests that could have used that memory. Once the queue is non-trivial, InferCept's decision surface is provably sub-optimal, which is Continuum's opening.

## Open questions surfaced

- **No admission control.** InferCept never rejects, defers, or rate-limits a request. Waiting-queue insertion is unconditional FCFS; capacity is enforced only by "add requests until GPU capacity reached" at batch-build time. All decisions are *reactive KV-management for already-admitted requests*, not proactive admission.
- **Cost model is per-request-local.** WastePreserve/WasteSwap/WasteDiscard price GPU-memory-time for the intercepted request and (for Discard/Swap) blocking cost on the currently *running* batch (`C_other`, `C_batch`). They do **not** model queue length, waiting-request memory demand, or arrival-rate–dependent opportunity cost of holding memory idle. This is precisely the hole Continuum fills.
- **`T̂_INT = t_now − t_call` is a memoryless heuristic.** It assumes hazard rate is increasing (the longer it's been, the longer it'll be), which is fine for heavy-tailed human/network intercepts but likely mispredicts short-tail tool calls. No per-augmentation-type prior is used at runtime even though §2 shows the priors are dramatically different.
- **New open problem surfaced by this paper:** *joint scheduling of intercept KV-management and request admission/preemption under stochastic interception durations.* InferCept optimizes what to do with an intercepted request in isolation; the true objective is joint over (admit new? preempt running? preserve/swap/discard intercepted?) — a POMDP with unknown intercept-duration distributions. No existing work (through the papers we've read) solves this jointly with an admission-control lever.
- **GQA changes the calculus.** On Llama3-70B, GQA shrinks per-request KV so Preserve becomes cheap and Swap becomes fast, compressing the gap between policies. As models increasingly ship with GQA/MLA/MQA, InferCept's dynamic-selection payoff may diminish and the *scheduling* term (Continuum's contribution) becomes the dominant lever. Worth revisiting on 2025-era architectures (Llama-3.1, DeepSeek-V3 MLA).
