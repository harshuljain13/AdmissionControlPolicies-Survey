# AQUA

**Full title**: AQUA: Network-Accelerated Memory Offloading for LLMs in Scale-Up GPU Domains
**Authors**: Abhishek Vijaya Kumar, Gianni Antichi, Rachee Singh
**Venue**: ASPLOS '25 (Rotterdam, Mar 30–Apr 3, 2025); DOI 10.1145/3676641.3715983
**Links**: arXiv:2407.21255
**Code**: https://github.com/aquaml
**Fetched**: 2026-09-10

## Abstract
GPU memory constraints during LLM inference under bursty request patterns. Argues preemptive scheduling of prompts in time slices is essential for responsive LLM inference under high load. AQUA framework reduces paging overhead while maintaining throughput. 20× responsiveness improvement, 4× throughput vs single long prompts, on 8× H100 80G.

## Taxonomy placement
- Unit of admission: **request** (preemption-based, alternative to admission-reject)
- Setting: **online serving**
- SLO-awareness: responsiveness-oriented
- Signal used: memory offload cost + PCIe/network bandwidth

## Contribution (deep-read summary — Days 2-6)
- **Reframes admission as a paging problem**: rather than rejecting/queueing bursty prompts (vLLM's admission control), AQUA argues for preemptive time-slicing of prompts, and attacks the resulting paging cost as the real bottleneck.
- **Aqua-Profiler**: online workload profiler that classifies co-located GPUs as memory *producers* (spare KV capacity) vs *consumers* (memory-bottlenecked) per-model, per-workload.
- **Aqua-Placer**: optimization that pairs consumers with producers *within the same NVLink/NVSwitch scale-up domain*, so evicted KV state is paged GPU→GPU at 300–450 GB/s instead of GPU→host DRAM at 25–50 GB/s over PCIe.
- **Aqua-Lib**: runtime abstraction exposing elastic, migratable KV tensors; integrates with chunked-prefill so preemption preserves prefix work.
- **CFS-style preemptive scheduler**: reschedules every k iterations or on request completion, paging out non-scheduled prompts and paging in previously evicted ones — request-granularity preemption, not token/layer.

## Baselines
- vLLM (default FCFS scheduler, PagedAttention w/ PCIe swap to host DRAM)
- vLLM + CFS (preemptive variant, still PCIe-bound)
- FlexGen (memory-constrained offload inference)
- VTC (fair-share admission control)
- Auto-scaling (spin-up more replicas on burst)

## Evaluation setup
- **Hardware (primary)**: 8× H100 80GB, NVSwitch @ 450 GB/s, PCIe Gen5 @ 50 GB/s, 1.5 TB host RAM.
- **Hardware (secondary)**: 2× A100 80GB, NVLink @ 300 GB/s, PCIe Gen4 @ 25 GB/s.
- **Models**: Llama 3.1 8B, Llama 3.1 70B, Yi-34B, Yi-34B-200K, OPT-30B; also multi-modal (SD-3, SD-XL, Kandinsky, AudioGen, MusicGen).
- **Engine**: extends vLLM (PagedAttention retained; swap layer replaced with Aqua-Lib GPU-GPU pager).
- **Workload**: synthetic bursty request arrivals; long-prompt stress (8K tokens).
- **Metrics**: TTFT / responsiveness, end-to-end throughput (tokens/sec), paging overhead.

## Claimed headline numbers
- **20× responsiveness (TTFT)**: Llama 3.1 70B on 2 GPUs under burst — TTFT ~20s (vLLM FCFS) → ~1s (AQUA CFS + NVLink paging).
- **4× throughput on long prompts**: OPT-30B, 8K-token prompts — FlexGen ~2 tok/s vs AQUA ~8 tok/s, from replacing DRAM offload with GPU-GPU offload inside the scale-up domain.

## Fidelity / reproducibility
- Code released at github.com/aquaml; built on vLLM so integration path is clear.
- Reproducibility risk: NVSwitch-class 8×H100 testbed is hard to replicate outside cloud tier; A100 secondary results partially mitigate.
- Numbers are best-case burst scenarios; steady-state gains under uniform load not the headline.

## Relevance to survey
Represents the "preemption + offload as alternative to admission-rejection" argument. Cluster 5.6 or as sub-cluster in 5.1. May be more adjacent than core — verify during deep read.

## Open questions surfaced
- Does GPU-GPU paging still win once *all* co-located GPUs are memory-consumers (no producers left)? Producer/consumer asymmetry is the whole premise.
- How does AQUA compose with disaggregated prefill/decode architectures (Splitwise, DistServe) that already move KV over the fabric for a different reason?
- Fairness of the CFS scheduler under adversarial long-context prompts is not stressed — a long-prompt tenant can dominate a producer GPU's KV budget.
- No SLO-attainment metric (P99 TTFT under target); "responsiveness" is reported as mean/tail TTFT rather than deadline attainment — gap for the admission-control framing.
- Scale-up domain assumption breaks in commodity 2–4 GPU boxes without NVSwitch; degradation curve vs interconnect BW would be a useful ablation.
