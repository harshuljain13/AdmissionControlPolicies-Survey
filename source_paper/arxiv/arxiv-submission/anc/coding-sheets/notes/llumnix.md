# Llumnix: Dynamic Scheduling for Large Language Model Serving

- **Full title:** Llumnix: Dynamic Scheduling for Large Language Model Serving
- **Authors:** Biao Sun, Ziming Huang, Hanyu Zhao, Wencong Xiao, Xinyi Zhang, Yong Li, Wei Lin (Alibaba Group)
- **Venue:** OSDI '24 (18th USENIX Symposium on Operating Systems Design and Implementation)
- **Links:**
  - USENIX page: https://www.usenix.org/conference/osdi24/presentation/sun-biao
  - arXiv: https://arxiv.org/abs/2406.03243
- **Code:** https://github.com/AlibabaPAI/llumnix
- **Fetched:** 2026-09-10
- **Tier:** 4 (admission-adjacent)

## Abstract

LLM serving requests are heterogeneous in input/output lengths, latency
requirements, and priorities, and their execution is unpredictable due to
autoregressive generation. Static, one-shot scheduling of requests onto model
instances leads to load imbalance, memory fragmentation, priority inversion,
and SLO violations. Llumnix reschedules requests across multiple model
instances at runtime, analogous to context switching in operating systems.
The core enabler is a **live migration mechanism for requests and their
in-memory (KV cache) states** that is near-zero downtime. A dynamic scheduling
policy uses migration to unify load balancing, defragmentation, priority
differentiation, and SLO-aware placement. On top of vLLM-class backends,
Llumnix reports order-of-magnitude tail-latency improvements, ~1.5x speedup
for high-priority requests, and up to ~36% cost reduction at matched SLO
attainment vs. SOTA baselines.

## Admission-adjacent component?

**No explicit admission control.** Llumnix does not reject, defer, or gate
incoming requests based on load, SLO feasibility, or capacity. Every arriving
request is admitted and placed on some instance; the novelty is that after
admission, requests (and their KV state) can be **migrated** between
instances to rebalance load, defragment memory, isolate priorities, and chase
SLOs.

Why it still shows up in an admission-control survey: Llumnix occupies the
same design point as admission — "what do you do when the cluster is
saturated and SLOs are at risk?" — but answers it with **migration + dynamic
rescheduling** instead of **rejection/deferral**. Cluster-level admission
controllers (SOLA, SLOs-Serve, QLM-style) frequently cite Llumnix as the
strongest migration-based alternative and as a SOTA scheduling baseline.
Migration and admission are complementary: an admission controller decides
*whether* to accept; Llumnix decides *where* an already-accepted request
should live over time.

## Contribution

- **Live KV-cache migration with near-zero downtime.** Uses a pipelined
  copy of KV blocks from source to destination instance overlapped with
  ongoing decode on the source, then a very short stop-and-switch. Migration
  cost is effectively hidden from the migrated request's TBT.
- **Unified dynamic-scheduling policy over migration primitive.** A single
  virtual-load abstraction (accounting for queued + running + priority
  headroom) drives load balancing, memory-fragmentation repair, priority
  isolation, and auto-scaling decisions — all realized via migrate/spawn
  actions rather than admission or preemption.
- **Priority + SLO differentiation without partitioning.** High-priority
  requests are migrated onto lightly loaded instances on demand, so
  low-priority traffic still uses the same fleet without hard reservations,
  yielding ~1.5x speedup for high-priority and ~36% cost savings at matched
  SLO.

## Baselines

- **vLLM** (PagedAttention, continuous batching) — same-instance scheduling
  baseline.
- **INFaaS-style / round-robin and least-loaded cluster schedulers** —
  static placement baselines (no migration).
- Ablations against Llumnix-without-migration to isolate the value of the
  migration mechanism vs. the policy.

## Evaluation setup (brief)

- **Models:** LLaMA-class (7B, 30B, 65B) on multi-GPU nodes; tensor
  parallelism within instance, data parallelism across instances.
- **Cluster:** Multi-node A100 setup with tens of model instances.
- **Workloads:** ShareGPT-derived traces plus synthetic bursty/long-tail
  traces; mixed-priority workloads.
- **Metrics:** P99 TTFT, P99 TBT, SLO attainment, cost at matched SLO,
  high-priority speedup, fragmentation.
- **Headline results:** order-of-magnitude P99 improvements over static
  scheduling; ~1.5x priority speedup; up to ~36% cost reduction.

## Relevance to survey (Cluster 5.6 — cluster scheduling & migration)

Llumnix is the canonical **migration-based** point in the admission /
scheduling design space, and is the most-cited "SOTA cluster scheduling"
baseline in the papers this survey centers on:

- **SOLA** cites Llumnix as the SOTA migration baseline it must beat on SLO
  attainment while also doing explicit admission.
- **SLOs-Serve** cites Llumnix as the SOTA dynamic-scheduling baseline and
  positions its SLO-aware admission as complementary to Llumnix-style
  migration.
- **QLM / priority-queueing admission** papers use Llumnix as the "no
  admission, migrate instead" contrast.

For §5.6 the framing is: **admission and migration are dual mechanisms** for
the same overload problem. Llumnix shows how far migration alone can go;
SOLA and SLOs-Serve show why admission is still needed once migration
saturates (nowhere left to migrate to). A layered controller
(admission-in-front-of-Llumnix) is a natural open direction the survey
should call out.
