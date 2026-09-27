# QLM

**Full title**: Queue Management for SLO-Oriented Large Language Model Serving
**Authors**: Archit Patke, Dhemath Reddy, Saurabh Jha, Haoran Qiu, Christian Pinto, Chandra Narayanaswami, Zbigniew Kalbarczyk, Ravishankar Iyer
**Venue**: **SoCC '24** (ACM Symposium on Cloud Computing)
**Links**: arXiv:2407.00047 · [ACM DL 10.1145/3698038.3698523](https://dl.acm.org/doi/10.1145/3698038.3698523)
**Code**: **Yes** — [github.com/QLM-project/QLM](https://github.com/QLM-project/QLM)
**Fetched**: 2026-09-10

## Abstract
Existing systems focus on interactive requests with tight latency but struggle when batch requests with relaxed requirements are added. QLM maintains batch + interactive requests across models/SLOs in a request queue via Request Waiting Time Estimator + global scheduler. Reports 40-90% SLO attainment improvement and 20-400% throughput gains vs SOTA.

## Taxonomy placement
- Unit of admission: **request**
- Setting: **online serving** (mixed with batch)
- SLO-awareness: **deadline + fairness across SLO classes**
- Signal used: request waiting time estimate + queue depth

## Contribution (deep-read summary — Days 2-6)
- **Request Waiting Time (RWT) estimator** that predicts per-request wait as `Wq = Σ Oi / Θ` (pending output tokens / generation throughput), leveraging CLT over historical output-token distributions to give tight bounds once the queue holds ≥4 request groups (R² ≥ 0.99). Wait is conservatively over-estimated at low queue depth — the paper is honest about this.
- **Global scheduler** formulated as a **linear program** over "virtual queues" (one per LLM instance) that minimizes total SLO-violation penalty `Σ max(0, Wq - SLO)` subject to one-to-one request-group-to-position and model-transition constraints. Solvable in ~5s for 400K requests (Gurobi).
- **Four Load-Steering Operators (LSOs)** exposed to the LP: (a) request pulling into GPU batch, (b) request eviction to CPU DRAM preserving KV cache, (c) two-tier model swapping (storage → CPU → GPU with warm cache), and (d) load balancing across heterogeneous GPUs.
- **Request grouping** abstraction: coalesces homogeneous pending requests to make the LP tractable at production queue sizes.
- **Deployed** in IBM's internal production routing service — one of the few academic queue-management systems with a real deployment path, not just a simulator.

## Baselines
- **vLLM** — SOTA continuous-batching engine with FCFS queue (primary baseline).
- **EDF (Earliest Deadline First)** — sort by SLO tightness; classical real-time scheduling baseline.
- **SHEPHERD** (OSDI '23) — ILP-based dynamic batching for DNN serving; assumes fixed-size batches so its assumptions break under LLM continuous batching.
- **Orca** (OSDI '22) — cited as prior work for iteration-level scheduling but not run head-to-head.
- Compatible backends discussed but not benchmarked: TensorRT-LLM, HuggingFace TGI.

## Evaluation setup
- **Models**: Mistral-7B, Vicuna-13B, LLaMA-70B.
- **Engine**: vLLM (QLM sits on top as a scheduling layer).
- **Hardware**: heterogeneous cluster — 30× NVIDIA A10 (24 GB) + 50× NVIDIA A100 (80 GB).
- **Workload**: ShareGPT — 3,500 requests per trace, Poisson arrivals, input/output length sampled from real distribution.
- **SLO classes**: Interactive (20s TTFT, p99) / Batch-1 (1 min) / Batch-2 (1 hour).
- **Scenarios**: WA single-model interactive+batch, WB multi-model batch (Mistral+LLaMA-70B or Vicuna+LLaMA-70B), WC mega-prompt (3K–4K tokens) HOL-blocking stress test.
- **Metrics**: SLO attainment, request throughput, GPU count required, LSO ablation impact, LP solve overhead.

## Claimed headline numbers
- **SLO attainment**: 40–90% improvement over vanilla vLLM (arrival-rate dependent).
- **Throughput**: 20% single-model, 50–400% multi-model over vLLM/EDF; up to 3–4× at 0.25K Batch-1 req/s.
- **GPU footprint**: 1.1–2.3× fewer GPUs single-model @ 0.5K interactive req/s; 2–5× fewer multi-model.
- **LSO ablation**: model swapping contributes ~300% throughput uplift in multi-model; request eviction contributes ~80% SLO uplift single-model.
- **Overhead**: LP solve ≤ 5s per scheduling round at 400K queued requests — acceptable for the reported arrival rates.

## Fidelity / reproducibility
- **Code**: public at github.com/QLM-project/QLM. Scheduling layer on top of vLLM — "any vLLM-compatible system also works with QLM."
- **Engines supported**: **vLLM only** (no TGI, TRT-LLM, SGLang bindings shipped).
- **Models**: no hard-coded model list; `config.yaml` accepts arbitrary HF model IDs (paper evaluates Mistral-7B / Vicuna-13B / LLaMA-70B).
- **Install**: `pip install -r requirements.txt`, optional `pip install -e .`, **requires Gurobi license** for the LP formulation (non-trivial dependency — academic license works but adds friction).
- **Quickstart**: `python benchmarks/basic_test.py` after setting `QLMPROJDIR`. No Docker image, no CI, no pinned CUDA/vLLM versions in the README.
- **Repo health**: 32 stars, 7 forks, 5 open issues, **only 2 commits on main** — code was dumped once around publication and is not actively maintained. No documented limitations/TODOs in README.
- **Verdict**: strongest reproducibility in the cluster on paper (real repo, real algorithm), but Gurobi dependency + stale repo + no version pins mean plugging it into a fresh benchmark harness will require non-trivial glue work.

## Relevance to survey
Anchor paper for request-level SLO cluster (5.1). The one paper in the taxonomy that's peer-reviewed at a top systems venue AND has open-source code. Load-bearing for reproducibility audit section (6). Also the clearest example of the "predict wait time → LP-schedule" design pattern that later work will be compared against.

## Open questions surfaced
- **Low-queue regime**: RWT over-estimates when <4 request groups queued — under bursty low-load, does this hurt tail latency or trigger spurious LSO actions?
- **Distribution drift**: RWT assumes stationary output-token distribution fit from history; no online adaptation. Behavior under workload shift (e.g., prompt-template change, new tenant) is unstudied.
- **Outlier prompts**: >5–10σ output-length or >10σ context-length requests fall out of the CLT bound. No admission-control fallback described.
- **End-to-end SLOs**: only TTFT is modeled; ITL / full-completion SLOs are explicitly out of scope (paper suggests composing with Andes).
- **Multi-model interactive**: current system degenerates to per-model GPU pinning because swap cost > 20s TTFT SLO — remains an open problem.
- **LP scalability**: 5s solve at 400K requests is fine for reported rates, but not obviously headroom for higher fan-out or shorter scheduling epochs.
- **Feasibility fallback**: when the LP is infeasible, paper punts to "scale up, EDF, or admission control" — no principled admission-control policy is proposed. **(This is a direct hook for our survey's admission-control angle.)**
