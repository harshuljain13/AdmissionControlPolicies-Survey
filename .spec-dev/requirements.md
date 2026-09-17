# Requirements: closing the five reviewer gaps

*Raised by Bhau, 2026-09-16, against `paper.md` v0.2. Target: arXiv preprint.*

## Problem Statement

The survey makes four claims and proposes a methodology contract. Three of the
claims are supported by the corpus audit; the contract and the reproducibility
finding are **asserted rather than evidenced**, and a reviewer has said so. As
drafted, §6.1 proposes a minimum standard without showing that anything breaks
in its absence, and §6 refutes the "reproducibility crisis" framing on an
artifact count alone.

AdmitPerf was built to supply that evidence and has been pointed at the wrong
question — reproducing a single policy well — instead of the question the
survey actually needs answered: *what happens to a published policy when the
things no paper reports are allowed to move?*

## Goals

1. **G1 — Justify §6.1 empirically.** Every item in the methodology contract is
   backed by a measured failure: a knob that moves, a number that moves with it,
   and the contract item that would have caught it. (Reviewer #1)
2. **G2 — Position against non-survey work.** §1.1 compares four surveys and
   nothing else. Add benchmark/harness work (MLPerf Inference, serving
   benchmarks) and reproducibility-study work, and state what this paper adds
   over each. (Reviewer #2)
3. **G3 — Stress-test the unclaimed intersection.** §3.5 claims an empty cell.
   Test the borderline cases explicitly — partial agent-awareness, per-tenant
   policies extensible to deadlines — and either hold the claim with the
   near-misses named, or narrow it. (Reviewer #3)
4. **G4 — Operationalize fairness.** "Per-tenant Jain fairness index" appears
   exactly once in the paper, inside a bullet, undefined. Give it a formal
   definition, a measurement procedure, and a reference implementation.
   (Reviewer #4)
5. **G5 — Make the reproducibility claim precise.** Separate *artifact*
   reproducibility (13/38 released code — already evidenced) from *methodology*
   reproducibility (claimed, not evidenced). Show the second is the binding
   constraint. (Reviewer #5)

6. **G6 — Show the effect is not Chronos-specific.** Port one more published
   algorithm from a different family and reproduce the sensitivity with it. One
   specimen invites the objection that we picked a fragile one.
7. **G7 — Make the harness able to prove what it produced.** Every result
   records the code version that made it, and no run can silently overwrite
   another. We have already lost one result to this.
8. **G8 — Connect the two halves publicly.** The paper carries an appendix that
   reproduces each table with one command and links the repo; the repo cites the
   paper. Neither half stands alone.

## Non-Goals

- **Proving any specific policy is good.** Chronos is a specimen, not a
  deliverable. A successful horse race would weaken the paper's own thesis that
  cross-paper comparison is currently impossible.
- **Porting the rest of the roster.** Two ports are enough to show the effect is
  general. QLM is a large job and CONCUR needs an agent-session workload that
  does not exist; both belong to the follow-up paper.
- **Agent-level admission.** The survey's empty cell stays empty in this paper.
  Filling it is the next paper's job.
- **Multi-hardware generalization.** One model on one GPU. The claim is about
  methodology sensitivity, not about a number transferring across accelerators.
- **Rewriting the taxonomy.** Sections 3-5 stand as reviewed.
- **A new benchmark.** §6.1 is a contract, not a leaderboard, and stays one.

## Success Criteria

*(S7 and S8 added after the evidence audit.)*

| # | Criterion | Test |
|---|---|---|
| S1 | Every §6.1 item cites a measurement | No contract bullet without a number and a figure/table reference |
| S2 | The sensitivity result exists on real hardware | One policy, ≥4 knobs, admit rate or attainment spanning a reported range, run on the A10G |
| S3 | §1.1 covers non-survey work | ≥3 benchmark/reproducibility works positioned, each with "what this adds" |
| S4 | The intersection claim survives a stated attack | ≥4 borderline systems examined in a table, each with why it does not occupy the cell |
| S5 | Fairness is implementable from the paper alone | Formal definition + procedure + AdmitPerf implementation agreeing on a worked example |
| S6 | The reproducibility claim is split and both halves evidenced | Artifact count (have) + methodology sensitivity (build) stated as distinct findings |
| S7 | The sensitivity effect appears in a second, independently ported policy | A published non-Chronos policy shows a result swing on at least one of the six knobs |
| S8 | Any table in the paper can be regenerated from the repo | Appendix lists one command per table; every cited bundle records its git sha |

## Constraints

- **Time.** arXiv submission is the next milestone; the author is one person
  with a day job. Every task below fits one focused session.
- **Money.** Evidence that needs a GPU must be justified per run. Current
  estimate: one run, ~75 min of A10G, ~$1.40. The mock engine covers the rest at
  zero cost.
- **Honesty.** Results already on disk were produced by configurations we have
  since found to be broken. Those runs are usable as *evidence of sensitivity*
  and must not be re-presented as performance results.
- **AdmitPerf's adapter API v0 is frozen**, so evidence must be collectable
  without changing `Decision` / `AdmissionPolicy`.

## Open Questions

- **Q1.** Does the sensitivity study need a second policy (e.g. `queue_depth`)
  to show the effect is not Chronos-specific? *(Cheap: same run, already in the
  config.)*
- **Q2.** Is per-tenant fairness measurable on the current synthetic workload,
  which assigns tenants but has no per-tenant SLO differentiation?
- **Q3.** Does §6.1 keep its "baseline set" bullet naming CONCUR/Chronos/QLM
  when only one of the three is ported? Naming policies nobody can run may be
  the same failure the paper is documenting.
- **Q4.** arXiv first with the sensitivity study as a section, or split it into
  a companion measurement paper and cite it?
