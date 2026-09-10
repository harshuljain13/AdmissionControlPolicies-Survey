# Cake: Compute or Load KV Cache? Why Not Both?

- **Full title:** Compute Or Load KV Cache? Why Not Both?
- **Authors:** Shuowei Jin, Xueshen Liu, Qingzhao Zhang, Z. Morley Mao (University of Michigan / University of Arizona)
- **Venue:** ICML 2025 (PMLR 267:28031–28043)
- **Links:**
  - arXiv: https://arxiv.org/abs/2410.03065
  - PMLR: https://proceedings.mlr.press/v267/jin25d.html
  - ICML Poster: https://icml.cc/virtual/2025/poster/45020
  - OpenReview: https://openreview.net/forum?id=cK0kUzocJW
- **Code:** Not officially released as of fetch date; artifact links absent from paper page.
- **Fetched:** 2026-09-10

## Abstract
LLMs are increasingly deployed at scale, but the prefill stage's cost of generating KV caches is a major bottleneck for long-context inputs. Prefix caching mitigates this by reusing stored KV caches, yet loading them from storage is bandwidth-bound and adds latency. Cake (Computation and Network Aware KV CachE loader) simultaneously loads saved KV cache from prefix-cache locations while computing KV cache on local GPUs, maximizing utilization of both compute and I/O bandwidth. It employs a bidirectional parallelized generation strategy — GPU computes forward from the first token, while the loader streams the cached prefix in reverse from the last token — meeting in the middle. Cake also includes an adaptive scheduler that integrates with non-prefix-caching requests. Across hardware configurations, datasets, and storage conditions, Cake achieves on average 2.6× reduction in Time to First Token (TTFT) versus compute-only and I/O-only baselines.

## Taxonomy placement
KV cache management / prefix cache loading. Adjacent to admission control and scheduling only in the sense that its adaptive scheduler mediates between prefix-hit and non-prefix requests; the core contribution is a hybrid compute+load prefill dataplane, not request-level admission.

## Contribution (compute-vs-load decision mechanism)
- **Bidirectional prefill fill-in:** GPU recomputes KV from token 0 forward; loader streams cached KV from token N backward; they meet at a crossover token determined by relative rates. Both resources are saturated throughout.
- **Rate-asymmetry insight:** Compute cost per token grows with position (attention over prior tokens), while I/O stream cost per token is position-invariant. Reverse loading exploits this to attack the expensive tail while compute handles the cheap head.
- **No explicit binary decision** ("compute vs load") per prefix — instead a *continuous split point* chosen dynamically from measured GPU throughput and storage bandwidth. Removes the brittle threshold logic of prior compute-or-load policies.
- **Adaptive scheduler:** Reallocates GPU cycles between prefix-hit prefills (which need less compute) and non-prefix prefills (which need all of it), responding to fluctuating resource availability.
- **Storage-tier agnostic:** Evaluated across local NVMe, remote SSD, and network-attached storage; the crossover point self-adjusts.

## Baselines
- Compute-only prefill (recompute KV from scratch, ignore cache).
- Load-only prefill (stream KV from prefix cache store, no overlapping compute).
- Static-threshold "compute-or-load" heuristics (prior prefix-cache systems that binary-select per request based on cache size vs bandwidth).

## Evaluation setup
- Hardware: multiple GPU configurations (paper reports across A100/RTX-class setups) paired with different storage backends (local NVMe, remote SSD, NAS/network storage) to sweep the I/O-bandwidth axis.
- Workloads: long-context LLM prefill traces on standard open models; datasets exercise varying prefix-hit ratios and context lengths.
- Metric: primarily **TTFT** (Time to First Token); secondary throughput under mixed prefix/non-prefix traffic.

## Claimed numbers
- **Average 2.6× TTFT reduction** vs both compute-only and I/O-only baselines.
- Gains reported across all tested storage bandwidths, with the crossover point shifting toward more compute as storage slows down (and vice versa).
- Throughput improvements under mixed workloads via the adaptive scheduler (paper reports gains but exact percentage varies by trace).

## Fidelity
Medium-high. Numbers come from a real system implementation with end-to-end TTFT measurements across multiple hardware/storage combinations — not simulator. Concern: no public code release located at fetch date, so reproducibility depends on paper appendix. Baselines are the natural extremes (pure compute, pure load) plus static threshold; no comparison to production serving stacks like vLLM's prefix caching or SGLang's RadixAttention with tiered storage — which limits how strong the "state of the art" claim is.

## Relevance to survey (cluster 5.5)
Cluster 5.5 (KV cache management + prefill acceleration) — direct fit. Cake is a canonical citation for the "prefix cache is not free — loading has latency" sub-problem, and its bidirectional-fill trick is the cleanest formulation of the compute-vs-load tradeoff to date. Cite alongside CachedAttention, LMCache, and Preble as the compute+I/O overlap point in the prefix-cache design space. For an **admission control** survey specifically, Cake is a *boundary case*: it doesn't admit/reject requests, but the adaptive scheduler between prefix-hit and non-prefix requests is a resource-arbitration mechanism that any admission controller layered on top would need to be aware of.

## Open questions surfaced
- How does bidirectional fill interact with **chunked prefill** and continuous batching schedulers? The crossover point assumes uninterrupted GPU compute — under chunking, the compute rate is time-varying.
- The adaptive scheduler treats prefix-hit and non-prefix requests as two classes; **can this generalize to N-class SLO-aware admission**, where some tenants get guaranteed bandwidth?
- Reverse-order KV streaming assumes the cache store supports random-access reads at arbitrary positions — how does this compose with **compressed** or **quantized** KV caches where decode is sequential?
- Energy/cost model absent: computing forward from token 0 uses GPU power that could serve another request. When is the crossover point *economically* optimal vs latency-optimal?
- **NEW open problem:** Cake optimizes a *single* request's TTFT. Under high load, the bidirectional strategy consumes GPU cycles that a pure-load policy would leave free for other requests' decode. There is no published characterization of when hybrid fill *hurts* aggregate goodput — a natural admission-control question: *at what queue depth should the system switch from Cake-style hybrid to load-only, freeing GPU for backlog?*
