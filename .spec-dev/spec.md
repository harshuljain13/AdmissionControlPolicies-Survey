# Spec: closing the five reviewer gaps

Status: Draft
Last updated: 2026-09-17

## Summary

Add one empirical section to the survey — a **sensitivity study** in which a
single faithfully-ported policy is held fixed while the parameters no paper
reports are moved, and the reported result moves with them. That section
supplies the justification §6.1 currently lacks (G1) and the methodology half of
the reproducibility finding (G5). Three smaller, desk-based edits close the
remaining gaps (G2, G3, G4). AdmitPerf becomes the contract's reference
implementation rather than a reproduction attempt.

## Design Decisions

### D1: What the empirical section argues

**Options considered**
- (a) Reproduce Chronos faithfully and report whether it beats baselines.
- (b) Compare several ported policies head-to-head.
- (c) Hold one policy fixed, move the unreported knobs, report the range.

**Chosen**: (c).

**Why**: The paper's own second finding is that cross-paper comparison is
impossible from the literature alone. (a) and (b) would quietly contradict it —
if a clean comparison were available, the crisis would be overstated. (c) is the
only option whose result *is* the thesis: the same policy, faithfully
implemented, reads anywhere from refuse-everything to admit-everything depending
on choices that are currently nobody's obligation to report. It is also the
cheapest, because the knobs are mostly free to move.

### D2: Which knobs, and what each one licenses in §6.1

Each row becomes one contract item. Nothing goes in §6.1 that does not have a
row here.

| Knob | Observed effect | Evidence status | Contract item it justifies |
|---|---|---|---|
| Cost-model constant γ inherited from the source paper's hardware | admit rate 1.8% → 100% | measured (policy replay) | Parameter provenance: which parameters were fitted on the evaluation hardware, which inherited |
| Offered load relative to capacity | winner flips: baseline wins at ~0.5x, `queue_depth` +12.2 pts at ~2x | half measured (0.5x on A10G, 2x on mock only) | Load reported as a multiple of measured serveable rate, plus how capacity was measured |
| Deadline relative to unloaded latency (500ms vs measured p50 418ms) | a formally correct policy refuses 100% | measured (A10G) | Deadlines reported as a multiple of measured unloaded latency |
| Signal liveness (KV usage on a 0.5B) | `kv_threshold` admits 100%, a no-op wearing a policy's name | measured (A10G, twice) | Report the observed range of the signal the policy reads |
| Repeat count | 0%, 38%, 0% admitted across three identical repeats | measured (A10G) | >= 3 repeats, spread reported; a single run is not a result |
| Context budget vs trace token distribution | 32% HTTP 400s recorded as overload failures | measured (A10G) | Report `max_model_len` against the trace's token distribution |

**Six items, six measurements.** S1 is satisfied by construction.

### D3: Which claims need new GPU time

**Chosen**: exactly one run — `experiments/regimes.yaml`, 4 situations x 5
policies x 3 repeats, ~75 min, ~$1.40.

**Why**: five of the six rows are already measured on the A10G. Only the
load-sensitivity row has its overload half on the mock engine, and a paper
cannot rest a headline row on a stub engine. Everything else is replay or
already banked.

### D4: How the already-broken runs are used

**Chosen**: present them as sensitivity evidence with their defects named in the
caption, never as performance numbers.

**Why**: a run where a third of traffic returned HTTP 400 is worthless as a
measurement of a policy and is *excellent* evidence that an unreported
configuration choice can masquerade as overload. That is the paper's argument.
The framing must be explicit or a reviewer will read it as sloppiness — which is
how it looked to us until we traced it.

### D5: Fairness (G4)

**Chosen**: define a metric named **tenant SLO fairness (F)**, computed as
Jain's index [Jain, Chiu & Hawe 1984] over **per-tenant offered attainment**,
not over admitted counts or throughput.

**Naming**: the metric gets a plain English name; the formula keeps its
citation. Renaming a forty-year-old standard index after this tool would read
as reinventing prior art, which is an expensive thing to do in a paper whose
credibility rests on a reproducibility audit. The contribution is not the
formula, it is the choice of quantity it is computed over.

**Why**: an admission policy can trivially equalize admitted counts while
concentrating deadline misses on one tenant. Attainment is the quantity the SLO
is written against, so it is the one fairness should be measured on. The
survey's §5.3 distinguishes task- from tenant-fairness but never says which
quantity enters the index; this makes it unambiguous and implementable.

Reference implementation lands in AdmitPerf (`bench/fairness.py`), which already
records `tenant_id` on every decision and outcome. A worked example in the paper
shows the index discriminating between two policies with identical aggregate
attainment.

### D6: Intersection stress test (G3)

**Chosen**: a table of >= 4 borderline systems, each with the specific property
it lacks. Candidates: SAGA (agent-level, fairness — online + TTFT/TBT
decomposition unestablished), QLM (queue-managed, tenant-aware — no deadline
admission), CONCUR (agent-level concurrency — fairness not per-tenant), Token
Pools (gateway admission — single-node, not agent-level), plus any per-tenant
scheduler extensible to deadlines.

**Why**: the claim is a negative existential. Negative claims are only credible
when the strongest near-misses are named and dismissed on stated grounds.

### D7: Related work (G2)

**Chosen**: extend §1.1 beyond surveys to (i) benchmark/harness work — MLPerf
Inference, vLLM's own benchmark suite, any serving-benchmark paper; (ii)
reproducibility studies in systems/ML; (iii) methodology-contract precedents in
other fields. Each row states what this paper adds.

**Why**: the reviewer's "missing related work" is not about more surveys; it is
that a paper proposing a measurement contract has not positioned itself against
the literature on measurement contracts.

### D8: Which algorithms to port, and in what order

**Chosen**: one more published port for the preprint — **FluidWait-inspired** —
with **TokenBudget** if time allows. QLM and CONCUR wait for the follow-up.

**Why**: one specimen invites "you picked a fragile one". A second port from a
different family answers that. The choice is driven by cost and by whether the
policy can do anything on our hardware at all:

| Order | Policy | Family | Why now, or why not |
|---|---|---|---|
| 1 | FluidWait-inspired (arXiv:2504.11320) | scalar threshold on queue + KV | Published, cheap, and it reads `waiting_requests`, which `docs/policies.md` says is the signal that binds in our regime. It will actually act rather than sit inert. |
| 2 | TokenBudget (derived) | offered tokens vs capacity | Cheap, SLO-aware, and honest about not being a port. A stronger baseline than a bare threshold. |
| 3 | QLM-inspired (SoCC 2024) | virtual-queue LP | The convincing third family, but a large job. Follow-up. |
| 4 | CONCUR-inspired (arXiv:2601.22705) | agent-level | Needs an agent-session workload that does not exist. This is the next paper's seed, and the survey's empty cell. |

**The regime table decides this.** `docs/policies.md` already states that on a
small model with a low `max_num_seqs`, the binding constraint is the concurrency
cap and the signal that moves is `waiting_requests`. That predicted the
`kv_threshold` result before we measured it. Porting a policy whose signal is
known dead on our hardware would produce another inert row and teach nothing.

### D9: What a port must ship with

Every port, no exceptions, so a port is never a loose end:

1. The policy, named `*_inspired` unless it is bit-exact with the paper.
2. **A deviation list** — every place the paper did not say enough to implement
   without a choice, and what we chose.
3. Unit tests for the decision function at its boundaries.
4. A **liveness check**: evidence that its signal moved in the regime we ran it
   in. A policy that cannot fire is not a result.
5. A row in `which-policy-when.yaml` so it is exercised at every load.

**The deviation lists are the survey's evidence, not an apology.** Each entry is
something a paper left unspecified that changes the answer. Chronos's list
already contains the cost constants that swing admit rate from 1.8% to 100%.
They go in the appendix as a table.

### D10: How the two repos reference each other

**Chosen**: the paper carries a reproduction appendix; the repo carries the
citation and a section explaining which paper claim each check supports.

- **Survey → AdmitPerf**: an appendix with one command per table or figure, the
  repo URL, the commit each table was produced at, and the hardware. A reader
  must be able to regenerate a table without asking us anything.
- **AdmitPerf → survey**: README states that this is the reference
  implementation of the contract proposed in the paper, cites it, and maps each
  executable check to the contract item it enforces.

**Why**: the two halves are one argument. A repo with no paper is a tool nobody
asked for; a paper with no repo is the exact failure it is documenting.

## Architecture / Approach

```
AdmitPerf (evidence engine)              Survey (claims)
--------------------------               ---------------
bench capacity   ---------------------->  load as multiple of capacity      (item 1)
infra calibrate  ---------------------->  deadline as multiple of unloaded  (item 2)
policy param provenance in manifest ---->  fitted vs inherited              (item 3)
signal_was_healthy + signal range ------>  signal liveness                  (item 4)
repeats + spread in compare/decide ----->  >= 3 repeats                     (item 5)
check_context_budget (refuses to start) ->  context budget vs trace         (item 6)
bench fairness (new) ------------------->  per-tenant Jain on attainment    (G4)
```

Every contract item is enforced by something executable. That is the paper's
answer to "why this minimum": not taste, but six failures we hit and the checks
that now prevent each.

## Data Model / Schema

Additions to the run manifest (already partly present):

| Field | Purpose | Status |
|---|---|---|
| `situation`, `offered_rate` | the load axis | done |
| `workload` snapshot | what traffic was generated | done |
| `policy_params` | the knobs as set | done |
| `parameter_provenance` | per-parameter: `fitted` \| `inherited` \| `default` | **to build** |
| `signal_range` | min/max of the signal each policy read | **to build** |
| `capacity_ref` | serveable rate this run's load is relative to | **to build** |

## Edge Cases and Error Handling

- **A policy that reads no signal** (`no_admission`) → `signal_range` is absent,
  not zero. A zero would read as "the signal never moved".
- **Capacity probe never fails** → report "capacity is at or above the top rung"
  rather than inventing a number. Already handled.
- **Single-tenant workload** → the fairness index is undefined, not 1.0. An
  index of 1.0 would claim perfect fairness was demonstrated.
- **A run whose scrapes mostly failed** → already flagged; must be excluded from
  the sensitivity table, since it measures the harness, not the knob.

## What's Explicitly Not in v1

Everything in Non-Goals, plus: γ fitting (the *cause* of the largest swing is
identified and quantified; fixing it is future work and is more honest as an
open problem), and the `random_shed` control policy (needed to judge Chronos on
the merits, not needed to show sensitivity).

## Dependencies

- Modal GPU access with a payment method on file — **resolved 2026-09-16**.
- AdmitPerf `bench capacity`, `bench decide`, context-budget guard — **built**.
- Survey repo `.spec-dev/` — this folder.

## Open Questions (resolved)

- **Q1** → Yes, include `queue_depth` in the sensitivity table. It is already in
  `regimes.yaml`, costs nothing extra, and one-policy sensitivity invites the
  objection that Chronos is unusually fragile.
- **Q2** → No. The current workload assigns tenants without differentiating
  their SLOs, so fairness gets a definition, an implementation and a worked
  example, but not a headline measurement. Stated as a limitation.
- **Q3** → Reword the bullet: name the *properties* a baseline set must cover
  (agent-level, deadline-aware, queue-managed) and cite the policies as
  examples, noting only one has a public port. Requiring papers to run
  unavailable code is the failure mode the survey documents.
- **Q4** → arXiv first, sensitivity study as a section. A companion paper
  doubles the writing and the reviewer asked for justification *in this paper*.
