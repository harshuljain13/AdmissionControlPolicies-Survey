# FastServe

**Full title**: Fast Distributed Inference Serving for Large Language Models
**Authors**: Bingyang Wu, Yinmin Zhong, Zili Zhang, Shengyu Liu, Fangyue Liu, Yuanhang Sun, Gang Huang, Xuanzhe Liu, Xin Jin (Peking University)
**Venue**: **NSDI '26** (per USENIX conference page — verify final publication)
**Links**: arXiv:2305.05920 · [USENIX NSDI 26 program](https://www.usenix.org/conference/nsdi26/presentation/wu-bingyang) · GitHub: [LLMServe/FastServe](https://github.com/LLMServe/FastServe), mirror [MachineLearningSystem/NSDI26-FastServe](https://github.com/MachineLearningSystem/NSDI26-FastServe)
**Code**: **Yes** (Python + C++, on SwiftTransformer — not vLLM)
**Fetched**: 2026-09-10

## Abstract
Exploits autoregressive pattern to enable preemption at output-token granularity. Skip-join Multi-Level Feedback Queue scheduler + efficient GPU memory management + proactive KV offload. Up to 31.4× / 17.9× throughput vs vLLM under average / tail latency requirements.

## Taxonomy placement
- Unit of admission: **request** (with token-level preemption)
- Setting: **online serving**
- SLO-awareness: **deadline-aware** (average + tail)
- Signal used: multi-level queue position + estimated remaining work

## Contribution (deep-read summary — Days 2-6)
- **Skip-join MLFQ scheduler**: unlike vanilla MLFQ, arriving jobs are placed in the queue whose quantum best matches the measured cost of the first output token (prefill/first-decode), avoiding the head-of-line penalty that FCFS batching imposes on short jobs.
- **Token-granular preemption**: exploits autoregressive decoding boundaries so any decode iteration is a safe preemption point — no wasted compute on rollback, unlike request-level preemption or restart-on-preempt.
- **Proactive KV cache offload**: uses an Estimated Next Scheduled Time (ENST) heuristic to swap out KV tensors of low-priority jobs to host memory *before* GPU HBM saturates, and pre-fetches swap-ins for jobs about to be scheduled; PCIe transfers overlap with GPU decode kernels.
- **Aging / starvation control**: jobs whose starvation time exceeds threshold α (default 300 ms, tuned to SLO) are promoted back to the highest-priority queue, bounding tail latency for long generations.
- **Distributed extension**: pipeline + tensor parallel execution on multi-node A100 clusters with the scheduler co-designed to keep swap traffic off the critical path.

## Baselines
- **vLLM v0.1.7** (primary): iteration-level scheduling + PagedAttention, but FCFS with run-to-completion — no preemption of long jobs, so short jobs queue behind them.
- **FasterTransformer v5.3**: NVIDIA production engine; job-level (request-granularity) scheduling, no iteration-level batching or preemption.
- **FastServe-FCFS** (ablation): same SwiftTransformer engine + swap machinery, but FCFS scheduler — isolates the contribution of skip-join MLFQ from the engine improvements.

## Evaluation setup
- **Models**: OPT-13B (26 GB), OPT-66B (132 GB), OPT-175B (350 GB) — open-source GPT-3-scale.
- **Engine**: custom C++ (SwiftTransformer) — not vLLM or SGLang.
- **Hardware**: 2× AWS p4d.24xlarge (16× A100-40GB total, NVLink intra-node, PCIe 4.0 ×16 to 1152 GB host RAM per node).
- **Workload**: ShareGPT (real ChatGPT traces) + Alpaca (synthetic instruction-following). Poisson arrivals; sweep over request rate.
- **Metrics**: average per-token latency (E2E / output length), P95 tail latency, sustained throughput at SLO. SLO = 10× single-iteration decode latency ≈ 0.3 s.

## Claimed headline numbers
- **31.4× throughput vs vLLM at matched average latency SLO** — peak reported on **OPT-175B, 16× A100, ShareGPT workload**.
- **17.9× throughput vs vLLM at matched P95 tail latency SLO** — same OPT-175B / 16-GPU / ShareGPT config.
- Gains shrink for smaller models (OPT-13B) where KV pressure is lower and vLLM's FCFS is less punishing; ablation shows both skip-join MLFQ *and* proactive swap are needed — either alone leaves ~2–4× on the table.

## Fidelity / reproducibility
- **Code**: public, but built on **SwiftTransformer** (custom C++ kernels) — not vLLM or SGLang. README acknowledges "architecture design greatly inspired by vLLM" but ships no vLLM/SGLang backend.
- **Install path**: clone repo → conda env from `environment.yml` → build SwiftTransformer with CMake → pip install FastServe. Non-trivial C++ toolchain requirement.
- **Model support**: OPT + LLaMA2 families only.
- **Artifact eval**: `benchmarks/artifact-evaluation/` directory with its own README — good sign for NSDI AE process.
- **README quality**: minimal — features listed, build steps present, but API docs and config reference are thin.
- **Porting cost**: for AdmitBench Track 2, wiring the skip-join MLFQ + ENST swap policy into vLLM or SGLang would be a **substantial engine port** (multi-week), not a config change. This is the main reproducibility friction for the survey.

## Relevance to survey
Represents preemption-based admission approach — token-granular preemption as alternative to reject-on-arrival admission. Load-bearing for the "preemption vs admission" discussion in 5.6.

## Open questions surfaced
- **KV cache growth is the underlying pressure**: paper explicitly flags that as context length grows, KV memory becomes the binding constraint — swap-based mitigation has PCIe-bandwidth ceiling.
- **Starvation-vs-fairness tuning is manual**: α threshold (300 ms) is hand-tuned to SLO; no online adaptation.
- **Swap accounting under memory pressure**: authors report swap time <5% of E2E under their workloads, but degradation curve under adversarial (long-context, high-rate) traffic isn't characterized.
- **Model coverage narrow**: OPT-only evaluation; no LLaMA/Mixtral/MoE results in the paper (though repo now lists LLaMA2 support).
- **Burst handling relies on workload profiling**: idle-slot reservation policy is trained on historical arrivals — cold-start behavior on unseen traffic patterns is open.
- **No comparison to admission-control baselines** (e.g., Llumnix, S³, request-drop schemes) — the paper frames preemption as strictly dominant without engaging that design axis.
