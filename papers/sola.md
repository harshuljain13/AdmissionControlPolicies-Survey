# SOLA

**Full title**: SOLA: Optimizing SLO Attainment for Large Language Model Serving with State-Aware Scheduling
**Authors**: Ke Hong, Xiuhong Li, Lufang Chen, Qiuli Mao, Xuefei Ning, Guohao Dai, Shengen Yan, Yun Liang, Yu Wang (Tsinghua, Infinigence-AI, SJTU, PKU)
**Venue**: **MLSys 2025** (poster, presented May 14 2025)
**Links**: [MLSys Proceedings hash bc82dbfbfa43232be85b8d9838f49c3e](https://proceedings.mlsys.org/paper_files/paper/2025/hash/bc82dbfbfa43232be85b8d9838f49c3e-Abstract-Conference.html) · [OpenReview ubIvpetAd6](https://openreview.net/forum?id=ubIvpetAd6) · [Slides](https://mlsys.org/media/mlsys-2025/Slides/3231.pdf) · [Full PDF](https://nicsefc.ee.tsinghua.edu.cn/nics_file/pdf/ce55a1f2-ff0d-45f6-8985-f4f251b2a0d4.pdf)
**Code**: TBD (check paper body)
**Fetched**: 2026-09-10

## Abstract
Fine-grained scheduling based on formal design space; state-aware scheduling with awareness of per-request states + systemic states. Balances TTFT/TPOT + balances across requests. Enhances SLO attainment from 45.5% to 99.4%; 1.04-1.27× more requests served vs SOTA.

## Taxonomy placement
- Unit of admission: **request**
- Setting: **online serving**
- SLO-awareness: **deadline-aware** (TTFT + TPOT)
- Signal used: composite (per-request state + systemic state)

## Contribution (deep-read summary — Days 2-6)
TBD

## Baselines
"State-of-the-art systems" — identify from paper body

## Evaluation setup
- Model(s): TBD deep read
- Engine: TBD
- Workload: TBD
- Metrics: SLO attainment, requests served

## Claimed headline numbers
45.5% → 99.4% SLO attainment; 1.04-1.27× more requests

## Fidelity / reproducibility
TBD deep read

## Relevance to survey
Request-level SLO cluster (5.1). Represents the "systemic state" signal branch — different from Chronos (deadline slack) and QLM (queue depth).

## Open questions surfaced
TBD deep read
