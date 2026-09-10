# DistServe: Disaggregating Prefill and Decoding for Goodput-optimized LLM Serving

- **Full title**: DistServe: Disaggregating Prefill and Decoding for Goodput-optimized Large Language Model Serving
- **Authors**: Yinmin Zhong, Shengyu Liu, Junda Chen, Jianbo Hu, Yibo Zhu, Xuanzhe Liu, Xin Jin, Hao Zhang
- **Venue**: OSDI '24 (verified — 18th USENIX Symposium on Operating Systems Design and Implementation, July 2024)
- **Links**: arXiv:2401.09670 — https://arxiv.org/abs/2401.09670 ; HTML: https://arxiv.org/html/2401.09670
- **Code**: https://github.com/LLMServe/DistServe
- **Fetched**: 2026-09-10

## Abstract

DistServe improves LLM serving goodput (requests/sec meeting both TTFT and TPOT SLOs) by physically disaggregating the prefill and decoding phases onto separate GPU instances. Colocation forces prefill-decoding interference and couples resource allocation between two phases with very different compute/memory profiles. By splitting them, DistServe independently optimizes parallelism and batching for each phase, and places instances to minimize KV-cache transfer cost given cluster bandwidth. Reports up to 7.4× more requests or 12.6× tighter SLO than prior colocated systems (vLLM, DeepSpeed-MII) while meeting SLOs on >90% of requests.

## Admission-adjacent component?

DistServe routes each incoming request first to a prefill instance, then hands the resulting KV cache off to a decode instance. This is primarily a **placement / routing decision**, not an admission-control decision — DistServe does not reject, defer, or downgrade requests when the system is saturated. However, it is admission-*adjacent* in two ways:

1. Sizing the prefill:decode instance ratio at deployment time is effectively a static capacity-planning admission knob — a given deployment can only sustain a bounded arrival rate before either the prefill pool or the decode pool becomes the bottleneck.
2. Because prefill and decode become separately-provisioned resources, any future admission controller (e.g., SLOs-Serve) has *two* independent queues/resources to reason about instead of one fused GPU pool. DistServe establishes the substrate; it does not do the admission itself.

## Contributions

- **Phase disaggregation**: separates prefill (compute-bound, latency-sensitive TTFT) from decode (memory-bandwidth-bound, throughput-sensitive TPOT) onto distinct GPU groups, eliminating head-of-line blocking of decode tokens by long prefills.
- **Per-phase parallelism co-optimization**: independently searches TP/PP configuration for each phase (prefill typically favors TP for latency; decode favors larger batch + PP for throughput).
- **Bandwidth-aware placement**: chooses prefill/decode instance colocation (same node vs across nodes) based on NVLink/PCIe/IB bandwidth to keep KV-cache handoff off the critical path.

## Baselines

- vLLM (continuous batching, colocated P+D)
- DeepSpeed-MII / DeepSpeed-FastGen
- (Ablations against colocated-DistServe to isolate the disaggregation win)

## Evaluation setup (brief)

- Models: OPT-13B, OPT-66B, OPT-175B (representative dense LLMs).
- Workloads: ShareGPT (chat), HumanEval (code), LongBench (long context) — trace-driven, Poisson arrivals at varied rates.
- Hardware: multi-node A100 clusters with NVLink intra-node and IB inter-node.
- Metric: goodput = req/s meeting both TTFT and TPOT SLOs on ≥90% of requests.

## Relevance to survey (cluster 5.6)

- Baseline for SLOs-Serve and other SLO-aware serving papers — SLOs-Serve reports ~2.6× goodput over DistServe on bursty mixed workloads.
- Establishes prefill and decode as **separately provisionable resources**, which changes the admission-planning model: an admission controller must now track two capacity envelopes (prefill compute headroom, decode KV-cache/memory-bandwidth headroom) rather than one.
- The 2.6× gap over DistServe under bursty workloads stems from DistServe's **static** prefill:decode split — sized for an assumed traffic mix, it wastes capacity when the mix drifts (e.g., a burst of long prompts starves decode; a burst of long generations starves prefill). SLOs-Serve's dynamic reallocation + admission-aware scheduling absorbs those swings.
- Cited as motivation for treating P/D as separate admission surfaces in the survey's disaggregation subsection.
