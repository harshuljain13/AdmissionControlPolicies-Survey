# Fluid-WAIT

**Full title**: Optimizing LLM Inference: Fluid-Guided Online Scheduling with Memory Constraints
**Authors**: Ao, Luo, Simchi-Levi, Wang
**Venue**: arXiv preprint — venue TBD
**Links**: arXiv:2504.11320
**Code**: **No** (simulator-only in Vidur; not released)
**Fetched**: 2026-09-05 (prior session)

## Abstract
Threshold-based admission rules — WAIT (Waiting for Accumulated Inference Threshold) and Nested WAIT — designed to handle KV cache growth memory constraints during LLM inference. Enlarges the empirically observed stable operating range vs widely used baseline algorithms.

## Taxonomy placement
- Unit of admission: **request**
- Setting: **online serving**
- SLO-awareness: partial (stability-oriented)
- Signal used: queue accumulation threshold + KV memory constraint

## Contribution (deep-read summary — Days 2-6)
TBD

## Baselines
"Widely used baseline algorithms" (vague — check paper body)

## Evaluation setup
- Model(s): Llama-2-7B
- Engine: **Vidur simulator** (supplemental real-GPU validation in appendix)
- Workload: TBD
- Metrics: stable operating range, throughput, latency

## Claimed headline numbers
"Empirically observed stable operating range" enlarged vs baselines — no specific x-fold number

## Fidelity / reproducibility
- Code: **not released**
- Notes: Vidur simulator is public, so re-implementation possible; the WAIT threshold derivation requires re-solving fluid model per workload (M*, equilibrium batch) — 1-2 days tuning per workload per Feasibility Audit

## Relevance to survey
Represents fluid-model/queueing-theory approach to admission thresholds (cluster 5.4). Complement to Chronos (formal WCRT) — both are theoretically grounded but with different mathematical machinery.

## Open questions surfaced
TBD deep read
