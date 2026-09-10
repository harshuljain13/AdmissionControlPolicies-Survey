# Bi-daily Evaluation Log

Per `steps.md`, run 5-question check at end of every even-numbered day. Stop and reconsider if any "no" or "unclear" for two consecutive checkpoints.

---

## Day 2 eval (2026-09-10)

**Deep-read this cycle**: CONCUR, QLM, Chronos, SOLA (4 anchor papers across all 4 taxonomy quadrants).

### Q1: Are we still filling the right gap?
**YES — strengthened.**
- No new admission-control-specific survey has landed since 2026-09-10 morning check.
- Deep reads confirm the "no cross-comparison" gap: CONCUR compares only to Continuum (post-rebuttal), QLM to vLLM/EDF/SHEPHERD, Chronos to FCFS/EDF/SLAI/AC-FCFS, SOLA to vLLM-D/vLLM-S/SJF. **Zero overlap between these baseline sets.** Cross-comparison gap is real.

### Q2: Is the taxonomy holding up?
**PARTIAL — needs signal-axis refinement.**
- All 4 papers fit the (Unit × Setting × SLO-awareness) axes cleanly.
- Signal axis needs sub-branches: (a) scalar heuristic, (b) dual-gate conjunction (CONCUR's U AND H insight), (c) LP-based composite (SOLA + QLM), (d) formal WCRT (Chronos). Updating `taxonomy.md` this cycle.

### Q3: Are claimed contributions still defensible?
**YES + strengthened.**
- **Reproducibility audit is much sharper after deep reads**: QLM (2 commits, Gurobi dependency, no CI, "code drop not maintained artifact"), Chronos (simulator-only, roofline-derived kernel params never measured on real silicon), SOLA (no code released despite MLSys venue), CONCUR (no code released). Section 6 has real substance now.
- 4 new open problems surfaced (see below) — pushes count from 10 to 14.

### Q4: On timeline?
**YES.**
- Day 1 target (15 skeletons + commit): DONE
- Day 2 target (deep read 4 anchor papers): DONE
- No spillover into buffer (Day 14, Day 20-25).

### Q5: NEW open problems discovered?
**YES — 4 new, all with grounded evidence.** Adding to `open-problems.md`:

1. **Signal granularity: aggregate vs per-session** (from CONCUR deep read). CONCUR uses cluster-wide U_t and H_t averages. Long-tail agent sessions could poison the hit-rate signal and cause the controller to under-admit healthy sessions. Signal-granularity is orthogonal to admission-unit-granularity.
2. **Implicit admission via LP constraint relaxation** (from SOLA deep read). SOLA's alpha-percentile constraint-loosening implicitly sacrifices (1-α)% of requests to keep the LP feasible — an implicit admission-control decision hiding inside a scheduler. Nobody surfaces this as a first-class knob.
3. **Principled admission fallback when SLO-scheduling infeasible** (from QLM deep read). QLM's own paper punts to "scale up, EDF, or admission control" when the LP can't satisfy all SLOs. No principled admission policy is proposed. Direct hook for admission-control-primary work.
4. **Real-engine vs simulator gap for schedulability proofs** (from Chronos deep read). Chronos's AC-FCFS ablation is entirely in-simulator with shared α/β/γ. On a real vLLM/SGLang, a throughput-matched token bucket may queue at the KV-cache admission point rather than the request queue, potentially closing the gap. Real-engine reproduction is the obvious next study.

### Notable insights beyond the 5 questions
- **CONCUR's dual-gate (U AND H) is a taxonomically important refinement** — not just "KV pressure" but "KV pressure conjoined with hit-rate collapse." Update `taxonomy.md`.
- **QLM's honesty about multi-model interactive workloads** — the paper openly states swap cost > TTFT SLO defeats their own approach. Rare and citable in survey Section 6.
- **Chronos author affiliation** — Univ. Saïda (Algeria) + Prince Sultan Univ. (KSA). Unusual for an LLM systems paper (real-time community not typically in ML/systems venues). Worth noting for community-diversity in the survey conclusion.
- **SOLA reimplemented SplitFuse** on vLLM rather than compared to upstream Sarathi-Serve, explicitly to avoid operator-level noise — unusually honest baseline hygiene. Citable in Section 6 methodology audit.

### Decisions
- **Proceed to Day 3**: read remaining Tier 1 papers (FastServe, Shen et al., SLOs-Serve, Continuum).
- **Update this cycle**: `open-problems.md` (add 4), `taxonomy.md` (refine signal axis).
- **No scope change** to `Roadmap.md`.
- **No changes needed** to Track 2 (AdmitBench) deferral.

### Health check
- Days consumed: 2 / 21
- Papers deep-read: 4 / 40
- Open problems: 14 (up from 10 planned)
- Reproducibility audit rows: 4 done, 11 more to fill by Day 6
