# VTC — Fairness in Serving LLMs

**Full title**: Fairness in Serving Large Language Models
**Authors**: Ying Sheng, Shiyi Cao, Dacheng Li, Banghua Zhu, Zhuohan Li, Danyang Zhuo, Joseph E. Gonzalez, Ion Stoica (UC Berkeley + others)
**Venue**: **OSDI '24** (18th USENIX Symposium on Operating Systems Design and Implementation)
**Links**: [USENIX OSDI 24 program](https://www.usenix.org/conference/osdi24/presentation/sheng) · [arXiv:2401.00588](https://arxiv.org/abs/2401.00588)
**Code**: https://github.com/Ying1123/VTC-artifact (artifact-evaluated)
**Fetched**: 2026-09-10

## Abstract
High-demand LLM inference services (ChatGPT, Bard) serve requests of wildly varying input/output lengths. Existing services rely on per-client request-rate limits to prevent any one client from dominating the queue, but this rudimentary fairness under-utilizes capacity when the system has slack. The authors formalize LLM-serving fairness through a cost function over tokens processed (not requests), then introduce **Virtual Token Counter (VTC)**, a work-conserving fair scheduler layered on top of continuous batching. They prove a **2× tight upper bound** on the service-difference between any two backlogged clients and empirically show VTC dominates FCFS and RPM baselines on both synthetic and Chatbot Arena traces.

## Taxonomy placement
- Unit of admission: **tenant** (client/user)
- Setting: **online serving**
- SLO-awareness: **fairness-oriented** (token-level fairness across users)
- Signal used: Virtual Token Counter (VTC) per client

## Contribution (deep-read summary — Day 4)
- **Formal fairness definition for LLM serving**: cost = weighted sum of input/output tokens, `W = w_p·n_p + w_q·n_q` (defaults `w_p=1, w_q=2`, matching OpenAI's 1:2 input:output pricing). Replaces request-count fairness, which is meaningless when a 1k-token prompt costs 100× a 10-token prompt.
- **VTC algorithm**: maintain per-client virtual counter of tokens served; at each continuous-batching step, prioritize the *least-served* backlogged client. Counter updates every generated token, so no length-prediction is required.
- **Counter lift for arrivals**: when an idle client returns, its counter is *lifted* to `max(own, min over active clients)`. This prevents an absent client from banking credit and then bursting to unfairly dominate later — credits do not accumulate.
- **Theoretical guarantee**: for any two continuously-backlogged clients f, g, `|W_f − W_g| ≤ 2·max(w_p·L_input, w_q·M)` where M is the max batch size. A matching lower bound of `w_q·M` proves the 2× factor is tight.
- **Variants**: weighted VTC (per-tenant weights → weighted max-min), VTC(predict) (uses last-5-requests length estimate), VTC(oracle) (perfect length knowledge; tightens counter-lift heuristics).

## Baselines
- **FCFS** — first-come-first-serve on the request queue (default in most engines).
- **RPM(k)** — request-per-minute rate limit, k ∈ {5, ...}; the industry-standard "fairness".
- **LCF (Least-Counter-First)** — VTC ablation without the counter-lift step (shows lift is what prevents burst-after-idle unfairness).
- **VTC(predict)** and **VTC(oracle)** — length-prediction variants, used to bound the value of knowing output length.

## Evaluation setup
- Model(s): **Llama-2-7B** and **Llama-2-13B**.
- Engine: **S-LoRA** (built on LightLLM), continuous batching + PagedAttention.
- Hardware: **A10G (24 GB)** for 7B, **A100 (80 GB)** for 13B. KV pool 10k tokens (7B) / 35–65k (13B).
- Workload:
  - *Synthetic*: constant, ON/OFF, and Poisson arrivals with variable in/out lengths in [64, 768].
  - *Real*: **27 clients** replayed from **LMSYS Chatbot Arena traces**, 10-minute window, 210 req/min system-wide. Input avg 136 tok (max 1021), output avg 256 tok (max 977).
- Metrics:
  - **Service difference** = `min(|W_f − W_g|, |lower_service − arrival_demand|)` — max and average across client pairs.
  - System throughput (tokens/sec).
  - Fairness under adversarial burst / idle-and-return patterns.

## Claimed headline numbers
- **Real-workload (27 Arena clients, Llama-2-13B)**:
  - VTC: **max service diff 368**, avg 252, throughput **779 tok/s**.
  - FCFS: max diff 760 (**~2× worse fairness**), avg 434, throughput 777 tok/s (VTC is *work-conserving* — no throughput loss).
  - RPM(5): max diff 144 (fair) but throughput collapses to **340 tok/s** (~56% degradation) — the classic under-utilization symptom.
- **Theoretical**: `|W_f − W_g| ≤ 2·max(w_p·L_input, w_q·M)` for backlogged clients; lower bound `w_q·M` proves the 2× constant is tight.
- LCF (no counter lift) fails on ON/OFF adversarial traces: returning idle clients over-consume until their counter catches up.

## Fidelity / reproducibility
- **Code released**: https://github.com/Ying1123/VTC-artifact — OSDI '24 artifact-evaluated. Includes S-LoRA integration, all baselines, synthetic + Arena trace replays, and plotting scripts.
- Workload traces (Arena subset) reproducible; models are open Llama-2 weights. Hardware (A10G/A100) is commonly available.
- High fidelity — one of the cleaner OSDI systems artifacts to reproduce.

## Relevance to survey
Anchor paper for the fairness cluster (5.3). First formal treatment of client-level fairness in LLM serving. Load-bearing for Open Problem 6 (multi-tenant admission with per-tenant SLOs) and Problem 18 (soft-admission decline transparency).

## Open questions surfaced
- **Token-throughput fairness ≠ SLO fairness.** VTC equalizes served tokens, not per-request latency or TTFT. A tenant with strict TTFT SLO and one with batch-tolerant workload receive the "same" service but experience wildly different QoS. Open Problem 6 (per-tenant SLO fairness) is **not** solved by VTC.
- **Prefix locality ignored.** Follow-up DLPM (arXiv 2501.14312) reports up to **2.87× higher throughput** than VTC by co-optimizing prefix-cache hits and fairness — VTC's least-served-first can shatter KV reuse.
- **Abuse vs. equality.** Multi-agent workloads (arXiv 2411.15997) argue equal-TPM treatment protects abusive agents; fairness may need reputation/priority tiers, not just weights.
- **Counter-lift heuristic is one of many.** No exploration of decay, EWMA, or budget-based alternatives — likely a fertile design space for tenant-SLO-aware admission (my Problem 6 angle).
- **No explicit admission-control**: VTC is a *scheduler*, not an *admission gate*. It never says "no" — it just reorders. How VTC composes with a soft-decline admission layer (Problem 18) is unaddressed.
