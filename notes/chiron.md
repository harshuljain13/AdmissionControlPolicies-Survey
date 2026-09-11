# Chiron

**Full title**: Hierarchical Autoscaling for Large Language Model Serving with Chiron
**Authors**: Archit Patke, Dhemath Reddy, Saurabh Jha, Chandra Narayanaswami, Zbigniew Kalbarczyk, Ravishankar K. Iyer
**Venue**: arXiv preprint (cs.DC / cs.AI), Jan 2025 — no peer-reviewed venue yet; same DEPEND@UIUC + IBM group as QLM (SoCC '24)
**Links**: arXiv:2501.08090 — https://arxiv.org/abs/2501.08090
**Code**: not released as of fetch date
**Fetched**: 2026-09-10

## Abstract
LLM serving workloads mix interactive requests with strict SLOs (seconds) and batch requests with relaxed SLOs (minutes–hours). Existing autoscalers ignore per-request SLOs and either over-provision or violate deadlines. Chiron proposes a hierarchical autoscaler that combines backpressure signals from queue size, GPU utilization, and SLO slack to jointly decide (a) how many instances to run and (b) how each instance batches requests. Reports up to 90% higher SLO attainment and up to 70% better GPU efficiency versus prior autoscalers.

## Taxonomy placement
- **Autoscaling-primary, admission-adjacent**: Chiron does not reject requests. It absorbs load by scaling replica counts and re-partitioning capacity between interactive- and batch-typed instances; the effective "admission" boundary is deadline-aware queue draining rather than gate-keeping.
- Unit of decision: **replica** (global) + **batch size** (local)
- Setting: **online serving, mixed interactive+batch**
- SLO-awareness: yes — TTFT and ITL targets drive scaling triggers
- Signal used: queue depth, waiting-time-to-deadline, GPU utilization (EWMA-smoothed)

## Contribution (3–5 bullets on the hierarchical autoscaling mechanism)
- **Two-level hierarchy**. *Local autoscaler* (per-instance) tunes batch size via latency- and throughput-based backpressure: halves batch when backpressure > 1, grows it with EWMA smoothing otherwise. *Global autoscaler* (cluster) adjusts instance count and instance *type* (interactive / batch / mixed) using separate interactive vs batch backpressure signals.
- **Deadline-driven batch scaling**. New batch instances are spun up when queued batch requests' predicted waiting time approaches their TTFT deadline (hours-scale), not when queue length crosses a static threshold — decouples scaling from raw queue size.
- **Over-provisioning ratio Θ=1/3 for interactive spikes**. Global autoscaler holds ~33% headroom on interactive-typed instances so bursts don't have to wait on cold-start, trading a bounded amount of GPU idle time for tail-TTFT protection.
- **Preemptible multiplexing on mixed instances**. Interactive requests can evict batch requests co-located on mixed instances; evicted KV cache is migrated to CPU for cheap resume — a soft admission mechanism (batch requests are *paused*, not dropped) that lets one pool absorb both classes.
- **Type-aware routing**. Requests preferentially route to instances of matching type (interactive→interactive-only, batch→batch-only); mixed instances are fallback capacity, which makes the routing layer autoscaling-aware without a separate scheduler.

## Baselines
- **Llumnix** (SOTA LLM orchestrator built on vLLM) — default configuration
- **Llumnix (tuned)** — parameter-swept per-workload variant, to remove "unfair defaults" objection

## Evaluation setup
- **Hardware**: NVIDIA A100 80 GB, cluster cap of 50 GPUs
- **Models**: Llama 3.1 8B and 70B; prefix caching + speculative decoding (8B used as draft for 70B)
- **Workloads**: ShareGPT-derived traces, 3,500 requests each, Poisson arrivals
  - **WA**: interactive-only, TTFT SLO = 10 s, ITL = 200 ms
  - **WB**: mixed interactive + batch, batch TTFT SLO = 1 h, ITL = 2 s
- **Metrics**: SLO attainment (%), GPU efficiency (utilization / cost), instance count over time

## Claimed numbers
- **Up to 90% higher SLO attainment** vs Llumnix on mixed WB workload
- **Up to 70% better GPU efficiency** (fewer GPU-hours to serve the same trace at target SLO)
- Effects are most pronounced on WB (mixed) — WA (interactive-only) gap is smaller, consistent with the mechanism's value being *class-aware* rather than pure scaling

## Fidelity / reproducibility
- No code release, so parameter defaults (Θ=1/3, EWMA half-life, backpressure thresholds) are trust-me numbers
- Single-cluster, single-tenant, single-model-family evaluation; no multi-tenant contention or heterogeneous GPU pool
- Trace-driven but derived from ShareGPT — realistic distributions but not production arrival bursts
- Baselines limited to Llumnix; no comparison against pure HPA/KEDA-style k8s autoscalers or against QLM (their own prior work), which is a notable omission given the hierarchy framing

## Relevance to survey
- **Cluster 5.6 (autoscaling / elasticity)** with strong adjacency to **5.1 (admission control)**. Chiron is the load-bearing citation for **Open Problem 7 (coupling admission + autoscaling + routing)**: it demonstrates that once autoscaling is SLO-aware, the "admission" question partially dissolves — you rarely need to reject if you can (a) shift a request to a batch pool, (b) preempt-and-page it, or (c) spin up before the deadline fires. This reframes admission control as *the residual* after autoscaling and routing have done their work.
- Pairs naturally with QLM (Patke et al., SoCC '24) from the same group: **QLM does per-replica SLO-aware queueing and reordering; Chiron does inter-replica elasticity and class partitioning**. Composition story: QLM decides *which queued request runs next on a given replica*; Chiron decides *how many replicas of which type exist*. Neither alone handles the third axis — request routing across a heterogeneous replica set — which is exactly where Open Problem 7 lives.

## Open questions surfaced
- **Composition with QLM is asserted-not-shown**: no paper co-evaluates QLM's per-replica queue with Chiron's global autoscaler. Does QLM's reordering interact adversarially with Chiron's deadline-based scaling trigger (e.g., QLM keeps deadline slack healthy → Chiron never scales → tail explodes on a burst)?
- **Θ=1/3 headroom is a magic number**. No sensitivity analysis vs arrival burstiness (CoV of interarrival). In heavier-tailed traces this over-provision could dominate cost.
- **Cold-start is elided**. "Spin up a batch instance when deadline approaches" assumes provisioning latency ≪ deadline slack, which holds for hour-scale batch but not for the seconds-scale interactive SLOs — the paper sidesteps this by pre-provisioning interactive capacity.
- **No admission-reject path**. Under sustained overload where even mixed instances saturate, Chiron has no described fallback other than SLO violation. A survey-relevant question: at what load factor does an autoscaling-only design *require* an admission gate to preserve tail behavior?
- **NEW OPEN PROBLEM candidate**: *Autoscaling-aware routing under class asymmetry*. Chiron classifies instances (interactive/batch/mixed) but the routing policy is a static "preferential" rule. No work I've catalogued jointly optimizes (instance type mix, routing weights, per-replica queue policy) — this is a distinct sub-problem inside Open Problem 7 that deserves its own callout in the survey.
- **Reproducibility**: without code, the 90%/70% numbers cannot be independently regressed as vLLM/Llumnix evolve. Worth flagging in the survey's evidence-quality column.
