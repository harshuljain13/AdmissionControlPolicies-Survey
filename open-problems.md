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

---

For the paper: pick 5-7 highest-signal problems; the ones with concrete peer-reviewer or paper-published evidence carry the most weight. Problems 1, 2, 3, 5 are strongest — all backed by CONCUR's ICML 2026 review thread which is publicly citable. Problems 11-14 added Day 2 (2026-09-10) from CONCUR/QLM/Chronos/SOLA deep reads. Problems 15-18 added Day 3 (2026-09-10) from FastServe/Shen et al./SLOs-Serve/Continuum deep reads. Each cites the specific paper's own text or design as evidence.
