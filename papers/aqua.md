# AQUA

**Full title**: AQUA: Network-Accelerated Memory Offloading for LLMs in Scale-Up GPU Domains
**Authors**: Abhishek Vijaya Kumar, Gianni Antichi, Rachee Singh
**Venue**: arXiv preprint (cs.DC) — venue TBD
**Links**: arXiv:2407.21255
**Code**: TBD (not in abstract)
**Fetched**: 2026-09-10

## Abstract
GPU memory constraints during LLM inference under bursty request patterns. Argues preemptive scheduling of prompts in time slices is essential for responsive LLM inference under high load. AQUA framework reduces paging overhead while maintaining throughput. 20× responsiveness improvement, 4× throughput vs single long prompts, on 8× H100 80G.

## Taxonomy placement
- Unit of admission: **request** (preemption-based, alternative to admission-reject)
- Setting: **online serving**
- SLO-awareness: responsiveness-oriented
- Signal used: memory offload cost + PCIe/network bandwidth

## Contribution (deep-read summary — Days 2-6)
TBD

## Baselines
"State-of-the-art" (unspecified)

## Evaluation setup
- Model(s): "several state-of-the-art large generative ML models" (unspecified)
- Engine: TBD (network-accelerated GPU offloading focus)
- Workload: bursty
- Metrics: responsiveness, throughput

## Claimed headline numbers
20× responsiveness improvement; 4× throughput vs single long prompts

## Fidelity / reproducibility
- Code: TBD
- Notes: this is more of a *systems* paper on memory offloading than a pure admission paper — reclassify?

## Relevance to survey
Represents the "preemption + offload as alternative to admission-rejection" argument. Cluster 5.6 or as sub-cluster in 5.1. May be more adjacent than core — verify during deep read.

## Open questions surfaced
TBD deep read
