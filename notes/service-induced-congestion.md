# Service-Induced Congestion

**Full title**: Service-Induced Congestion in Memory-Constrained LLM Serving
**Authors**: Ruicheng Ao, Jing Dong, Gan Luo, David Simchi-Levi
**Venue**: arXiv preprint (math.OC) — venue TBD
**Links**: arXiv:2606.15555
**Code**: **No**
**Fetched**: 2026-09-10

## Abstract
Discrete-time dynamical model of GPU-memory-constrained LLM serving. Key insight: the service process itself creates future capacity pressure as KV caches grow during token generation. Analyzes admission + memory dynamics + eviction under continuous batching. Homogeneous workloads converge to limit cycles with throughput losses up to 50%. Heterogeneous workloads have stability criteria — workload heterogeneity desynchronizes completions and stabilizes performance.

## Taxonomy placement
- Unit of admission: **request**
- Setting: theoretical (both online + batch modeled)
- SLO-awareness: throughput-oriented (stability)
- Signal used: dynamical-system analysis — service completion timing

## Contribution (deep-read summary — Days 2-6)
- **Discrete-time dynamical model of continuous batching under a memory budget.** State $X^n = (x_{k,j}^n)$ tracks the mass of class-$k$ requests at decoding stage $j$; memory usage $M^n = \sum_{k,j} w_{k,j} x_{k,j}^n$ with per-slot weight $w_{k,j} = l_{0,k} + 1 + j$ (KV cache grows monotonically with generated tokens). One iteration = four ordered maps: **Execute → Arrive → Evict (LPF, least-progressed-first) → Admit**. In the saturated-input regime the whole system is deterministic: $X^{n+1} = F(X^n)$; the eviction-free subdynamics linearize to $X^{n+1} = B X^n$.
- **Instability of the "natural" eviction-free fixed point.** For homogeneous workloads the eviction-free equilibrium exists but is unstable under any admission rule that only checks instantaneous memory feasibility (one-step lookahead). System converges to a unique **worst-case limit cycle** where memory is monopolized by a single stage at a time and completions synchronize.
- **The $\tfrac{1}{2}$ throughput bound.** Along the worst cycle, throughput ratio equals $(2l_0 + l_1 + 1) / (2(l_0 + l_1))$, which lies in $(1/2, 1)$ and $\to 1/2$ as $l_1/l_0 \to \infty$. Loss is amplified by factor $\beta = (l_0+l_1)/(l_0+1)$ — long-output / retrieval-augmented regimes are the pathological case, not toy cases.
- **Heterogeneity-as-stabilizer (survival-polynomial mechanism).** Linearizing around the multi-class eviction-free equilibrium gives a characteristic polynomial whose roots depend on decoding-length arithmetic. **Theorem 3 (GCD criterion):** if $\gcd(l_{1,1},\dots,l_{1,K}) = g > 1$, unstable modes with modulus $1 + \Theta(1/l_0)$ sit on $g$-th roots of unity → synchronized eviction cycles. If $g = 1$ (coprime), all roots strictly inside the unit disc → global asymptotic stability of the eviction-free equilibrium.
- **Scheduling design principles derived, not benchmarked.** (a) Use coprimality of active $l_1$ values as a *diagnostic* for synchronization risk; (b) inject mild jitter into decode-length distribution to break gcd; (c) treat any eviction as an early-warning signal and rate-limit admission to the analytically derived $x^*$ before throughput collapses; (d) for multi-class serving, mix classes so coprimality is preserved in each batch/pool.

## Baselines
No prior systems compared head-to-head (this is a first-principles model). The implicit baseline the paper argues against is **myopic memory-feasibility admission** — the default rule in vLLM / continuous-batching schedulers where a request is admitted iff its current KV footprint fits, with no reservation for growth. The paper's contribution is proving that this policy is *provably unstable* rather than merely suboptimal.

## Evaluation setup
Numerical experiments exist and are non-trivial (not a pure-theory paper):
- **Model simulations (§6.1)** with stochastic Poisson arrivals — confirm empirical phase transition at $\bar{T}_{l_1-1}$; myopic admission accumulates unbounded backlog once arrival rate crosses the worst-cycle throughput even while below the naive eviction-free rate.
- **Vidur high-fidelity LLM simulator + real-GPU runs (§6.2)** — synchronization survives real batching, paged KV, and scheduler quirks. Mixing decoding lengths to reduce gcd improves throughput proportionally.
- **Rate-limited admission (§6.3)** — capping admissions at analytically derived $x^*$ preserves near-peak utilization and cuts per-iteration latency substantially.
- Metrics: worst-cycle throughput ratio, eviction rate, backlog growth, per-iteration latency.

## Claimed headline numbers
- **Throughput loss $\to 50\%$** as $l_1/l_0 \to \infty$ under myopic admission (Theorem 2 + worst-cycle formula).
- Worked example: $l_0=2, l_1=12 \Rightarrow$ ratio $\approx 0.54$, i.e. **~46% throughput loss** — a citable concrete data point.
- Unstable-mode modulus $1 + \Theta(1/l_0)$ when $\gcd > 1$ — quantifies how quickly synchronization compounds.
- Vidur experiments: mixing that increases gcd from 2→3 gives improvement proportional to synchronization reduction; ~16% gap between contiguous-block vs evenly-spaced configurations at eviction level 8.

## Fidelity / reproducibility
- Code: no public release found; Vidur is open-source so the simulator experiments are replicable in principle.
- Theoretical reproducibility: proofs are self-contained (paper is 101 pp; heavy appendix). Recurrence for perturbations $\Delta^{n-m}$ and the survival-polynomial construction are the two load-bearing derivations to re-verify.
- The 50% number is a *tight worst-case bound* under specific saturation + long-output assumptions — cite carefully in survey Section 2; do not over-generalize to arbitrary workloads.

## Relevance to survey
Cluster 5.4 (queueing theory / algorithmic). Provides the theoretical justification for why admission control matters at all — "service creates its own congestion." Load-bearing citation for Section 2 Background (Little's Law + service dynamics).

## Open questions surfaced
- **Stochastic decoding lengths.** GCD criterion is stated for deterministic $l_{1,k}$; real workloads have length distributions. Does an *effective* gcd (in expectation, or via measure-theoretic support) govern stability? Open.
- **Interaction with prefix caching / shared KV.** Model assumes per-request KV; modern serving reuses prefix caches. Do shared blocks break the memory-conservation identity the survival polynomial relies on?
- **Preemption vs eviction.** LPF eviction is analyzed; swap-to-CPU (as in vLLM v2) is not — likely changes the memory-release timing that drives synchronization.
- **Bridging to SLO-aware admission.** Paper is throughput-only. How does the coprimality insight interact with per-request latency SLOs? A coprime workload may stabilize throughput but reshuffle tail latency.
- **NEW open problem for the survey (Section 7 candidate):** *workload-arithmetic-aware admission control* — no current production scheduler exposes decode-length composition as an admission signal, a gap between theory (Ao et al.) and practice (vLLM / SGLang / TensorRT-LLM) worth flagging.
