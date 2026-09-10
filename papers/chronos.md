# Chronos

**Full title**: Formal schedulability analysis for LLM inference: TTFT and TBT deadline guarantees via response-time theory
**Authors**: [TBD — verify from paper]
**Venue**: **Frontiers in Computer Science**, Volume 8, June 29, 2026 (peer-reviewed; edited by Yi Dong; reviewed by Sabina Rossi + Boxuan Wang)
**Links**: [Frontiers DOI 10.3389/fcomp.2026.1873627](https://www.frontiersin.org/journals/computer-science/articles/10.3389/fcomp.2026.1873627/full)
**Code**: **Yes** — [github.com/am-research/rtss-ttft-tbt](https://github.com/am-research/rtss-ttft-tbt) (simulator)
**Fetched**: 2026-09-10

## Abstract
Applies classical real-time-systems response-time theory to LLM inference. Provides schedulability condition + admission test + WCRT bound for TTFT and TBT. Sporadic-task model: prefill = sporadic job with TTFT deadline; decode = task with TBT-bounded iterations.

## Taxonomy placement
- Unit of admission: **request**
- Setting: **online serving**
- SLO-awareness: **deadline-aware** (TTFT + TBT)
- Signal used: WCRT bound + deadline slack

## Contribution (deep-read summary — Days 2-6)
TBD

## Baselines
FCFS (no admission control) · EDF · SLAI (SLO-Aware LLM Inference) · AC-FCFS (token-bucket rate limiting matched to Chronos throughput)

## Evaluation setup
- Model(s): 7B-parameter model
- Engine: custom simulator (not vLLM/SGLang)
- Workload: replay 50,000 requests uniformly at random from production Azure LLM inference traces (44M total, 2 services: code completion + conversational)
- Metrics: deadline miss rate, TTFT, TBT, throughput

## Claimed headline numbers
TBD — deep read

## Fidelity / reproducibility
- Code: **available** (simulator only, not real vLLM/SGLang)
- Reproducibility scripts included per README
- Second-strongest reproducibility position in the cluster (after QLM)

## Relevance to survey
Anchor for formal-real-time cluster within 5.1. The only paper that provides a formal schedulability condition — bridge between systems and real-time-theory communities. Load-bearing for Open Problem 8 (formal schedulability with LLM-specific WCRT).

## Open questions surfaced
TBD deep read
