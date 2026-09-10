# Open Problems — Admission Control for LLM Serving

Draft of Section 8 of the survey. Each item cites specific peer-reviewer or paper evidence where possible.

## 1. Request-level vs agent-level admission — head-to-head unresolved

**Evidence**: CONCUR Reviewer Afcg (ICML 2026 OpenReview thread, submission 14315): *"the underlying problem can be addressed through more effective request-level scheduling (e.g., deciding whether to admit or defer a request under current memory constraints). I would therefore suggest that the paper include a discussion of this perspective in the final version."* CONCUR authors added Continuum comparison but no request-level baseline (QLM/Chronos/Fluid-WAIT). Field lacks empirical answer.

## 2. Online serving admission for agentic workloads

**Evidence**: CONCUR meta-review explicitly notes: *"the authors should explicitly state that the paper targets offline throughput-oriented agentic inference…and expand the discussion of…online serving."* All published agent-level admission work (CONCUR, Continuum, ThunderAgent) is offline. Online agent-level admission with SLO awareness is an open design point.

## 3. Fairness and starvation under admission control

**Evidence**: CONCUR Reviewers DhUu and Afcg both flagged. VTC/FairBatching address fairness but at request level; per-agent fairness under admission-controlled agentic serving is unaddressed.

## 4. Reasoning-trace-aware admission

**Evidence**: PASCAL (HPCA 2026) addresses phase-aware scheduling for reasoning LLMs but does not treat admission as first-class. o1/R1/DeepSeek-R1 style long-CoT traffic has fundamentally different KV growth patterns from chat or agentic; no admission policy classifies these upfront.

## 5. Reproducibility crisis

**Evidence**: Of 15+ admission-control papers surveyed, only Chronos has released code (simulator). CONCUR, Fluid-WAIT, FairBatching, ProServe, QLM, SOLA, Continuum: no released code as of 2026-09-10. Field cannot cross-verify claims.

## 6. Multi-tenant admission with per-tenant SLOs

**Evidence**: VTC handles fair queueing across users. FairBatching handles batch fairness. No policy handles per-tenant deadline SLOs with tenant-aware admission. Real production workloads (per Production Scenarios page: OpenAI, Anthropic, Cloudflare incidents) are multi-tenant.

## 7. Coupling admission with autoscaling and routing

**Evidence**: Chiron addresses autoscaling; SkyWalker/Block address routing. Admission is treated as a distinct box (per Admit/Queue/Route framing). No end-to-end model treats admission decisions jointly with replica selection and autoscaling. Production incidents (Anthropic Aug 29 wrong-pool routing) show this coupling matters.

## 8. Formal schedulability with LLM-specific WCRT

**Evidence**: Chronos provides WCRT bounds for LLM iterations but under strong assumptions. Sun et al. SIGMETRICS 2025 tutorial identifies queueing-theoretic gaps. Full formal schedulability analysis with realistic prefill/decode variance is open.

## 9. Admission for speculative decoding

**Evidence**: EAGLE, EAGLE-3, P-EAGLE work on speculative-decoding acceleration. When to admit a request that will use speculative decoding vs one that won't (draft-model resource contention) is an open admission question.

## 10. Admission under prefix-cache aware routing

**Evidence**: llm-d, SGLang RadixAttention, Mooncake handle prefix caching at routing/engine level. When admission and prefix-cache placement are decided together, the joint policy space is unexplored.

## 11. Signal granularity: aggregate vs per-session

**Evidence**: CONCUR (arXiv:2601.22705) deep read. CONCUR uses cluster-wide U_t (KV utilization) and H_t (hit rate) averages as its admission signal. The paper does not address whether a small number of long-tail agent sessions can poison the aggregate hit-rate signal and cause the controller to under-admit healthy sessions. Signal-granularity is orthogonal to admission-unit-granularity — an axis nobody has systematically explored.

## 12. Implicit admission via LP constraint relaxation

**Evidence**: SOLA (MLSys 2025) deep read. SOLA's alpha-percentile constraint-loosening in its LP formulation implicitly sacrifices (1-α)% of requests to keep the LP feasible. That is an implicit admission-control decision hidden inside a scheduler. Nobody in the cluster surfaces this as a first-class knob or characterizes its behavior under overload.

## 13. Principled admission fallback when SLO-scheduling is infeasible

**Evidence**: QLM (Patke et al., SoCC '24) deep read. When QLM's LP cannot satisfy all SLOs, the paper punts to "scale up, run EDF, or do admission control." That last option is a direct wedge: SLO-aware queue management and admission control are complementary, not alternatives, and no paper in the cluster closes the loop with a principled admission fallback policy for infeasible LP states.

## 14. Real-engine vs simulator gap for schedulability proofs

**Evidence**: Chronos (Frontiers CS 2026) deep read. Chronos's AC-FCFS ablation (throughput-matched token bucket vs formal admission test) is entirely in-simulator with shared α/β/γ parameters. On a real vLLM/SGLang, a matched-throughput token bucket may queue at the KV-cache admission point rather than the request queue, potentially closing the gap. Real-engine reproduction of AC-FCFS-vs-formal-admission is the obvious next study.

## 15. Preemption papers and admission-control papers do not cite each other

**Evidence**: FastServe (arXiv:2305.05920, NSDI '26) deep read. FastServe frames token-level preemption as strictly dominant over FCFS but never compares against admission-control / request-drop baselines (Llumnix, SHEPHERD, S³). Symmetrically, admission-control papers (CONCUR, QLM, Chronos) do not compare against preemption-based systems. The survey should surface this axis explicitly: is preemption a *replacement* for admission control, or *complementary* under different load regimes? This is a whole missing quadrant in the cross-comparison matrix.

## 16. Prompt-conditional reward distributions break i.i.d.-per-config assumptions

**Evidence**: Shen et al. Two-Layer Framework (arXiv:2602.07663, ICML 2026) deep read. The framework assumes each config induces a *stationary* reward-resource distribution, but in real LLM serving a config's per-request cost is *prompt-conditional* (input length, decode length, tool-call pattern). The paper's "contextual extension" future-work bullet contextualizes the config *choice*, not the reward-resource distribution — so the actual gap between the theory and LLM deployment is unaddressed. General open problem across all queueing-theoretic admission work.

## 17. Per-stage-of-agent SLOs are a taxonomy gap

**Evidence**: SLOs-Serve (arXiv:2504.08784) deep read. Multi-turn agent applications like ToolLLM have distinct SLOs per stage (tight TTFT on tool-call prefill, loose TPOT on reasoning decode, tight TPOT on final answer). Only SLOs-Serve models this; Llumnix (single deadline), DynamoLLM (single-stage energy-SLO), ExeGPT (throughput/latency, single-stage), VTC (fairness, no deadlines) all model single-stage SLOs. As agentic workloads dominate, per-stage-SLO-aware admission becomes essential and is systematically underexplored.

## 18. Transparency of soft-admission decline decisions

**Evidence**: SLOs-Serve deep read. Distinct from Problem #3 (outcome fairness under admission control). Problem #18 is about *decision transparency* under multi-SLO soft admission: SLOs-Serve "guarantees admitted SLOs by declining others" — but nobody characterizes *which* cohorts (which tenants, which SLO tiers, which prompt shapes) get systematically declined under overload. VTC solves this for token throughput; nobody solves it for multi-SLO decline decisions.

## 19. Workload-arithmetic-aware admission

**Evidence**: Service-Induced Congestion (arXiv:2606.15555) deep read. Theorem 3 (GCD criterion): if gcd of active decoding lengths > 1, unstable modes appear on g-th roots of unity → synchronized eviction cycles; if gcd = 1 (coprime), all roots strictly inside unit disc → global stability. This is *workload arithmetic* — not rate — governing stability. **No production scheduler (vLLM / SGLang / TensorRT-LLM) exposes decode-length gcd/coprimality as an admission signal.** Clean theory-to-practice gap.

## 20. LIFO eviction fairness inversion

**Evidence**: Flow-Controlled Scheduling (arXiv:2604.11001) deep read. Algorithm 2 uses LIFO eviction (newest arrivals evicted first under overflow) to minimize wasted decode work — but this is a fairness inversion for interactive workloads: short recent requests get starved. The paper never analyzes starvation under interactive SLOs, and no other admission-control paper addresses LIFO-eviction fairness properties.

## 21. TPOT SLO ≠ streaming perception SLO

**Evidence**: FairBatching (arXiv:2510.14392) deep read. Time-budget formulation assumes per-token TPOT SLOs. Unclear how it degrades under end-to-end deadline SLOs or *streaming perception SLOs* (voice agents needing bounded inter-chunk gaps, not per-token TPOT). As voice/streaming applications grow, the "TPOT = perception" assumption breaks.

## 22. Cross-domain retraining ownership for edge admission

**Evidence**: Clairvoyant (arXiv:2606.07248) deep read. Zero-shot cross-distribution accuracy collapses to 52.7-65.3%; ~240-request domain retraining is required per new workload. On edge devices (Ollama/llama.cpp deployments) it is unclear who owns retraining — the model provider? The edge orchestrator? The end-user? Also: the paper flags that "curated instruction datasets are degenerate for length prediction" (Alpaca has 4 Long examples of 52K = 0.008%), a reusable negative result for anyone training length predictors.

## 23. Prefix locality vs fairness composability

**Evidence**: VTC (Sheng et al., OSDI '24) deep read + follow-up DLPM (arXiv:2501.14312). VTC's least-served-first scheduling shatters prefix-cache reuse. DLPM already claims 2.87× throughput over VTC by co-optimizing prefix-cache hits and fairness. General open problem: how does fair admission compose with prefix-cache locality? No policy in the cluster explicitly optimizes both.

## 24. VTC never says no — composability with soft-decline admission

**Evidence**: VTC deep read. VTC is a *scheduler*, not an *admission gate* — it never declines a request, only reorders. How VTC (or any pure fair-share scheduler) composes with a soft-decline admission layer (SLOs-Serve style) is completely unaddressed. Adjacent to Problem 18 (decision transparency) but distinct: this is about the *composability* of fair scheduling with declining admission, not the transparency of the decline decision.

## 25. Fairness-of-perception vs fairness-of-tokens — metric entanglement

**Evidence**: Equinox (arXiv:2508.16646) deep read. VTC equalizes served tokens. Equinox argues equal tokens ≠ equal user experience (latency, GPU util diverge) and introduces a dual counter HF = α·UFC + β·RFC that folds latency and resource-efficiency into the fairness metric itself. But this entangles the fairness *definition* with the scheduling *mechanism*: Equinox's reported "+13% fairness vs VTC" is measured on a Jain index over Equinox's own HF — not on a definition-neutral fairness metric (e.g., latency-percentile spread, TTFT variance across tenants). The field has no agreed-upon *mechanism-independent* fairness metric for LLM serving. Related but distinct from Problem 3 (starvation) and Problem 6 (per-tenant SLO): this is about the *measurement layer*, not the policy layer. Adjacent to Problem 24 — pure fair-share schedulers proliferate (VTC, Equinox, DLPM, FairBatching) each defining fairness differently, making apples-to-apples comparison impossible.

## 26. Prediction-driven fair scheduling under distribution shift

**Evidence**: Equinox depends on MoPE (3× BERT-base + length-router) predicting output length, latency, TPS, and GPU-util per prompt. VTC needs zero prediction. Under distribution shift (new tenants with code-heavy, non-English, or reasoning-CoT prompts unlike LMSYS training data) MoPE's L1 error will rise — and every scheduling decision uses these predictions. No graceful-degradation path is measured. Same fragility Clairvoyant (Problem 22) surfaced for length prediction, now compounded across four predicted signals feeding a fairness controller.

## 27. Practical Gittins-index policies for LLM admission

**Evidence**: Mitzenmacher & Shahout, SIGMETRICS 2025 tutorial (arXiv:2503.07545). Classical scheduling theory (Gittins index) is provably optimal under wide conditions but has never been operationalized for LLM serving. The tutorial argues this is a first-order gap between queueing theory and current LLM admission practice.

## 28. Distributional (not point) service-time predictions

**Evidence**: Mitzenmacher & Shahout tutorial. Current length-prediction work (Clairvoyant, S³, proxy-model predictors) returns point estimates of output length. Scheduling theory says the *distribution* matters — variance shape governs tail behavior. Extends Problem 16 (prompt-conditional distributions) on the policy side: nobody consumes distributional predictions as scheduler input.

## 29. Heterogeneous-GPU prefill/decode balance + lower-tier-GPU sizing

**Evidence**: Mitzenmacher & Shahout tutorial. Multi-generation GPU fleets (H100 + A100 + L40S + T4) require admission decisions to reason about which GPU tier can serve which request without SLO violation. No published policy addresses this hardware-tier admission dimension explicitly.

## 30. Learning-augmented framing of α-accuracy — robustness/consistency Pareto

**Evidence**: Jaillet et al. "Online Scheduling for LLM Inference with KV Cache Constraints" (arXiv:2502.07115). Their MC-SF policy provides Ω(√n) lower bound and O(1) upper bound under structured arrival + α-accurate predictions. Real production predictions have unknown α; a learning-augmented (robustness/consistency Pareto) framing is unaddressed. Extends Problem 8 (formal schedulability) with prediction-quality-conditioned bounds.

## 31. Autoscaling-aware routing under class asymmetry

**Evidence**: Chiron (arXiv:2501.08090) + QLM (SoCC '24), both same Patke/Iyer group. Chiron autoscales replicas; QLM queues per-replica. Neither addresses the third axis: routing across a heterogeneous replica set (different instance types running different model variants under different admission policies). Sub-problem of Problem 7. Same group, no composition paper published.

## 32. Predictive drop-at-admission using SLO-risk predictor

**Evidence**: Ascendra (arXiv:2504.20828). Ascendra uses an SLO-risk predictor to promote LP→HP but drops requests only *reactively* (after TTFT is already blown in queue). Turning the same predictor into a *proactive* admission gate — dropping at arrival when SLO violation is predicted inevitable — is unstudied in LLM serving.

## 33. Interaction between admission control and workflow-aware KV eviction

**Evidence**: KVFlow (NeurIPS 2025, arXiv:2507.07400) + CONCUR (ICML 2026). CONCUR caps concurrent sessions to fit working set; KVFlow evicts KV based on steps-to-execution. Under joint deployment, CONCUR reduces the pressure that would trigger KVFlow's eviction. Neither paper runs the joint config. Bridges clusters 5.2 (agent admission) and 5.5 (KV management).

## 34. Cake hybrid-fill fallback under queue depth

**Evidence**: Cake (ICML 2025, arXiv:2410.03065). Cake speeds single-request TTFT via hybrid compute-vs-load KV, but hybrid fill burns GPU cycles pure-load would spare. No characterization of the queue-depth threshold at which hybrid-fill *hurts* aggregate goodput — a natural admission-adjacent research question.

## 35. Joint intercept-KV-management + admission POMDP

**Evidence**: InferCept (ICML 2024, arXiv:2402.01869) + Continuum (arXiv:2511.02230). InferCept's `WastePreserve/Discard/Swap` cost model is local to a single intercept decision under unknown-duration tool calls. Joint scheduling of KV-mgmt AND admission/preemption under stochastic intercept durations = POMDP with unknown per-tool priors. No published treatment.

## 36. Policy portability across programmable serving substrates

**Evidence**: Pie (SOSP 2025, arXiv:2510.24051). Pie ships generation-loop handlers + explicit KvPage management but no cross-inferlet scheduler API. If QLM/CONCUR/FairBatching get independently re-implemented on Pie, SGLang, and vLLM, apples-to-apples comparison dies. A minimal common admission-policy API (admit/reject/preempt/migrate with standardized signals) is unbuilt.

## 37. Tool-asset admission control

**Evidence**: ThunderAgent (ICML 2026 Spotlight, arXiv:2602.13692). ThunderAgent is the first cluster paper to treat disk/ports/sandboxes as first-class scheduled resources, not just KV/GPU. Cluster 5.2 currently collapses LLM-side and tool-side admission; the survey should split this axis. Also: program migration for HBM balancing may conflict with prefix-cache locality (extends Problem 10).

---

For the paper: pick 5-7 highest-signal problems; the ones with concrete peer-reviewer or paper-published evidence carry the most weight. Problems 1, 2, 3, 5 are strongest — all backed by CONCUR's ICML 2026 review thread which is publicly citable. Problems 11-14 added Day 2 (2026-09-10) from CONCUR/QLM/Chronos/SOLA deep reads. Problems 15-18 added Day 3 (2026-09-10) from FastServe/Shen et al./SLOs-Serve/Continuum deep reads. Problems 19-24 added Day 4 (2026-09-10) from Tier 1 completion + VTC. Problems 25-37 added Day 5 (2026-09-10) from Equinox / Mitzenmacher-Shahout / Jaillet / Chiron / Ascendra / KVFlow / Cake / InferCept / Pie / ThunderAgent. Each cites the specific paper's own text or design as evidence.

**Note (Day 5)**: Problem 5 (Reproducibility crisis) needs refinement — as of Day 5, released-code count is ~11/25 papers (QLM, Chronos, FastServe, Shen et al., Continuum, Clairvoyant, AQUA, VTC, KVFlow, InferCept, Pie, ThunderAgent, Cake). Reframe from "only Chronos has code" to: "even where code exists, cross-comparison is impossible because each uses different engines/models/traces/baselines — the reproducibility crisis is at the *methodology* level, not the *artifact* level." Apply in Week 2 draft.
