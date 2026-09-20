# Aegaeon

**Full title**: Aegaeon: Effective GPU Pooling for Concurrent LLM Serving on the Market
**Authors**: Yuxing Xiang, Xue Li, Kun Qian, Yufan Yang, Diwen Zhu, Wenyuan Yu, Ennan Zhai, Xuanzhe Liu, Xin Jin, Jingren Zhou (Alibaba Cloud + Peking University)
**Venue**: SOSP '25 (ACM SIGOPS 31st Symposium on Operating Systems Principles), Seoul, Oct 2025 — pp. 1030–1045
**Links**: ACM DL https://dl.acm.org/doi/10.1145/3731569.3764815 · PDF https://ennanzhai.github.io/pub/sosp25-aegaeon.pdf
**Code**: not released as of fetch date
**Fetched**: 2026-09-10

## Abstract (reconstructed from ACM listing + Alibaba blog; PDF text extraction failed)
Cloud model marketplaces (Alibaba's Model Studio, HF Inference Endpoints, Bedrock Marketplace) must concurrently serve *tens to hundreds* of LLMs whose per-model request rates are highly skewed and bursty — the reported production trace has arrival rates spanning 0.01–1.13 rps with a mean of 0.037. Dedicating GPUs per model wastes capacity; naive multi-tenant packing incurs prohibitive model-switching cost. Aegaeon proposes **token-level auto-scaling**: the scheduler can swap the resident model *between individual token generations* on a shared GPU, treating the GPU as a pool that virtualizes across many models. To make this viable, Aegaeon reduces model-switch overhead by ~97% via component reuse, explicit memory management, and fine-grained KV-cache synchronization. Deployed in Model Studio for 3+ months, it serves 47 models (1.8B–72B) on 213 H20 GPUs versus 1,192 previously — an 82% GPU reduction — and sustains 2–2.5× higher request arrival rates or 1.5–9× higher goodput than baselines.

## Taxonomy placement
- **Multi-model serving / autoscaling-primary, admission-adjacent (weak)**. Aegaeon's headline lever is *token-granularity model swap on shared GPUs*, not admission gating. Whether it also has an explicit reject-or-queue admission path could not be verified from available sources (PDF binary was not text-extractable; blog is high-level). Best inference from the design: SLO/goodput regulation is via *swap scheduling* and *pooling capacity*, not request rejection.
- Unit of decision: **token** (which model owns the next forward pass) + **GPU pool membership** (which models are warm)
- Setting: **multi-model marketplace serving, heavy skew across models**
- SLO-awareness: yes — per-token scheduling explicitly optimizes goodput under per-model SLOs
- Signal used: per-model queue state, KV-cache residency, model-switch cost

## "On the market" — what it means
Not spot/preemptible instances. "On the market" refers to the **model marketplace** setting (Model Studio hosts many third-party and first-party LLMs, each with low individual traffic). The economic problem is *long-tail model catalog*, not preemptible hardware. This distinguishes Aegaeon from spot-aware systems (SpotServe, etc.) — no evidence of preemption-aware admission decisions in the paper.

## Contribution (per available sources)
- **Token-level model auto-scaling**. Prior multi-model systems (MuxServe, dLoRA, Prism) scale at request or batch granularity; Aegaeon can decide *after every generated token* which model runs next on a given GPU, enabling fine interleaving of dozens of active models within one forward-pass cadence.
- **97% switch-overhead reduction**. Component reuse (shared runtime state across model instances), explicit memory management (bypassing PyTorch allocator for model weights), and fine-grained KV-cache synchronization make sub-token-boundary swaps feasible — this is the enabling systems contribution without which token-level scheduling is a nonstarter.
- **Production evidence at cloud scale**. 213 H20 GPUs replacing 1,192 for 47 models (1.8–72B, mixed TP=1 and TP=4), up to 7 models per GPU, 3+ months in beta on Model Studio — the largest published multi-model consolidation result to date.

## Baselines
- Not extractable from PDF; blog claims comparisons to "existing mainstream systems" without naming them. Given the multi-model framing and 1.5–9× goodput claim, likely candidates are **MuxServe** (OSDI '24), **dLoRA** (OSDI '24), and possibly **vLLM** single-model baseline as a lower bound. **To verify against paper §6.**

## Evaluation setup (partial)
- **Hardware**: NVIDIA H20 GPUs; production cluster of 213 (cross-region), plus (presumed) smaller testbed for controlled experiments
- **Models**: 1.8B–72B parameter LLMs; TP=1 for small, TP=4 for large; 28 small + 19 large in production
- **Workloads**: real Model Studio arrival trace (arrival rates 0.01–1.13, mean 0.037) plus (presumed) synthetic sweeps
- **Metrics**: goodput, sustained arrival rate at SLO, GPU count for fixed workload, model-switch overhead
- **Details missing from summary sources**: exact SLO thresholds (TTFT/TPOT), synthetic workload construction, per-baseline configuration

## Claimed numbers
- **82% GPU reduction** in production (1,192 → 213) for a fixed model catalog
- **2–2.5× higher sustainable arrival rate** vs baselines
- **1.5–9× higher goodput** vs baselines
- **97% reduction in model-switch overhead** vs a naive implementation of the same swap primitive

## Fidelity / reproducibility
- No code release; production cluster claims are not independently reproducible
- ~~PDF text extraction failed on the ennanzhai.github.io mirror~~ — **resolved 2026-09-20**, full text extracted; presence/absence of admission gating is now verified (see below). Baselines and exact SLO thresholds remain from the ACM listing and are not quoted in the survey.
- Production trace is Alibaba-proprietary; the 0.01–1.13 rps range and 0.037 mean are the only characteristics disclosed

## Relevance to survey
- **Cluster 5.6 (multi-model serving / autoscaling)** with weak adjacency to **5.1 (admission control)**. Aegaeon extends the autoscaling axis by pushing the decision granularity from *replica* (Chiron) or *batch* (MuxServe) down to *token*. This is the finest-granularity autoscaling knob in the literature and sets a lower bound on what "per-token" can mean in the survey's granularity taxonomy.
- **Pairs with Chiron** on the granularity spectrum: Chiron autoscales replicas at seconds-to-minutes with class partitioning; Aegaeon autoscales *which model is resident on a GPU* at token cadence. Neither rejects requests — both are load-response levers that *dissolve* the admission problem via elasticity. Aegaeon strengthens the survey's Open Problem 7 framing: if you can swap models per-token, the residual admission question is even smaller than Chiron implied.
- **Contrast with market-focused admission work** (Concur, FairBatching): those gate by tenant/deadline; Aegaeon gates by *nothing* and instead makes the shared pool cheaper. Interesting axis to callout — "admission by elasticity" as an alternative to "admission by gate."

## Open questions surfaced
- ~~**Does Aegaeon ever refuse or queue-drop a request?**~~ **CLOSED 2026-09-20** — no. See the verification section above.
- **Token-swap cost floor**. 97% reduction is impressive but the *absolute* switch cost per token (µs? tens of µs?) sets the ceiling on how many models can coexist. Not reported in summaries.
- **Interaction with continuous batching**. Standard vLLM-style continuous batching assumes homogeneous model weights across the batch. Does Aegaeon serialize models per token (harming batch efficiency) or shard the forward pass? Mechanism detail matters for the survey's throughput analysis.
- **Fairness across models**. With per-model arrival rates spanning 100× (0.01 → 1.13), what prevents a high-rate model from monopolizing GPU cycles? Any weighted-fair scheduler? Blog is silent.
- **Applicability outside marketplaces**. Aegaeon's ROI depends on *long-tail low-utilization models*. A single high-QPS model gains nothing from token-level swap. Scope this carefully in the survey — do not overclaim generality.

## VERIFIED 2026-09-20 — second reading pass, full text

The PDF text layer extracted successfully this time (16 pages, complete
through references). The open question below is now closed.

**Aegaeon performs no admission control. The survey's "No" in Table 3 is correct.**

Term counts over the full text:

| term | count | what it actually refers to |
|---|---|---|
| admission, admit, reject, discard, defer | **0** | absent entirely |
| drop | 1 | "performance drop" under longer inputs, not request drop |
| refus | 1 | MuxServe's *placement optimizer* refusing to co-locate models |
| overload | 2 | both describe the problem (bursts overload reserved GPUs), never a response |
| queue | 10 | job queues for dispatch and batching |

Algorithm 1 (prefill dispatch) is decisive: on arrival of request r, Aegaeon either
appends r to an existing same-model group or creates a group on the **least loaded**
job queue. Every arrival is placed. There is no bounded queue length, no deadline
discard, and no return path that refuses service. SLO violations are addressed by a
weighted round-robin decoding scheduler that *minimises tokens violating TBT*, and
SLO attainment is defined as the percentage of token generation times meeting their
deadlines — a measurement of the outcome, not a gate on the input.

**On the third-party characterization.** FaaScale (MLSys 2026) describes Aegaeon as
optimizing "resource sharing, admission control, and request scheduling across
tenants." That is loose: nothing in Aegaeon's text supports the middle term. If a
reviewer raises it, the answer is the term counts and Algorithm 1 above.

This also confirms the note's original inference from the blog and ACM listing:
"admission by elasticity" rather than admission by gate.
