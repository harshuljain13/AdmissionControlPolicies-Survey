# Shen et al. — Two-Layer Framework

**Full title**: A Two-Layer Framework for Joint Online Configuration Selection and Admission Control
**Authors**: Owen Shen, Haoran Xu, Yinyu Ye, Peter Glynn, Patrick Jaillet (MIT / Stanford)
**Venue**: **ICML 2026** (poster)
**Links**: arXiv:2602.07663 · [ICML poster page 62790](https://icml.cc/virtual/2026/poster/62790)
**Code**: TBD
**Fetched**: 2026-09-10

## Abstract
Framework for sequential decisions: (1) select from K configurations that induce a distribution over reward-resource pair; (2) observe request and decide accept/reject. Proposes switching-aware fluid oracle + SP-UCB-OLP algorithm with Õ(√KT) regret. Three application domains: LLM serving, GPU scheduling, revenue management.

## Taxonomy placement
- Unit of admission: **request**
- Setting: **online serving** (theoretical, applied to LLM)
- SLO-awareness: reward-based (generalizes SLO)
- Signal used: fluid oracle switching signal + config distribution

## Contribution (deep-read summary — Days 2-6)
TBD

## Baselines
Theoretical benchmark: "switching-aware fluid oracle" — need to identify empirical baselines from paper body

## Evaluation setup
- Model(s): TBD (paper appears primarily theoretical; check empirical section)
- Engine: TBD
- Workload: TBD
- Metrics: regret bound (theoretical); empirical TBD

## Claimed headline numbers
Õ(√KT) regret bound

## Fidelity / reproducibility
- Theoretical paper — reproducibility = replicable regret analysis
- Code: TBD

## Relevance to survey
Represents the algorithmic/theoretical cluster (5.4). Joint config + admission is a novel design point that most policy papers ignore. Same author group (Jaillet) also authored arXiv:2502.07115 "Online Scheduling for LLM Inference with KV Cache Constraints" — an active theoretical research group.

## Open questions surfaced
TBD deep read
