# Past-Future Scheduler for LLM Serving under SLA Guarantees

- **Authors**: Ruihao Gong, Shihao Bai, Siyu Wu, Yunqian Fan, Zaijun Wang, Xiuhong Li, Hailong Yang, Xianglong Liu
- **Affiliations**: Beihang University; SenseTime; Peking University
- **Venue**: ASPLOS '25 (30th ACM International Conference on Architectural Support for Programming Languages and Operating Systems, Vol. 2), pp. 798–813, Rotterdam, Mar 30 – Apr 3, 2025
- **Links**:
  - ACM DL: https://dl.acm.org/doi/10.1145/3676641.3716011
  - arXiv: https://arxiv.org/abs/2507.10150
  - dblp: https://dblp.org/rec/conf/asplos/GongBWFWLY025.html
- **Code**: https://github.com/ModelTC/lightllm (AE artifact: https://github.com/WuSiYu/lightllm-ae)
- **Fetched**: 2026-09-10

## Abstract

Continuous batching is central to modern LLM serving, but its effectiveness depends on accurately estimating each request's memory footprint. Because output lengths are unknown and highly variable, existing schedulers are either **aggressive** (assume short outputs, high utilization but frequent eviction/preemption of running decodes) or **conservative** (over-reserve KV cache, low utilization and long queuing). The Past-Future Scheduler exploits the observation that request output-length distributions are relatively stable across adjacent sliding time windows: it uses the **past** window to estimate the output-length distribution and **projects future** peak KV-cache occupancy for currently running requests, then admits new requests into the running batch only when projected peak memory stays within GPU capacity. This adaptive estimator balances queuing against harmful evictions and, on the authors' evaluation, delivers roughly 2–3x higher goodput than baseline schedulers under heavy load while meeting SLA targets.

## Admission-adjacent component?

**Partial — batch-level admission, not request-level rejection.** Despite the "SLA guarantees" framing, the paper does not include a classical admission control test that rejects or defers requests based on whether their SLO can be met. Instead, SLA-awareness enters through a **projected-memory admission check at the batching boundary**: on every scheduling step, the scheduler predicts peak KV-cache usage over a future horizon for the current running set (using the past window's output-length distribution) and only pulls a waiting request into the running batch if projected peak memory stays under a safety threshold. Requests that don't fit stay queued rather than being evicted mid-decode. So it is best characterized as **memory-projection-based batch admission / preemption avoidance** — a scheduling-side gate on batch composition — rather than a per-request SLO feasibility test with rejection. Requests are never turned away; they wait. SLA metrics (TTFT, TBT) are used to define goodput but do not appear as inputs to a per-request admit/reject decision.

## Contributions

- **Past window as an output-length oracle**: Characterization that within adjacent sliding windows the empirical distribution of output lengths is stable enough to serve as a predictor for the next window — sidesteps the need for a learned per-request length predictor.
- **Future peak-memory projection**: For each candidate batch composition, roll forward the running set's KV-cache occupancy over a lookahead horizon using the past-window distribution, and only admit a new request into the running batch if projected peak stays under GPU capacity. This directly targets **harmful preemption/eviction**, which the paper identifies as the dominant SLA-violator for aggressive schedulers.
- **Adaptive to workload shape**: Unlike a fixed conservative reservation or a fixed aggressive "assume-zero-output" policy, the estimator self-tunes to whatever input/output-length regime the workload is currently in, keeping goodput high across ShareGPT-like and long-output regimes.

## Baselines

Compared against vLLM's scheduler (aggressive, assumes output length ~0) and conservative reservation-based scheduling; system-level comparisons reference DeepSpeed-MII, TGI, and FastGen. Implementation is on top of LightLLM.

## Evaluation setup (brief)

- **Models**: LLaMA / LLaMA-2 family, Qwen (incl. Qwen-VL), Baichuan-2, InternLM, Yi.
- **Workload**: ShareGPT-derived request traces with varying arrival rates to sweep load regimes; long-output regimes to stress KV-cache pressure.
- **Metrics**: **Goodput** under SLA targets on TTFT and per-token latency (TBT), plus eviction/preemption rate, GPU memory utilization, and queuing delay.
- **Headline**: ~2–3x goodput over baseline schedulers under heavy load while satisfying SLA.
- Hardware specifics not extracted from the available excerpt.

## Relevance to survey

Belongs in **Cluster 5.1 (SLO-aware scheduling)**, not 5.6 (admission control). It is a strong exemplar of the "SLA-aware but no explicit admission test" pattern that the survey should contrast against true admission-control systems: it uses SLA-relevant signals (projected memory → preemption risk → TTFT/TBT violations) to shape **batch composition and queuing**, but never rejects or defers a request on SLO-feasibility grounds. Useful as a boundary case when defining what "admission control" means in the survey's taxonomy: the past-future projection is functionally an admission check *into the running batch* (an internal gate), which is worth distinguishing from *external* admission control at the ingress. Also a useful baseline/point of comparison for any Tier-1 admission-control paper that claims SLA guarantees via prediction — Past-Future shows how far you can get with distribution-level prediction alone, without per-request length estimation or rejection.
