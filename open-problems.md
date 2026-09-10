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

---

For the paper: pick 5-7 highest-signal problems; the ones with concrete peer-reviewer or paper-published evidence carry the most weight. Problems 1, 2, 3, 5 are the strongest — all backed by CONCUR's ICML 2026 review thread which is publicly citable.
