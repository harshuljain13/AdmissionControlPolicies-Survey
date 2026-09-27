# Workshop proposals: MLSys 2027 and ICLR 2027

Drafted 2026-09-27. Read `SKELETON-REVIEW.md` first: three claims in
`paper-skeleton.md` do not survive checking, and one of them determines whether
the central experiment measures anything at all.

These proposals are written against the corrected framing.

---

## The reframe, and why it is necessary

The skeleton pre-commits to its result. R1 states that the KV signal "is inert
in the steady 50%-capacity regime" and calls the pilot a basis for expecting it.
A paper that announces its finding before the run has two failure modes, and
this one is exposed to both. If the signal turns out live, the contribution
evaporates. If it turns out inert in a configuration where it could not have
moved, the finding is an artifact and a reviewer will say so.

The fix is to make the measurement the contribution rather than its outcome.
The question "does this policy's signal move under realistic load, and how would
a reader of the paper know" is worth answering whichever way it resolves. A live
signal that no paper reports is still an information gap. An inert one is a
sharper result. Both are publishable; only one of them is currently written.

This also matches what the survey can support. The survey states plainly that
its central finding is bibliographic and not empirical, that the authors did not
run the policies, and that establishing the empirical claim requires running an
inert-signal policy alongside a live-signal one on the same deployment. That is
Open Problem 7. The workshop paper should present itself as the first attempt at
OP7, not as confirmation of something the survey already showed.

---

## Proposal A: MLSys 2027 workshops

Targets: ES-FoMo, ML for Systems. Both take systems-measurement work with no new
algorithm.

### Title

Does the Signal Move? Measuring Admission-Control Signal Liveness in LLM Serving

### Abstract, 180 words

Admission control decides whether an arriving request enters an LLM serving
system, and published policies differ in the quantity they read: queue depth,
KV-cache pressure, deadline slack, tenant credit. A systematic review of
fifty-five works found that none of sixteen admission-primary papers reports the
range that quantity took during its own evaluation. The consequence is that a
policy whose threshold was never approached and a policy that approached it and
declined to reject produce identical admission counts and identical downstream
latencies. No reported number separates them.

We measure that range directly. We run two published policies, one reading queue
depth and one reading KV utilization, on unmodified vLLM across arrival regimes
spanning the engine's rated capacity, and report the observed signal range
alongside the admission decisions it produced. We find that signal liveness is a
property of the deployment configuration rather than of the policy, and that
plausible configurations exist in which a widely-used signal cannot reach its
threshold at any offered load. We release the harness and a one-line reporting
addition that makes this checkable in future work.

### Why it fits

These workshops take measurement papers whose contribution is a method and a
result rather than a mechanism. The shape here is: a published literature makes
an unstated assumption, we build the instrument that tests it, we report what
the instrument says. MLPerf Inference is the standing precedent for
evaluation-harness work at a systems venue.

The result is also operationally consequential in a way these audiences care
about. If signal liveness depends on the model-to-memory-to-concurrency ratio,
then a policy validated in one deployment can be silently inert in another, and
nothing in the published record would warn an operator.

### What to emphasise in the discussion

The capability-declaration schema and the runtime gate. An engine-agnostic
contract in which a policy declares the signal it reads and the band it assumes,
and the harness refuses to deploy it against an engine that cannot supply the
signal or a regime where prior probes show the signal is pinned. That is a
reusable mechanism, not a measurement, and it is the part a systems audience can
adopt.

---

## Proposal B: ICLR 2027 workshops

Targets: ES-FoMo, and the evaluation or trustworthy-ML workshops.

### Title

An Unreported Variable: Signal Liveness as a Reporting Requirement for Admission
Control

### Abstract, 175 words

Evaluation in LLM admission control rests on an unstated assumption. Sixteen
published policies decide admission by reading a runtime quantity and comparing
it to a threshold, and none reports the range that quantity took during the
evaluation. Without it, a reported improvement is uninterpretable in a specific
way: a policy whose threshold was never approached and a policy that approached
it and chose not to reject yield the same admission counts and the same
latencies.

We treat this as a reporting problem and test whether it matters. Running two
published policies on unmodified vLLM across arrival regimes, we record the
signal range alongside every admission decision and ask whether any conventional
reported metric distinguishes the two cases. We find that it does not, that
liveness varies with deployment configuration rather than with the policy, and
that the distinguishing information costs one column in a results table. We
propose that column as a reporting requirement, in the same spirit as
confidence-interval norms elsewhere in machine learning.

### Why it fits

ICLR evaluation workshops take work arguing that a subfield's reported numbers
do not support the conclusions drawn from them, provided the argument is
demonstrated rather than asserted. This has the demonstration.

The framing that travels here is reporting norms, not systems performance. The
analogue a reviewer will recognise is the shift from bare accuracy to accuracy
with confidence intervals: not a new method, a change in what counts as an
adequate result. The ask is one column, which is a low enough bar to be
adoptable and concrete enough to be checkable.

### What to emphasise in the discussion

The connection to reviewer checklists. NeurIPS and ICLR both ship one, and a
signal-range row is exactly the kind of item they contain. Argue that admission
control is a case where the missing item is cheap to add and expensive to omit,
and that the seven reporting items from the survey are a candidate starting
point for a future admission-control CFP.

---

## Shared assets

Both proposals draw on the same paper. Only the framing paragraph and the
discussion emphasis change, as the skeleton already anticipated.

| asset | state |
|---|---|
| Taxonomy and the seven recorded properties | Done, in the survey |
| Method protocol for the liveness probe | Draftable now, no experiments needed |
| Threats to validity | Draftable now |
| Figure 1, ingress stack diagram | Adaptable from the survey |
| Measurements | **Blocked.** See the configuration problem in `SKELETON-REVIEW.md` |
| Figures 2 to 4 | Blocked on the measurements |
| Public harness release | Blocked on the repository being made public |

---

## Sequencing

The CFPs are not open. ICLR 2027 workshop acceptances are expected around late
November 2026, with per-workshop deadlines in January and February 2027. MLSys
2027 workshop lists usually follow in January or February.

That leaves time, and the right use of it is to settle the experiment design
before writing prose against it. Specifically: establish a configuration in which
the KV signal *can* reach its threshold, so that finding it pinned is a result
rather than a foregone conclusion. Until that exists, §5 cannot be written
honestly, and §5 is the paper.

---

## Compliance

The skeleton asserts that a derivative workshop paper from a manuscript under
review at CSUR is permitted subject to three conditions. Treat that as unverified
until read off ACM's current policy directly. Two points to confirm rather than
assume: whether notification to the CSUR editor-in-chief is required or merely
advisable, and whether the workshop has archival proceedings, since a
non-archival workshop raises no prior-publication question at all and an archival
one does.

The substantive condition is the one worth meeting regardless of policy: the
workshop paper must carry an empirical contribution the survey does not. As
designed, it does. The survey states explicitly that it did not run the policies
and that doing so is Open Problem 7. This paper is that.
