# Sun et al. — Queueing, Predictions, and LLMs

**Full title**: Queueing, Predictions, and LLMs: Challenges and Open Problems
**Authors**: Michael Mitzenmacher (Harvard), Rana Shahout (Harvard)
  *Note: paper is widely referred to as "Sun et al." in our tracker because it entered the reading list bundled with a Sun-lab related bibliography — canonical authorship is Mitzenmacher & Shahout. Corrected here.*
**Venue**: SIGMETRICS 2025 — tutorial / position paper (arXiv:2503.07545, March 2025)
**Links**: [arXiv abs](https://arxiv.org/abs/2503.07545) · [HTML v1](https://arxiv.org/html/2503.07545v1)
**Code**: N/A (tutorial / position paper — no artifact)
**Fetched**: 2026-09-10

## Abstract
Surveys the intersection of (a) queueing theory with machine-learned predictions of service time and (b) the emerging scheduling challenges of LLM inference systems. Argues that LLM inference is a *new and rich* queueing problem — variable per-token service times, dynamic KV-cache memory constraints, prefill/decode phase asymmetry, multiple preemption strategies (swap vs recompute vs drop), and predictable-but-noisy output-length signals — and that classical predictions-augmented queueing results (SOAP, Gittins, 1-bit predictions, uniform bounds) transfer only partially. Enumerates open theoretical and systems problems across six sections: single-server queues with predictions, LLM dynamic batching, adaptive scheduling, GPU orchestration, compound AI systems, and reasoning workloads.

## Taxonomy placement
- Unit of admission: **N/A** (tutorial — spans request, batch, cluster granularities)
- Setting: **theoretical framing** — queueing-theoretic, not tied to a specific engine or workload
- SLO-awareness: **none directly** — deadlines / SLOs are mentioned only as motivation; the paper's scheduling objectives are mean/tail response time and completion time, not multi-SLO compliance
- Signal used: **queueing-theoretic** — predicted service time (point, distributional, 1-bit, k-bit), utilization, prediction cost, prefill/decode ranks

## Contribution
- **Position + tutorial hybrid.** Consolidates the "predictions in queueing" literature (SOAP framework, Mitzenmacher's 1-bit predictions, Gittins-with-predictions, uniform-bound results, prediction-cost models) into one accessible narrative aimed at the LLM systems community. Serves as the *canonical entry point* for anyone bridging classical queueing theory and modern LLM inference.
- **Novel problem statements for LLM inference.** Formulates prefill-vs-decode ranking, KV-cache memory as a *dynamic* server-capacity constraint, and preemption-mode selection (swap vs recompute) as first-class queueing problems that existing theory does not cleanly handle.
- **Compound AI systems as tandem/job-shop queues.** Argues speculative decoding, API-augmented LLMs, model-routing (mixture-of-experts / cascade), and multi-LLM pipelines should be modeled as *tandem queues* or *job-shop* problems — a framing no LLM systems paper has yet formalized.
- **Reasoning workloads as expansion/aggregation.** Section 6 flags long-CoT / test-time-compute reasoning (o1 / R1 style) as needing *entirely new* scheduling and load-balancing models — expansion (multiple parallel reasoning traces) followed by aggregation is not covered by any existing queueing model.
- **Enumerates ~25 open problems** across six sections; explicitly framed as a research agenda rather than a solved-problem review.

## Baselines
**N/A** — this is a survey / position paper; no empirical comparison is performed.

## Evaluation setup
**N/A** — no experiments. The paper's contribution is problem framing, not measurement.

## Claimed numbers
**N/A** — problem statements only; no numerical claims.

## Fidelity / reproducibility
**N/A** — no artifact, no code, no measurements. Reproducibility is not applicable to a position paper; the *literature review* portions cite standard queueing-theory results (SOAP, Gittins) that are independently verifiable.

## Relevance to survey
**Cluster 5.4 anchor** (theoretical framing / queueing background). This paper is the single best citation for grounding our survey's queueing-theoretic framing of admission control. It is also the closest *positioning peer* to our own survey — and the differentiation is clean:
- **Sun et al. (Mitzenmacher & Shahout)** is a *position paper* by two theorists. It enumerates open problems and gestures at LLM systems as a motivating application. It does **not** systematically catalog admission-control papers, does not build a taxonomy, does not do a cross-comparison matrix, and does not surface reproducibility gaps.
- **Our survey** is a *systematic review* of ~25+ admission-control-adjacent papers with a taxonomy (Admit / Queue / Route × request / batch / cluster × single-SLO / multi-SLO), a reproducibility audit, and an evidence-cited open-problems section (24 items).
- **Complementary, not competing.** We should cite Sun et al. prominently in Section 2 (background) and Section 8 (open problems) as the *theoretical* companion to our *empirical / systems* review. Their open-problem list overlaps with ours on ~4 items and *extends* ours on ~6 items (see below), which strengthens rather than threatens our differentiation.
- **Cite explicitly in Open Problem 8** — we already do this. Also cite in Open Problems 15, 16, 22 (theory-to-practice gaps).

## Open questions surfaced (Sun et al.'s enumeration — verbatim-close)

**Queueing-with-predictions (single server):**
1. Realistic models of prediction error in queueing (beyond scale/shift noise).
2. Numerical tools for M/G/1 with arbitrary prediction models.
3. Extending SOAP analysis beyond rank-based policies.
4. When are Gittins policies practical to implement?
5. Distributional (not point) predictions of service time.
6. Predictions that degrade over time / staleness.
7. Beyond 1-bit: k-bit prediction performance as k grows.
8. Tail-behavior analysis (not just expected response time) under predictions.
9. Tighter constants for graceful-degradation uniform bounds.
10. Prediction-cost models: when to predict, dedicated prediction servers, economic/incentive framing.

**LLM-specific:**
11. How to rank requests given prefill/decode split?
12. Dynamically adjust preemption thresholds by model size / batch / memory / arrival distribution.
13. SPRPT variants with *limited* preemptions and their tail behavior.
14. Global cost target + acceptable response time — joint optimization.
15. Interactive vs non-interactive workload mixing.
16. Prompt-sharing (prefix-cache) as a scheduling signal.
17. Pooled vs dedicated GPU orchestration policies.
18. Prefill/decode balance across *heterogeneous* GPUs.
19. Systematic estimation of lower-tier GPU counts to match a higher-tier GPU.

**Compound AI:**
20. Scheduling guarantees for API-augmented LLM requests (tool calls, RAG).
21. Speculative decoding as a *tandem queue* — how to size the draft-model stage.
22. Multi-LLM routing: model selection under quality/latency tradeoffs.
23. Multi-LLM sequential pipelines as job-shop scheduling.

**Reasoning:**
24. Expansion/aggregation scheduling for long-CoT reasoning workloads.
25. Load-balancing across reasoning traces with unknown branching factor.

**Ones we have NOT yet captured in `open-problems.md`:**
- **(#3) SOAP beyond rank-based policies** — pure queueing-theory gap; no analog in our list.
- **(#4) Practical Gittins for LLM serving** — Gittins-index policies for LLM admission are not in our list at all.
- **(#5) Distributional predictions** — we have prompt-conditional distributions in Problem 16 (Shen et al.), but not the *scheduling-theoretic* consequence of using a distribution instead of a point estimate.
- **(#8) Tail-behavior analysis for prediction-augmented queues** — we cover tail *SLOs*, not tail *analysis* of prediction-augmented policies.
- **(#13) Limited-preemption SPRPT variants** — adjacent to our Problem 15 (preemption ↔ admission) but from the *tail-behavior* angle, not the admission-comparability angle. Worth adding as a sub-bullet under 15.
- **(#18/#19) Heterogeneous-GPU prefill/decode balance and lower-tier-GPU sizing** — we discuss admission + routing coupling (Problem 7), but not the *hardware-tier estimation* problem. New candidate for our list.
- **(#21) Speculative decoding as a tandem queue** — our Problem 9 covers admission for speculative decoding but not the *tandem-queue formalization*. Worth folding in.
- **(#24/#25) Expansion/aggregation scheduling for reasoning** — our Problem 4 covers reasoning-trace-aware admission but not the *expansion-aggregation queueing model*. Cite Sun et al. as the framing paper.

Net: **~5 genuinely new open-problem angles** worth adding to `open-problems.md` (Gittins-practical, distributional-prediction scheduling, tail analysis of predictions, heterogeneous-GPU sizing, reasoning as expansion/aggregation queue).
