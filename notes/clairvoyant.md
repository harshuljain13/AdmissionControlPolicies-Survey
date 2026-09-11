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
- **Predictive SJF for serial backends**: repositions classic SJF for the single-GPU/edge regime where engines (Ollama, llama.cpp) execute requests serially — HoL blocking is the dominant tail-latency pathology, and admission-time reordering is the lever.
- **19-feature lexical proxy**: 6 numeric features (prompt_token_len ≈ ⌊len/4⌋, has_code_keyword, has_length_constraint, ends_with_question, has_format_keyword, clause_count) + 13 verb one-hots (what, write, explain, summarize, how, list, implement, compare, describe, generate, why, define, other). Deliberately sub-millisecond; ONNX-exported XGBoost keeps inline overhead negligible vs. DistilBERT's 865 ms P99.
- **Three-class (Short/Medium/Long) XGBoost classifier**: 300 estimators, depth 6, lr 0.1, 3-class softmax, seed 42, 80/20 stratified split. Trained separately on ShareGPT, LMSYS-Chat-1M, OASST1.
- **"Curated instruction datasets are degenerate" finding**: Alpaca (0.008%), CodeAlpaca (0.015%), Dolly (0.6%) contain <<0.02% Long-class responses because GPT synthesis imposed brevity — unusable for length prediction. Only organic conversation logs (ShareGPT, LMSYS, OASST1) produce viable training signal. This is a genuinely useful negative result for the length-prediction sub-literature.
- **Reference proxy implementation**: Go proxy at :8080, ONNX runtime for inference, starvation timeout guard against Long-class starvation, forwards to upstream Ollama/llama.cpp.

## Baselines
- FCFS (random ordering baseline, ~50% ranking accuracy)
- Prompt-length heuristic (52.3–55.8% ranking accuracy)
- Keyword heuristic (4.6–36.3%)
- DistilBERT fine-tuned length predictor (higher accuracy but 865 ms P99 — "unusable inline")
- Cloud-scale vLLM / Orca discussed only as context; **no head-to-head comparison** with concurrent-batch schedulers.

## Evaluation setup
- **Hardware**: RTX 4090 (24 GB), Apple M1 (16 GB unified), GCP g2-standard-4 with NVIDIA L4 (24 GB)
- **Engine**: **Ollama** (primary), llama.cpp (serial backends — NOT vLLM/SGLang concurrent servers)
- **Models**: Gemma3:4b, Llama3.1:8b
- **Workloads**: 100-request bursts (50 Short / 50 Long) for GPU/M1; real LMSYS trace replay with Poisson arrivals (ρ=0.80) on L4
- **Metrics**: short-request P50 latency, TTFT, ranking accuracy, per-class recall

## Claimed headline numbers
- **70–76% short-request P50 latency reduction** — RTX 4090, 100-request mixed burst (50 Short / 50 Long), Gemma3:4b and Llama3.1:8b
- **69.7% P50 reduction** — Apple M1, same mixed burst, Gemma3:4b
- **83.6% TTFT reduction** — GCP L4, real LMSYS trace replay, Poisson arrivals at ρ=0.80
- **95% of DistilBERT's ranking fidelity** at a fraction of its inline latency
- **SJF benefits concentrate at ρ ≳ 0.55**; below that FCFS is fine — an honest operational envelope statement

## Fidelity / reproducibility
- **Code available**, pinned commit 39ad9a64, 12 commits on main, "Paper in preparation" — active, not stale
- **Deps**: Python 3.10+, Go 1.21+, XGBoost 2.x, ONNX Runtime (system-dependent, e.g., `brew install onnxruntime`)
- **Repro pipeline present**: `data/pipeline/` (dataset + feature extraction), `model/` (train + ONNX export), `profiler/benchmark.py` (GPU bench), `profiler/trace_replay.py` (L4 trace replay)
- **Known gotcha**: XGBoost 2.x omits `split_condition` from `get_dump(format='json')` for binary one-hot features — requires manual patching before ONNX export, silent failure otherwise. Documented in README.
- Third-strongest reproducibility position in the cluster (after QLM and Chronos).

## Relevance to survey
Cluster 5.1 (request-level) but with the distinctive edge/serial framing — different deployment context than server-side vLLM/SGLang. Notable as one of the few papers with released code + prediction-based admission. Provides the "predictive SJF" data point.

## Open questions surfaced
- **Cross-distribution generalization is weak**: zero-shot accuracy drops to 52.7–65.3% off the training distribution; author's fix is ~240-request domain retraining — but who owns/refreshes that in a production edge deployment?
- **Tokenizer approximation breaks on CJK and minified code** (character-length undercounts) — proxy will systematically misclassify these prompts as Short.
- **Response buffering inflates end-to-end wins**: current impl buffers full responses before returning; streaming would change the reported P50 numbers (author calls these "conservative upper bounds" but effect on relative ordering is not quantified).
- **No head-to-head against vLLM/SGLang admission policies** — the paper cleanly stays in the serial lane, but the survey should not let readers assume serial-SJF gains transfer to continuous-batching regimes.
- **Starvation-timeout tuning**: SJF's Long-class starvation is guarded by a timeout, but the sensitivity of tail latency to that timeout under sustained load is not characterized.
- **Only 2 models tested** (Gemma3:4b, Llama3.1:8b); length distributions for larger or reasoning-tuned models (o1-style, DeepSeek-R1) likely break the 3-class assumption.
