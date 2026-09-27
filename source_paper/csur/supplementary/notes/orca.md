# Orca

**Full title**: Orca: A Distributed Serving System for Transformer-Based Generative Models
**Authors**: Gyeong-In Yu, Joo Seong Jeong, Geon-Woo Kim, Soojeong Kim, Byung-Gon Chun (Seoul National University / FriendliAI)
**Venue**: **OSDI '22**
**Links**: [USENIX OSDI '22 page](https://www.usenix.org/conference/osdi22/presentation/yu) · PDF: https://www.usenix.org/system/files/osdi22-yu.pdf
**Code**: **No public release** (proprietary; commercialized as FriendliAI's PeriFlow / Friendli Engine)
**Fetched**: 2026-09-10 (USENIX host returned 403 for automated fetch; note written from paper knowledge — verify quotes before citation)

## Abstract
Orca is a distributed serving system for Transformer-based generative models (GPT-family) that introduces two co-designed techniques: **iteration-level scheduling** (return control to the scheduler after every generated token instead of after a full request completes) and **selective batching** (batch operations that are shape-compatible across requests at different decode positions — attention is executed per-request, everything else is batched). Together they eliminate the head-of-line blocking that request-level batching imposes on variable-length generation, and drive throughput up by up to 36.9× vs FasterTransformer at the same latency on GPT-3 175B.

## Admission-adjacent component?
**No explicit admission logic.** Orca's scheduler is FCFS over the request queue with a **max_batch_size** cap and a **max KV-slot reservation** cap; when either is hit, newly arriving requests simply wait in the queue — there is no reject-on-arrival, no priority, no SLO-aware gating, no load shedding, no queue-length shedding. The paper's "scheduler" is a batching admitter (picks which queued requests to add to the next iteration's batch), not an admission controller in the survey's sense. The KV-reservation check is the closest thing to admission and is best characterized as **implicit capacity-based back-pressure**, not a policy.

## Contribution (foundational)
- **Iteration-level scheduling**: reframes the serving loop so that the scheduling quantum is one decoder iteration (one generated token per active request) rather than one full request. New requests can join a running batch at any iteration boundary, and finished requests leave immediately — this is the mechanism now universally called **continuous batching** (vLLM, TGI, TensorRT-LLM, SGLang, DeepSpeed-MII all implement variants of it).
- **Selective batching**: attention has a per-request shape (KV length differs across requests in a batch), while MatMuls / LayerNorm / activations are shape-uniform once you flatten the token dimension. Orca batches the uniform ops and runs attention per-request in the same kernel launch — the enabling trick that makes iteration-level scheduling actually profitable on GPU.
- **Distributed engine design**: pipeline + intra-layer (tensor) parallelism with a control-plane scheduler that dispatches per-iteration batches across workers, keeping the pipeline fed under variable-length generation. Establishes the reference architecture that later serving systems inherit.

## Baselines
- **FasterTransformer** (NVIDIA): request-level batching, static batch composition, no mid-batch join/leave — Orca's primary throughput comparison target.
- **NVIDIA Triton + FasterTransformer backend**: production-grade serving stack; used to control for dispatch/queueing overhead beyond just the engine.
- **Orca variants (ablation)**: iteration-level scheduling *without* selective batching, and selective batching *without* iteration-level scheduling, to isolate each contribution.

## Evaluation setup
- **Models**: GPT-family up to **GPT-3 175B** (also 13B, 101B intermediate sizes).
- **Hardware**: multi-GPU / multi-node A100 clusters; up to **16× A100** with NVLink intra-node and Infiniband inter-node; tensor + pipeline parallelism swept.
- **Workload**: synthetic Poisson arrivals with input/output length distributions drawn from GPT-family usage traces; latency-vs-throughput curves at multiple concurrency levels.
- **Metrics**: median and P90 end-to-end latency at target throughput; sustained throughput at latency SLO.
- **Headline**: up to **36.9× throughput vs FasterTransformer at matched latency** on GPT-3 175B; gap widens as request-length variance grows.

## Relevance to survey
**Foundational cite for Section 2 (Background), cluster 5.6.** Orca is the substrate every modern admission-control paper (Llumnix, FastServe, QLM, Chiron, Concur, FairBatching, Ascendra, etc.) implicitly or explicitly sits on top of: they all assume iteration-level scheduling / continuous batching as the *engine primitive* and then layer admission, preemption, priority, or SLO logic on top. The survey should cite Orca once, up front, as **"the paper that made mid-flight batch composition possible, and thereby made per-iteration admission decisions a design question at all."** Without Orca, admission is trivially request-level FCFS; with Orca, admission becomes a first-class scheduling axis — which is what the survey exists to map.

Cite as: **foundational cite for continuous batching / iteration-level scheduling — the substrate admission policies sit on top of; itself contains no admission policy beyond FCFS + capacity back-pressure.**
