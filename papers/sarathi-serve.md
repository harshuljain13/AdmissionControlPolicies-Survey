# Sarathi-Serve

- **Full title**: Taming Throughput-Latency Tradeoff in LLM Inference with Sarathi-Serve
- **Authors**: Amey Agrawal, Nitin Kedia, Ashish Panwar, Jayashree Mohan, Nipun Kwatra, Bhargav S. Gulavani, Alexey Tumanov, Ramachandran Ramjee
- **Venue**: OSDI '24 (USENIX)
- **Links**: [USENIX page](https://www.usenix.org/conference/osdi24/presentation/agrawal-amey) · [arXiv:2403.02310](https://arxiv.org/abs/2403.02310)
- **Code**: https://github.com/microsoft/sarathi-serve
- **Fetched**: 2026-09-10
- **Tier**: 4 (admission-adjacent)

## Abstract

LLM inference interleaves two phases with opposing profiles: prefill is compute-bound and latency-heavy but GPU-efficient, while decode is memory-bandwidth-bound with poor compute utilization. Batching improves decode throughput but forces an unpleasant tradeoff — either prioritize prefill (hurting decode TBT/tail latency via "generation stalls") or prioritize decode (hurting TTFT and throughput). Sarathi-Serve introduces *chunked prefill* — splitting a prefill request into near-equal token chunks — combined with *stall-free scheduling* to construct hybrid batches that piggyback new prefill chunks onto ongoing decode iterations without stalling them. This yields uniform iteration times, larger effective batches, and up to 2.6x (Mistral-7B, single A100), 3.7x (Yi-34B, 2xA100 TP), and 5.6x (Falcon-180B, pipeline-parallel) higher serving capacity within a TBT SLO vs vLLM/Orca.

## Admission-adjacent component?

**No — Sarathi-Serve has no explicit admission control (no accept/reject, no SLO-conditioned queue gating).** The scheduler operates purely at the batching layer: it decides *which* in-flight requests (and which prefill chunks) to co-schedule inside a hybrid batch, constrained by a token budget derived from the target TBT SLO. New requests are enqueued unconditionally; the token-budget knob only limits *how many* new prefill chunks are pulled into the current iteration. This is a batching / iteration-composition policy, not admission. The closest admission-adjacent behavior is the implicit backpressure created when the chunk size and token budget force new prefills to wait — but there is no rejection, no deadline check, no load-shedding, and no priority-aware queue.

## Contribution (chunked-prefill mechanism)

- **Chunked prefill**: split a prompt's prefill into fixed-size token chunks so that a single prefill request no longer monopolizes an iteration; each chunk can be co-scheduled with decodes of other requests.
- **Stall-free (hybrid) batching**: pack a decode-heavy batch with a prefill chunk sized to fit a per-iteration token budget, so ongoing decodes never stall and TBT stays within SLO.
- **Uniform iteration time under TP/PP**: because iterations carry comparable token loads, pipeline bubbles and tail-latency spikes from mixed prefill/decode iterations shrink dramatically, unlocking larger effective batches.

## Baselines

- vLLM (continuous batching, prefill-prioritizing)
- Orca (iteration-level scheduling)
- FasterTransformer-style request-level batching (referenced for context)

## Evaluation setup

- **Models**: Mistral-7B, Yi-34B, Falcon-180B (LLaMA family referenced)
- **Hardware**: A100 (single-GPU, 2xA100 TP, multi-node PP for 180B)
- **Engine**: custom serving stack (open-sourced as sarathi-serve, PagedAttention-compatible)
- **Workload**: synthetic Poisson arrivals with prompt/decode length distributions from real traces (openchat, arxiv-summarization); SLO defined on TBT (P99) and TTFT
- **Metric**: *serving capacity* = max QPS sustaining SLO

## Relevance to survey (Cluster 5.6 — scheduling with admission component)

Cited as a **throughput/latency anchor** in Cluster 5.6: Sarathi-Serve is the state-of-the-art *pure batching* baseline. Its explicit non-adoption of admission control makes it the natural foil for admission-aware schedulers (FairBatching, Llumnix's migration+admission, QLM). Any admission scheme that claims to preserve throughput needs to show it does not regress against Sarathi-Serve's chunked-prefill capacity gains. Also useful as: (a) the assumed underlying batching layer that admission logic sits *on top of* in several later systems; (b) evidence that a lot of latency pathology attributed to "no admission" is actually solvable via batching alone — sharpening what admission must uniquely deliver (fairness, deadline guarantees, priority, cost/SLO tiers).

## Open questions (admission-relevant)

- Under Sarathi-Serve's token-budget scheduler, does implicit queue backpressure become unbounded under sustained overload? (paper evaluates within-SLO capacity, not overload behavior — the regime where admission control matters most.)
- Can the token-budget knob be repurposed as an admission signal (e.g., reject or defer when queued token-debt exceeds a threshold)?

---

## Return summary

Sarathi-Serve has **no explicit admission logic** — no accept/reject, no queue gating, no SLO-conditioned deferral. It is a pure batching/scheduling system: chunked prefill + stall-free hybrid batches under a per-iteration token budget derived from a TBT SLO. New requests are always enqueued; the only "control" is which chunks join the current iteration. **Cite as**: (i) baseline for FairBatching (throughput/latency parity check), (ii) throughput anchor showing how much latency pathology batching alone can resolve, sharpening the unique value proposition of admission control (fairness, deadlines, priority tiers).
