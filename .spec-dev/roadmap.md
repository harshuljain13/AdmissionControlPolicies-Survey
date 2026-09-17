# Roadmap: the survey and AdmitPerf, as one project

*Updated 2026-09-17, after the evidence audit.*

---

## What we are trying to prove

The survey says: **you cannot compare admission-control policies using the
published literature, because no two papers measure the same thing.** It then
proposes a minimum set of things every paper should report.

A reviewer asked the fair question: *why that set?*

AdmitPerf is the answer. We take a published algorithm, implement it honestly,
run it on a real GPU, and show that the result swings wildly when you change
things that no paper is currently required to report. Each thing that swings the
result becomes one item in the contract. Nothing goes in the contract that we
have not watched break.

So:

- **The survey makes the claim.**
- **AdmitPerf produces the evidence for it.**
- **The survey publishes that evidence and points at the repo.**
- **The repo points back at the survey.**

That is the whole project. Everything below is sequencing.

---

## Why this is not a "which policy wins" study

Worth repeating, because we lost three weeks to it.

The survey's own claim is that fair comparison is not currently possible. If the
same paper then announces a winner, it undercuts itself. So Chronos is a
**specimen**, not a contender. We are not asking "is Chronos good". We are
asking "can the same faithful implementation be made to say opposite things".
The answer is yes, and that is the finding.

The head-to-head study — which policy actually wins, under which conditions — is
the **next** paper, and it only becomes possible once the contract exists.

---

## The six things that swing the result

Each becomes one contract item. Status is from the audit
(`evidence-audit.md`), not from optimism.

| # | Thing that moves | What happens | Evidence today |
|---|---|---|---|
| 1 | Context window vs the traffic's token sizes | a third of requests get rejected by the engine and counted as overload failures | **lost** — need a 3-minute re-run |
| 2 | Workload sample (seed) | 0%, 38%, 0% admitted across three seeds | **good**, statement needs correcting |
| 3 | Which signal the policy reads | KV usage peaked at 0.005 against a 0.9 threshold: the policy could never fire | **good**, directly measured |
| 4 | Cost-model constants carried from another GPU | admit rate spans 1.8% to 100% | **analysis only**, label it as analysis |
| 5 | Offered load vs what the box can serve | the best policy changes | **half** — overload half is a stub engine |
| 6 | Deadline vs the machine's own latency | a correct policy refuses everything | **wrong denominator**, needs a 2-minute run |

Three are usable now. Three need short runs. None need a big experiment.

---

## How the two repos connect

```
SURVEY                                ADMITPERF
paper.md, arXiv                        github.com/harshuljain13/AdmitPerf

 §6.1 the contract  <--- justified by --- the sensitivity study
        |                                        |
        |  each item  <--- enforced by --- an executable check
        |                                        |
        |    load vs capacity                    bench capacity
        |    deadline vs unloaded                infra calibrate
        |    parameter provenance                manifest fields
        |    signal liveness                     signal_range
        |    3+ repeats and spread               bench compare / decide
        |    context vs token sizes              refuses to start
        |
 Appendix: how to reproduce ------------> one command per table
 Citation --------------------------------> repo README cites the survey
```

Simple version: **the paper states the rule, the repo is why you should believe
the rule, and the repo's checks make the rule cheap to obey.**

---

## Porting more algorithms: how many, and why

One port (Chronos) proves the effect exists. A reviewer will ask whether Chronos
is just unusually fragile. So we need a **second published algorithm, as
different from Chronos as possible**, and we need it to be cheap.

From `admitperf/docs/policies.md`, in order of cost:

| Order | Policy | Why this one | Cost |
|---|---|---|---|
| 1 | **FluidWait-inspired** (arXiv:2504.11320) | Published, and its signals (queue + KV) are the ones that actually move on our hardware, so it will do something rather than sit inert. Different family from Chronos: scalar threshold, not a formal bound. | small |
| 2 | **TokenBudget** (derived) | Not a port, but a strong SLO-aware baseline that is honest about not being a port. Cheap. | small |
| 3 | **QLM-inspired** (SoCC 2024) | A second *venue-published*, SLO-aware policy from a third family (virtual-queue LP). This is the one that makes "not Chronos-specific" convincing. | large |
| 4 | **CONCUR-inspired** (agent-level) | Needs an agent-session workload that does not exist yet. This is the seed for the next paper, not this one. | out of scope |

**For the preprint we need 1, and 2 if time allows.** 3 and 4 belong to the
follow-up.

### The part people miss

Every port produces a **deviation list** — the places where the paper did not
say enough to implement it without guessing. Chronos's list already contains
three entries, including the cost constants that swing the result from 1.8% to
100%.

Those lists are not apologies. **They are the survey's evidence.** Each entry is
a thing a paper left unspecified that changes the answer. Port notes go straight
into the appendix.

---

## Order of work

Each phase produces something. Nothing is a prerequisite pile.

| Phase | What it produces | GPU | Cost |
|---|---|---|---|
| **A. Make the harness trustworthy** | git sha in every result, no silent overwrite, signal range recorded | no | free |
| **B. Bank and correct the evidence we have** | the sensitivity table, stated accurately, with three rows final | no | free |
| **C. Survey desk work** | related work, intersection stress test, fairness defined | no | free |
| **D. The measured run** | the load row, real numbers, four situations, calibrated deadlines | yes | ~$1.50 |
| **E. Second port + its experiment** | FluidWait-inspired, plus proof the effect is not Chronos-only | yes | ~$0.50 |
| **F. Write it into the survey** | §6.2, appendix, both repos cross-linked | no | free |
| **G. Submit** | arXiv preprint | no | free |
| **H. Later** | QLM port, agent workload, CONCUR, head-to-head paper | yes | later |

**Phase A comes first and is not optional.** We already lost one result to a
silent overwrite, and no bundle can currently say which version of the code
produced it. A paper about provenance cannot ship on a harness without it.

---

## Standing decisions

- **Chronos is a specimen, not a contender.** No winner is declared in this paper.
- **Tenant SLO fairness (F)**, plain name in the text, `[Jain et al. 1984]` on
  the formula. We do not rename a standard index after our own tool.
- **Configs are named for what they produce.** `which-policy-when`, not
  `Experiment1`.
- **A broken run is evidence if its defect is named**, and noise if it is not.
- **One deployment is the unit of comparison.** Load varies inside it; nothing is
  ever pooled across hardware.
- **Ports never claim the bare name.** `chronos_inspired`, never `chronos`, and
  every deviation is written down.
