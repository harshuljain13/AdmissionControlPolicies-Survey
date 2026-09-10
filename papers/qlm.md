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
TBD

## Baselines
"State-of-the-art LLM serving systems" — need to identify from paper body

## Evaluation setup
- Model(s): heterogeneous GPUs, real-world dataset — details TBD
- Engine: TBD
- Workload: real-world LLM serving dataset
- Metrics: SLO attainment, throughput, device utilization

## Claimed headline numbers
40-90% SLO attainment improvement; 20-400% throughput gains

## Fidelity / reproducibility
- Code: **available** on GitHub — high reproducibility
- Notes: strongest reproducibility position in the whole cluster

## Relevance to survey
Anchor paper for request-level SLO cluster (5.1). The one paper in the taxonomy that's peer-reviewed at a top systems venue AND has open-source code. Load-bearing for reproducibility audit section (6).

## Open questions surfaced
TBD deep read
