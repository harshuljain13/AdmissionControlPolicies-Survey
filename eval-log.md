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

---

## Day 4 eval (2026-09-10)

**Deep-read this cycle**: AQUA, Service-Induced Congestion, Flow-Controlled Scheduling, FairBatching, ProServe, Clairvoyant, VTC (7 papers — 6 Tier 1 remaining + start of Tier 2). Day 3 also completed FastServe / Shen et al. / SLOs-Serve / Continuum.

**Cumulative**: 15 / 40 papers deep-read (37%) at 4 / 21 days consumed (19%). **~2× planned pace.**

### Q1: Right gap?
**YES.** No competing admission-control-only survey has appeared. Cross-comparison gap intact — 15 papers, no two agree on baselines. **AQUA venue upgraded**: confirmed at **ASPLOS '25** (DOI 10.1145/3676641.3715983), was arXiv-only in earlier records.

### Q2: Taxonomy holding?
**PARTIAL — significant refactor applied this cycle:**
1. **5.1 cluster split** into 5.1a (concurrent-batch server) vs 5.1b (serial edge). Clairvoyant is sole 5.1b entry; server admission and edge admission share almost no mechanism.
2. **5.3 fairness split** into task-fairness (FairBatching, sole entry) vs tenant-fairness (VTC, Equinox). Lumping would mislead readers looking for multi-tenant isolation.
3. **ProServe reclassified** 5.1 → 5.6 (scheduling-primary; no reject/defer/gate action; runs on Huawei Ascend 910B + JD.com xLLM proprietary stack).

All three landed in `taxonomy.md` this cycle as new sub-branches under Axis 2 (concurrency context) and Axis 3 (fairness type).

### Q3: Contributions defensible?
**YES + strengthened.** Reproducibility audit is much richer:
- **FairBatching only 90 LoC** vLLM changes (my earlier feasibility estimate 800-1200 was 10× too high).
- **AQUA has released code** at github.com/aquaml (was TBD in skeleton).
- **Shen et al. code released** (was TBD).
- **Continuum code released** as vLLM fork.
- **ProServe locked to Huawei/JD.com stack** — worse than expected.
Open problems: 24 (up from planned 10-15). Rich taxonomy of gaps for Section 8.

### Q4: On timeline?
**YES — AHEAD.** Days 1-4 hit exit criteria, zero buffer used. Parallel-agent throughput is running ~2× the serial estimate in steps.md.

### Q5: New open problems?
**YES — 6 new (19-24), all grounded evidence.**
19. Workload-arithmetic-aware admission (SIC — gcd/coprimality unused as signal in prod)
20. LIFO eviction fairness inversion (Flow-Controlled)
21. TPOT SLO ≠ streaming perception SLO (FairBatching, voice-agent gap)
22. Cross-domain retraining ownership for edge admission (Clairvoyant)
23. Prefix locality vs fairness composability (VTC vs DLPM 2.87× successor)
24. VTC never says no — composability with soft-decline admission (VTC)

### Notable surprises worth Section 6 callout
- **GCD coprimality criterion** governs stability (Service-Induced Congestion) — workload arithmetic, not just rate.
- **VTC has 2× tight bound with matching lower bound** — unusually clean theory for OSDI systems paper.
- **DLPM (arXiv:2501.14312) already claims 2.87× over VTC** — VTC successor exists.
- **ProServe on Huawei Ascend NPUs + JD.com xLLM** — widens deployment axis.
- **Clairvoyant: Alpaca has 4 Long examples of 52K** (0.008%) — reusable negative result.
- **FastServe headline is vs vLLM v0.1.7** — pre-continuous-batching-mature. Weakens framing.

### Decisions
- **Proceed to Day 5**: Tier 2 remaining (Equinox, Sun et al. tutorial, Jaillet et al., Ascendra, Chiron) + start Tier 3 (KVFlow, Cake, InferCept, Pie, ThunderAgent).
- **Applied this cycle**: taxonomy.md (2 sub-branches), open-problems.md (6 new), papers.md (AQUA venue), eval-log.md (this entry).
- **Deferred to Week 2 draft**: outline.md updates to reflect ProServe reclassification and 5.1/5.3 sub-splits (mechanical edits, no cognitive cost).
- **No scope change** to Roadmap.md.

### Health check
- Days consumed: 4 / 21 (19%)
- Papers deep-read: 15 / 40 (37%)
- Peer-reviewed top-venue admission papers confirmed: 9 (CONCUR ICML '26, QLM SoCC '24, Chronos Frontiers CS '26, SOLA MLSys '25, FastServe NSDI '26, Shen et al ICML '26, AQUA ASPLOS '25, VTC OSDI '24, Continuum ICLR '26 workshop)
- Open problems: 24
- Taxonomy: 4 axes + 4 sub-branches (signal-structure D2, SLO-granularity D3, fairness-type D4, concurrency-context D4)
