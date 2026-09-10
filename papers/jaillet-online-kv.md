# Jaillet et al. — Online Scheduling for LLM Inference with KV Cache Constraints

**Full title**: Online Scheduling for LLM Inference with KV Cache Constraints
**Authors**: Patrick Jaillet, Jiashuo Jiang, Konstantina Mellou, Marco Molinaro, Chara Podimata, Zijie Zhou (MIT / HKUST / Microsoft Research / PUC-Rio)
**Venue**: arXiv preprint only (v1 Feb 2025, v5 Jan 2026); classified cs.LG / cs.AI / math.OC. No peer-reviewed venue as of 2026-09-10 — cited as "arXiv preprint" by downstream work (e.g., arXiv:2508.06133, arXiv:2604.11001, arXiv:2605.04595).
**Links**: [arXiv:2502.07115](https://arxiv.org/abs/2502.07115) · [PDF v5](https://arxiv.org/pdf/2502.07115v5) · [MIT mirror](http://www.mit.edu/~jaillet/general/2502.07115v5.pdf)
**Code**: Not released (no repository linked in the paper as of v5).
**Fetched**: 2026-09-10

## Abstract
Formulates LLM inference scheduling as an online problem where each request occupies KV-cache memory that grows monotonically with generated tokens until completion. Proves an Ω(√n) lower bound for any deterministic online algorithm under arbitrary arrivals, then proposes MC-SF (Memory-Constrained Shortest-First), a joint batching + scheduling policy that attains a constant competitive ratio in a structured regime (all-at-time-0 arrivals, identical prompt sizes, α-accurate output-length predictions, memory M ≥ 2·max(sᵢ + õᵢ)). Simulated on the LMSYS trace with Llama2-70B on 2× A100.

## Taxonomy placement
- Unit of admission: **request** (batching decision per round is which requests to admit into the running batch under KV budget)
- Setting: **online serving**, single-node, KV-memory-constrained
- SLO-awareness: **latency-oriented** (average end-to-end latency objective), no explicit SLO
- Signal used: **predicted output length** õᵢ (with α-multiplicative accuracy assumption) + current KV occupancy

## Contribution
**Both** — a theoretical result (competitive-ratio bounds, positive and negative) *and* an admission/batching policy (MC-SF) that operationalizes them.
- **Negative result**: Ω(√n) competitive-ratio lower bound for any deterministic online algorithm under arbitrary arrival sequences with KV-cache constraints — motivates the assumption relaxations that follow.
- **Positive result**: constant O(1) competitive ratio for MC-SF under (i) simultaneous arrivals, (ii) identical prompt lengths, (iii) α-bounded output-length prediction (oᵢ ≤ õᵢ ≤ α·oᵢ), (iv) memory slack M ≥ 2·max(sᵢ + õᵢ).
- **Algorithmic**: two policy families — **α-protection greedy** (reserve a memory margin proportional to prediction error) and **α-protection β-clearing** (periodically drain the batch to bound peak occupancy). MC-SF combines shortest-predicted-remaining-output ordering with memory-feasibility admission.
- **Hindsight benchmark**: integer program over admission-time and per-round batch membership, used both for the theory and as the empirical yardstick.

## Baselines
- **MC-Benchmark**: memory-feasibility batch admission modeled on vLLM's FCFS + threshold approach (industry reference).
- **α-protection greedy** and **α-protection β-clearing** (the paper's own variants, ablated against MC-SF).
- **Hindsight optimal IP** on synthetic instances.

## Evaluation setup
- **Trace**: LMSYS-Chat-1M subset — 10,000 conversations, mean prompt 40.62 tokens, mean output 85.32 tokens.
- **Model**: Llama2-70B (tokenizer + per-token KV footprint used to size memory budget; not an end-to-end engine run).
- **Hardware assumption**: dual A100, memory budget M = 16,492 KV slots.
- **Regimes**: (a) all-at-time-0 synthetic; (b) online Poisson-style arrivals at varying rates.
- **Metrics**: average end-to-end latency; ratio to hindsight-optimal IP.

## Claimed numbers
- **Theoretical**: Ω(√n) lower bound (adversarial); O(1) competitive ratio (structured regime, explicit constant depends on α and memory slack).
- **Empirical**: MC-SF achieves **1.005×** hindsight-optimal on the all-at-time-0 synthetic setting and **1.047×** under online arrivals; roughly **6× smaller latency slope** than MC-Benchmark under high demand (Fig. showing latency-vs-arrival-rate curves).

## Fidelity
- **No code release** (as of v5, 2026-01-15) — reproducibility depends on re-implementing MC-SF and the IP benchmark from the paper's pseudocode.
- **Not run on a real LLM engine**: the "Llama2-70B on A100" numbers are simulator-level (KV-slot arithmetic on the LMSYS trace), not vLLM/SGLang/TRT-LLM measurements. Peak-memory and latency are computed from an analytical KV model, not GPU wall-clock.
- Theory is self-contained; assumptions (i)–(iv) are strong and clearly stated.

## Relevance to survey (cluster 5.4)
Sits cleanly in the theoretical cluster. Complements Shen et al. by tackling the **KV-memory-per-token** structure that Shen et al. abstract away — Shen's reward/consumption vector is stationary per config, whereas here consumption is *monotonically growing over the lifetime of a request* (the KV cache), which is the LLM-specific twist. Together the two papers stake out the Jaillet-lab thread: Shen = joint config × admission with fluid oracle; Jaillet-2025 = pure admission/batching under time-varying per-request memory. Should be cited alongside Shen et al. as the theoretical anchors for admission control in the survey's Section 5.4, with an explicit note that neither runs on a real LLM engine.

## Open questions surfaced
- **Stated**: closing the gap between the Ω(√n) adversarial lower bound and the O(1) structured upper bound — what is the tight ratio under stochastic (Poisson) arrivals with heterogeneous prompts?
- **Stated**: dropping the identical-prompt assumption; extending α-accurate prediction to distributional prediction (calibrated quantiles instead of multiplicative bounds).
- **New (mine)**: MC-SF assumes a *single-round* preemption-free admission per request — but modern engines (vLLM, SGLang) preempt and re-admit under memory pressure. The competitive analysis does not model swap-in/swap-out cost, which is exactly the regime where the α-protection margin would be re-paid. A competitive-ratio result under preemption with bounded swap cost is missing from the Jaillet-lab thread and would connect this line of work to systems papers (FastServe, Sarathi-Serve).
- **New (mine)**: the α-accuracy assumption on output-length prediction is exactly the "predictions with errors" learning-augmented-algorithms interface — but the paper never frames it that way. A robustness/consistency Pareto (à la Lykouris–Vassilvitskii) would be the natural next paper and is currently absent from the group's thread.
