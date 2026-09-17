# Tasks

Legend: `[ ]` not started · `[x]` in progress · `[✓]` done

One rule for ordering: **nothing expensive runs until the thing that records it
is trustworthy.** We already lost one result to a silent overwrite.

Each task is one sitting. If it looks like two, it is two.

---

## Phase A — Make the harness able to prove what it produced

*No GPU. Free. Do this first.*

- [ ] **A1** Record the git commit and whether the working tree was dirty in
      every run manifest. Today a bundle says `admitperf 0.0.1`, a version that
      never changes, so we cannot tell which code produced which result.
- [ ] **A2** Refuse to write into a results directory that already has runs in
      it, unless explicitly told to. This is what destroyed the HTTP 400
      evidence.
- [ ] **A3** Record `signal_range` per run: the lowest and highest value of the
      signal each policy read, and absent rather than zero when it reads none.
      Turns "the signal never moved" from a hand dig into a field.
- [ ] **A4** Record `capacity_ref`: the serveable rate this run's load is
      expressed against, when one is known.
- [ ] **A5** Re-run the test suite and confirm all four fields appear in a fresh
      bundle from the mock engine.

---

## Phase B — Bank the evidence we already have, stated correctly

*No GPU. Free. Uses `evidence-audit.md` verdicts, not memory.*

- [ ] **B1** Build the sensitivity table: one row per knob, with value range,
      effect, and an honest provenance label (`A10G` / `analysis` / `mock`).
      Output: `survey/notes/sensitivity-table.md`.
- [ ] **B2** Correct the two mis-stated rows. Repeat variance is **three seeds,
      not three identical runs**. The γ cliff is an **analytical** sensitivity
      of the admission test, with frozen system state, not a live measurement.
- [ ] **B3** Turn the γ sweep into a figure with its method in the caption:
      fitting disabled, state frozen, arrivals synthetic.
      Output: `survey/figures/gamma-cliff.png`.
- [ ] **B4** Write the signal-liveness row from the measured range
      (0.0000–0.0046 against a 0.9 threshold, 485 decisions). This one is final.
- [ ] **B5** Draft §6.2 "Why this minimum": six short subsections, each opening
      with the measurement and closing with the rule it justifies.

---

## Phase C — Survey desk work

*No GPU. Free. Can run in parallel with everything.*

- [ ] **C1** Extend §1.1 past surveys: benchmark and harness work (MLPerf
      Inference, vLLM's benchmark suite, one serving-benchmark paper) and two
      reproducibility studies, each with what this paper adds. (Reviewer #2)
- [ ] **C2** Stress-test the empty cell in §3.5: a table of at least four
      near-misses (SAGA, QLM, CONCUR, Token Pools) each with the one property it
      lacks and a citation. Hold or narrow the claim in the text. (Reviewer #3)
- [ ] **C3** Define **tenant SLO fairness (F)**: Jain's index
      [Jain et al. 1984] over per-tenant offered attainment, with why attainment
      rather than admitted counts. Plain name in the text, cited formula.
      (Reviewer #4)
- [ ] **C4** Reword the §6.1 baseline-set bullet to require *properties*
      (agent-level, deadline-aware, queue-managed) rather than three policies,
      only one of which has a public port.
- [ ] **C5** Split the reproducibility finding in two: artifacts (13 of 38,
      already counted) and methodology (measured, six knobs). Say plainly that
      the second is the binding one. (Reviewer #5)

---

## Phase D — The measured run

*GPU. About 90 minutes, about $1.50. Only after Phase A.*

- [ ] **D1** Dry-run the whole shape on the mock engine at short duration and
      confirm `bench decide` produces one row per situation.
- [ ] **D2** `infra up` → `infra smoke` → **`infra calibrate`** → `bench
      capacity` → paste the measured `loads:` → `bench run` → `bench decide` →
      `bench report`. Do not tear down in between. Calibrate is what gives row 6
      its denominator.
- [ ] **D3** Re-run the 2048-context configuration for one repeat and **keep the
      bundle**. This recreates the destroyed HTTP 400 evidence. ~3 minutes.
- [ ] **D4** Fill the load row and the deadline row with real numbers. Retire
      the mock figures from the paper; keep them in the repo.
- [ ] **D5** Record both runs in `docs/results.md` with full provenance.

---

## Phase E — Second port, so the effect is not Chronos-only

*Small GPU cost, about $0.50.*

- [ ] **E1** Port **FluidWait-inspired** (arXiv:2504.11320): policy, unit tests,
      registry entry. It reads queue depth, which is the signal that actually
      moves on our hardware.
- [ ] **E2** Write its **deviation list** — every place the paper underspecified
      and what we chose. This is appendix material, not an apology.
- [ ] **E3** Add it to `which-policy-when.yaml` and re-run the situations it
      needs. Confirm its signal moved (Phase A3 makes this a field, not a dig).
- [ ] **E4** Reproduce **one** sensitivity knob with it — load is cheapest — and
      report whether the effect holds outside Chronos. If it does not, say so;
      that is also a result.
- [ ] **E5** *(if time)* Port **TokenBudget** as a cheap SLO-aware baseline,
      clearly labelled as derived rather than ported.

---

## Phase F — Write it into the survey, and connect the repos

- [ ] **F1** Land §6.2 with every claim traced to a bundle and a commit.
- [ ] **F2** Appendix: one command per table or figure, the repo URL, the commit
      each was produced at, and the hardware. A reader regenerates a table
      without asking us anything.
- [ ] **F3** Appendix: the port deviation lists, Chronos and FluidWait side by
      side, as the concrete form of "papers underspecify".
- [ ] **F4** AdmitPerf README: state that it is the reference implementation of
      the contract in the paper, cite the paper, and map each executable check
      to the contract item it enforces.
- [ ] **F5** Survey README and `paper.md`: link the repo, name the commit the
      results came from.
- [ ] **F6** Re-read the five reviewer comments one at a time and write, in one
      sentence each, where the paper now answers them.

---

## Phase G — Submit

- [ ] **G1** Full pass for claims that outran their evidence. Every number gets
      a provenance label.
- [ ] **G2** Compile, check figures and references, submit to arXiv.

---

## Phase H — After the preprint

- [ ] **H1** Port QLM-inspired (SoCC 2024) — the third family.
- [ ] **H2** Build an agent-session workload.
- [ ] **H3** Port CONCUR-inspired on top of it.
- [ ] **H4** The head-to-head study: which policy wins, under which conditions.
      Possible only once the contract exists, which is what this preprint
      establishes.
- [ ] **H5** Dashboard legibility pass: the charts and the vocabulary are opaque
      to anyone who did not build them. Pick the three terms that carry the
      argument, explain those, cut the rest.

---

## Blocked by

- Phase D is blocked by Phase A. Running an expensive experiment into a harness
  that cannot say what produced it is how we got here.
- D4 is blocked by D2 and D3.
- E4 is blocked by E1.
- F1 needs B5 and D4.

## Notes

- **Phases B and C need no GPU and no Modal account.** If a day is short, spend
  it there.
- **Phase D is the only real spend in the whole plan**: about $1.50.
- **If a port turns out to be hard**, stop and write down why. "This paper could
  not be implemented from its text" is a finding the survey wants, not a failure.
