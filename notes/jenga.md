# Jenga: Effective Memory Management for Serving LLM with Heterogeneity

- **Authors**: Chen Zhang, Kuntai Du, Shu Liu, Woosuk Kwon, Xiangxi Mo, Yufeng Wang, Xiaoxuan Liu, Kaichao You, Zhuohan Li, Mingsheng Long, Jidong Zhai, Joseph Gonzalez, Ion Stoica (Tsinghua, UC Berkeley, U. Chicago, et al.)
- **Venue**: SOSP '25 (pp. 446-461)
- **Links**: [arXiv 2503.18292](https://arxiv.org/abs/2503.18292) | [ACM DL](https://doi.org/10.1145/3731569.3764823)
- **Code**: https://github.com/heheda12345/Jenga-SOSP25-AE (artifact); simplified version merged into vLLM main
- **Fetched**: 2026-09-10
- **Tier**: 4 — admission-adjacent (memory management primary)

## Abstract (paraphrased)

To reduce LLM serving cost, one must maximize request batch size through efficient GPU memory management. PagedAttention-style allocators struggle with modern LLMs because of growing heterogeneity in embedding sizes and attention mechanisms (full attention, sliding window, Mamba SSMs, local attention, vision-language embeddings). Jenga tackles (1) minimizing fragmentation across differently sized embeddings and (2) enabling flexible per-layer caching/eviction policies tuned to each layer's token-dependency pattern. It uses a two-level allocator sized around the LCM of embedding sizes plus attention-property-aware eviction. On vLLM, Jenga improves GPU memory utilization by up to 79.6% and throughput by up to 4.92x (1.80x avg).

## Admission-adjacent component?

**Not directly an admission controller.** Jenga is fundamentally a memory placement + eviction / allocation system for heterogeneous KV state. There is no per-request gate or reject/queue mechanism proposed as a Jenga primitive.

Admission-adjacency is indirect:
- By raising achievable batch size, Jenga shifts the *threshold* at which a scheduler (vLLM's) must start rejecting or preempting — i.e., it changes the working point admission control operates against, not admission policy itself.
- The layer-specific *eviction* policies act as an implicit intra-request memory admission (which cached tokens survive), but scope is KV cache, not request-level gating.
- Downstream schedulers built on Jenga could in principle expose per-tier gating, but the paper does not.

## Contribution

- **Two-level allocator over LCM of embedding sizes**: eliminates fragmentation when a single model mixes attention variants with different per-token state footprints (full attn KV vs SWA vs Mamba SSM vs VLM embeddings).
- **Attention-property-aware caching/eviction API**: per-layer policies exploit token-dependency structure (e.g., sliding-window layers can drop tokens outside window; SSM layers keep compressed state) to raise reuse.
- **Drop-in vLLM integration** demonstrating up to 79.6% memory-utilization gain and up to 4.92x throughput on heterogeneous models.

## Baselines

- vLLM / PagedAttention (homogeneous block allocator) as the primary baseline.
- Comparisons across model families with mixed attention types (Llama-family full attention, Gemma SWA, Mamba/Jamba-style SSMs, VLMs).

## Evaluation setup

- Implemented on vLLM.
- Diverse LLMs (heterogeneous attention: full, SWA, Mamba, VLM), diverse datasets, multiple GPU configs (1x H100 primary; some experiments on 1x L4, 8x H100, 8x H200).
- Metrics: GPU memory utilization, serving throughput, batch size.

## Relevance to survey

- **Primary cluster**: **5.5 KV-cache-management-adjacent** — Jenga is a KV/allocator system, not a scheduler. Cite as the state-of-the-art for heterogeneous-model memory management that *enables* larger batches, which changes the operating regime for admission/scheduling policies covered in 5.1-5.3.
- **Cross-reference**: contrast with admission-primary papers that reject/queue requests under memory pressure — Jenga instead expands effective memory capacity, reducing (but not eliminating) the need to gate. A future admission controller could sit on top of Jenga's per-tier accounting to make per-mechanism (full-attn vs SWA vs SSM) admission decisions; flag as open direction.
- Not appropriate for 5.6 (scheduling-primary) — no scheduling contribution.
