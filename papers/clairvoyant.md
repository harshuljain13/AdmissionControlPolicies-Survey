# Clairvoyant

**Full title**: Clairvoyant: Predictive Shortest-Job-First Admission for Serial LLM Inference
**Authors**: Aravind Sundaresan
**Venue**: arXiv preprint (cs.DC) — venue TBD
**Links**: arXiv:2606.07248
**Code**: **Yes** — [github.com/Aravind0403/clairvoyant-scheduler](https://github.com/Aravind0403/clairvoyant-scheduler) (pinned to commit 39ad9a64)
**Fetched**: 2026-09-10

## Abstract
Addresses Head-of-Line Blocking in serial LLM inference systems where short requests get delayed behind long-running jobs. Clairvoyant proxy predicts response length using 19 lightweight lexical features via ONNX-exported XGBoost classifier — implements predictive Shortest-Job-First scheduling. 70-76% short-request P50 latency reduction on RTX 4090; 69.7% reduction on Apple M1. 95% of ranking fidelity of fine-tuned transformers at lower computational cost.

## Taxonomy placement
- Unit of admission: **request** (with SJF ordering)
- Setting: **serial (single-request) LLM inference** — edge / Ollama / llama.cpp
- SLO-awareness: latency-oriented
- Signal used: predicted response length (XGBoost proxy)

## Contribution (deep-read summary — Days 2-6)
TBD

## Baselines
FIFO on Ollama/llama.cpp; references cloud-scale vLLM/Orca for context (not direct comparison)

## Evaluation setup
- Systems: RTX 4090, Apple M1, GCP NVIDIA L4 (real-world trace replay)
- Engine: **Ollama, llama.cpp** (serial backends — NOT vLLM/SGLang concurrent servers)
- Metrics: P50 latency, ranking fidelity vs transformer-based length predictors

## Claimed headline numbers
70-76% short-request P50 latency reduction on RTX 4090; 69.7% on M1

## Fidelity / reproducibility
- Code: **available**, pinned commit, dependency versions listed (Python 3.10+, Go 1.21+, XGBoost 2.0.3, ONNX Runtime 1.16.3)
- Third-strongest reproducibility position in the cluster (after QLM and Chronos)

## Relevance to survey
Cluster 5.1 (request-level) but with the distinctive edge/serial framing — different deployment context than server-side vLLM/SGLang. Notable as one of the few papers with released code + prediction-based admission. Provides the "predictive SJF" data point.

## Open questions surfaced
TBD deep read
