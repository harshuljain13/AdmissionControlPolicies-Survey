# Scorpio

**Full title**: Scorpio: Serving Right Requests at the Right Time for Heterogeneous SLOs in LLM Inference
**Authors**: Yinghao Tang, Tingfeng Lan, Bo Pan, Xiuqi Huang, Hui Lu, Wei Chen
**Venue**: **WISE 2026** (27th International Conference on Web Information Systems Engineering)
**Links**: arXiv:2505.23022
**Code**: not established during this pass
**Fetched**: 2026-09-21 (full PDF, text-extracted)

## Taxonomy placement
- Unit of admission: **request**
- Setting: **online**
- SLO-awareness: **deadline** (TTFT and TPOT, decomposed)
- Signal used: **dual-gate** (TTFT feasibility + TPOT-under-virtual-batch), both driven by a
  learned output-length prediction rather than an analytic model
- Decision moment: **ingress**

## Mechanism
Three stages: admission control, queue management, batch selection.

- **TTFT Guard** — least-deadline-first reordering; rejects requests whose first-token
  deadline is unattainable, estimated from the cumulative prefill time of what is already
  queued.
- **TPOT Guard** — VBS (virtual batch size) based admission: admits only if predicted
  per-token latency for the resulting batch stays under the tightest TPOT target in the
  running set. Paired with a credit-based batching mechanism.
- **Predictor** — OPT-125M fine-tuned as a *length-bin classifier* on 20K ShareGPT and
  LMSYS-Chat-1M samples, co-located with the serving engine. Verbatim: "We fine-tune
  OPT-125M as a length-bin classifier on 20K ShareGPT and LMSYS-Chat-1M samples."
- **Binning** — 100 equal-width bins, chosen by systematic analysis: "for Llama3-8B on
  ShareGPT, 100 equal-width bins give Kendall's tau of 0.54 versus 0.25 at 10 bins."

## Setup
- **Hardware**: 4x NVIDIA A100 80GB, NVLink within pairs, PCIe/NUMA across pairs
- **Models**: Meta Llama-3.1-8B (1 GPU) and Google Gemma-2-27B (4 GPUs, tensor parallel), FP16/BF16
- **Workloads**: ShareGPT, LMSYS-Chat-1M, and real Azure production traces
- **Baselines**: vLLM (throughput-oriented, prefill-prioritising), S3 (length prediction +
  SJF), Mooncake
- **Engine**: implemented on vLLM

## Claimed headline numbers
- **up to 14.4x** system goodput and **up to 46.5%** SLO adherence over state-of-the-art
  baselines, under high load
- Scheduling overhead **under 1%**

## Why this paper matters to the survey

**The goodput denominator.** Verbatim from the problem formulation: "Note that the
denominator |R| counts all arriving requests, so rejected requests are counted as
SLO-unmet and never inflate either metric."

That is exactly the discipline the survey defines in §2.3 as goodput-under-admission,
reached independently. It is the strongest external support for that definition, because
a metric counting only *admitted* requests lets a shedding policy refuse most traffic and
still report near-perfect attainment.

**Policy-versus-policy comparison.** Scorpio's Mooncake baseline is one of very few cases
in the corpus where one admission mechanism is measured against another, rather than
against an unconfigured engine.

## Verification status (2026-09-21)
Every claim the survey makes about Scorpio was checked against the full text and holds:
three-stage split, TTFT Guard rejection and reordering, TPOT Guard virtual-batch
admission, OPT-125M over 100 bins, 4x A100, Llama-3.1-8B and Gemma-2-27B, the vLLM/S3/
Mooncake baselines, and the 14.4x / 46.5% figures.

**Two bibliography errors found and fixed.** The entry carried `author={Anonymous}` and
the citation key `he2026scorpio`; the first author is Tang. Key is now `tang2026scorpio`.
The title also carried a spurious "the" ("Serving the Right Requests"); corrected to match
the published title.
