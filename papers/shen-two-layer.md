# Shen et al. — Two-Layer Framework

**Full title**: A Two-Layer Framework for Joint Online Configuration Selection and Admission Control
**Authors**: Owen Shen, Haoran Xu, Yinyu Ye, Peter Glynn, Patrick Jaillet (MIT / Stanford)
**Venue**: **ICML 2026** (poster)
**Links**: arXiv:2602.07663 · [ICML poster page 62790](https://icml.cc/virtual/2026/poster/62790) · [OpenReview dEszwexTMi](https://openreview.net/forum?id=dEszwexTMi) · [code](https://github.com/owenshens/A-Two-Layer-Framework-for-Joint-Online-Configuration-Selection-and-Admission-Control)
**Fetched**: 2026-09-10

## Abstract
Framework for sequential decisions: (1) select from K configurations that induce a distribution over reward-resource pair; (2) observe request and decide accept/reject. Proposes switching-aware fluid oracle + SP-UCB-OLP algorithm with Õ(√KT) regret. Three application domains: LLM serving, GPU scheduling, revenue management.

## Taxonomy placement
- Unit of admission: **request**
- Setting: **online serving** (theoretical, applied to LLM)
- SLO-awareness: reward-based (generalizes SLO)
- Signal used: fluid oracle switching signal + config distribution

## Contribution (deep-read summary — Days 2-6)
- **Switching-aware fluid oracle** as a new benchmark: max–min value V^mix(b) = max_{w∈Δ_K} min_{p≥0} {⟨p,b⟩ + Σ_θ w_θ g_θ(p)}, where g_θ(p) = E_θ[(r − ⟨p,a⟩)_+] is the per-config surplus. Provably upper-bounds any online policy under the pathwise budget, and — unlike the single-configuration fluid oracle — captures the value of *mixing* configurations when they consume orthogonal resource dimensions (their diagnostic "complementarity gap" scenario: fixed oracle ≈ 74.76 vs. mixing optimum = 100).
- **SP-UCB-OLP algorithm** = Saddle-Point + UCB + Online LP. Warm-start round-robin over K configs (no admission), then per round: (i) build confidence radii β_{α,θ}(t) ∝ √(d log(KT/δ)/N_θ) from concentration on the surplus, (ii) solve an *optimistic* saddle point (w_t, p_t) ∈ argmax_{w∈Δ_K} argmin_{p≥0} L_t^opt(w,p) using UCB-inflated surpluses, (iii) sample θ_t ∼ w_t, observe (r_t, a_t), and admit iff r_t > ⟨p_t, a_t⟩ and residual budget allows. The dual price p_t plays exactly the OLP shadow-price role.
- **Regret**: Reg^mix(T) ≤ C_1 α √(KT · d log T) + C_2 √(T log T) + K R_max = Õ(α √(KT)) (Theorem 9). Assumes i.i.d. bounded rewards/consumptions per config, large-budget regime B = T·b, and no-tie continuous valuations. Proof: good-event concentration → optimism gap decomposition → KKT admission-price slack → conservative budget b^safe = (1−ε)b with ε = √(log T/T) → sum of confidence radii.
- **LLM-serving instantiation is motivational, not empirical.** The paper *frames* K as configurations that induce different reward/resource distributions per request (e.g., a serving configuration that trades throughput for quality), but never runs an LLM benchmark. The concrete evaluation is on Alibaba cluster traces where K=3 pricing "regimes" (CPU-heavy, memory-heavy, balanced) act as configurations over the (cpu, mem) resource vector.
- **Design point contribution**: joint config × admission (two coupled decisions) with a switching-aware benchmark — most admission-control theory holds config fixed and only optimizes admission; most config-selection theory ignores admission. This paper unifies them.

## Baselines
- **Theoretical**: switching-aware fluid oracle V^mix (strictly stronger than the standard fixed-config fluid oracle).
- **Empirical** (Alibaba trace + synthetic Gaussian scenario S0, K=5):
  - Greedy (α=0, pure exploitation)
  - Random (uniform config selection)
  - Oracle (true optimal parameters)
  - OneHot (commit to a single config)

## Evaluation setup
- **Primarily theoretical.** No LLM engine, no LLM model, no LLM workload.
- **Synthetic (S0)**: K=5 configs, independent truncated Gaussian reward/consumption on [0.01, 2.0].
- **Alibaba cluster trace**: real (plan_cpu, plan_mem) per job, normalized to [0,1]; workload imbalance 83.6% CPU vs 34.9% mem utilization; K=3 regimes with coefficient vectors (2.0, 0.5), (0.5, 2.0), (1.2, 1.2); noise ε ∼ N(0, 0.1²).
- **Diagnostic scenario S4** ("complementarity gap") designed to *prove* the switching-aware oracle is necessary.
- **Metrics**: competitive ratio vs. oracle, regret curves; theoretical result is the Õ(√KT) bound.

## Claimed headline numbers
- Regret: **Õ(α √(KT · d log T))** (Theorem 9).
- Alibaba: Greedy 84.8% ± 14.2% competitive ratio (10/50 seeds < 70% — "regime lock-in"); minimal exploration α=0.01 → **97.4% ± 0.6%** — a >12-point mean lift and ~24× variance reduction from a tiny UCB bonus.
- Complementarity-gap scenario: fixed-config oracle ≈ 74.76 vs. mixing optimum = 100 (motivating the switching-aware benchmark).

## Fidelity / reproducibility
- **Code released**: [github.com/owenshens/A-Two-Layer-Framework-...](https://github.com/owenshens/A-Two-Layer-Framework-for-Joint-Online-Configuration-Selection-and-Admission-Control) (linked from OpenReview). Covers synthetic + Alibaba trace experiments.
- Theoretical results are self-contained; proof sketched in Appendix E (5-step decomposition), fully replicable from the write-up.
- Reproducibility of the empirical claim is straightforward — no GPU, no LLM engine required; standard OLP + UCB machinery.

## Relevance to survey
Represents the algorithmic/theoretical cluster (5.4). Joint config + admission is a novel design point that most policy papers ignore. Same author group (Jaillet) also authored arXiv:2502.07115 "Online Scheduling for LLM Inference with KV Cache Constraints" — an active theoretical research group. **Caveat for survey framing**: despite the title's billing of LLM serving as a motivating domain, this paper is a general online-LP + UCB result validated on cluster traces; it belongs in 5.4 as a theoretical instrument, not in a request-level LLM-systems cluster.

## Open questions surfaced
- **Stated in paper (Sec. 7)**: non-stationary arrivals, contextual configurations (config depends on observed request context), delayed feedback.
- **Practical**: warm-start burns K rounds of revenue (bad when K is large — e.g., a serving system with many quantization × batch × parallelism combos); confidence radii scale with resource dimensionality d (curse of dimensionality); theory requires α ≥ 1 but experiments use α ≈ 0.01 — a gap between what's proved and what works.
- **Conservative budget**: b^safe = (1−ε)b leaves capacity on the table; unclear how to close this in high-utilization LLM serving where every GPU-second matters.
- **New (mine)**: the framework assumes each config induces a *stationary* reward–resource distribution, but in real LLM serving a config's per-request cost is *input-dependent* (prompt length, decode length). Lifting the i.i.d.-per-config assumption to prompt-conditional distributions is the actual gap between this theory and an LLM-serving deployment — and it is not the "contextual" extension the authors mention (which contextualizes the config choice, not the reward distribution).
