# Saying No at the Door: Admission Control for LLM Inference Serving

**Format:** 30 min (22–24 min talk + 6–8 min Q&A)
**Audience:** ML platform engineers, serving-systems researchers, SREs running inference at scale
**Based on:** *Admission Control for LLM Inference Serving: A Systematic Review* (CSUR submission, 2026)
**Speaker:** Harshul Jain

---

## Speaker notes on shape

Three acts, not seven. The survey has seven reporting items; the talk has three findings and one call to action. The seven show up on one slide near the end, as the receipt for the third finding, not as a section.

Zero em-dashes. Zero "curated tour" phrasing. Numbers only when they change the argument.

---

## Slide-by-slide

### Act I — The invisible layer (0:00–5:00, 5 slides)

**Slide 1 — Title (0:30)**
- Title, name, one-line affiliation, CSUR-submission tag.
- Say out loud: "This is a systematic review of 55 papers. I'm going to tell you the one thing none of them do."

**Slide 2 — The postmortem you have already read (1:30)**
- Screenshot montage: OpenAI Nov 2023, Anthropic 2024, Cloudflare AI Gateway, Azure OpenAI throttling.
- One shared shape: overload arrives, the engine responds, users see 429/503/529.
- Ask: where in that stack does the request get turned away?

**Slide 3 — The stack, and where the decision lives (1:00)**
- Diagram: client → gateway → router → engine (batching, KV, scheduler) → GPU.
- Highlight the ingress boundary. Say: "Admission is a decision at this line. Every other overload response — batching, migration, autoscaling, memory management — happens after."

**Slide 4 — What the serving literature does at that line (1:00)**
- Table of nine top-venue serving papers (Sarathi-Serve, Llumnix, DistServe, Orca, Aegaeon, Jenga, Past-Future, AdaServe, PASCAL).
- Column: "Overload response." Nine rows, nine engine-internal answers.
- Column: "Admission at ingress." Nine empty cells.
- Finding one, stated flat: **the layer the serving literature studies is not the layer where admission lives.**

**Slide 5 — Why this talk exists (1:00)**
- The gap is real. The policies exist — sixteen of them, in a separate literature.
- You cannot pick one for a deployment. That is the problem the survey exists to fix.

---

### Act II — The map (5:00–13:00, 8 slides)

**Slide 6 — What we reviewed (1:00)**
- 55 works, 2022–2026, adapted-PRISMA. Eleven venues.
- Two piles: nine serving papers audited for admission behavior, sixteen admission-primary papers placed on axes.

**Slide 7 — Five axes (1:30)**
- Unit (request / agent-session / tenant), Setting (online / offline / hybrid), Objective (deadline / throughput / fairness / cost), Signal (kv-pressure / queue-depth / deadline-slack / tenant-credit / session-state / wait-estimate), Portability (deployable in front of an unmodified engine, yes/no).
- Say: these are five questions you ask before you deploy a policy. Every paper answers four; almost none answer the fifth.

**Slide 8 — Axis 1: Unit (0:45)**
- Request is the default. Agent-session and tenant are where the interesting work is.
- One-line callouts: CONCUR (session), VTC (tenant), FairServe (tenant).

**Slide 9 — Axis 2: Setting (0:45)**
- Online (rejection is live), offline (deferral / batch), hybrid.
- Point: most published policies are online-only. Agentic workloads break that assumption.

**Slide 10 — Axis 3: Objective (0:45)**
- Deadline, throughput, fairness, cost. Rarely more than one at a time.
- Chronos = deadline. Fluid-WAIT = throughput. VTC/FairServe = fairness. Aqua = cost.

**Slide 11 — Axis 4: Signal (1:00)**
- Six signals in the literature. Each one implies an engine assumption.
- Callout: **a policy that reads KV pressure requires the engine to expose it.** Portability is not free.

**Slide 12 — Axis 5: Portability (0:45)**
- Class A: fronts an unmodified engine. Class B: needs engine changes.
- The class-B tax is invisible in most papers. It shows up when you try to deploy.

**Slide 13 — The master table (1:30)**
- Show the classification table, sixteen rows, five columns plus GRADE evidence rating.
- Six of seven properties recoverable from the published text for every row.
- One column is mostly empty. That is the next slide.

---

### Act III — The one missing fact (13:00–19:00, 6 slides)

**Slide 14 — Finding two (1:00)**
- Of sixteen admission-primary papers, **no two share a baseline set.**
- Almost every paper is measured against the absence of admission control. Almost none against each other.
- Consequence: you cannot rank them from the published record. Selection is not a comparison, it is a leap of faith.

**Slide 15 — Finding three, setup (1:00)**
- Placing the sixteen on the five axes: four of the five axes are recoverable from every paper.
- Signal *name* is recoverable. Signal *range in the reported deployment* is recoverable from zero of sixteen.

**Slide 16 — Why signal range matters (1:30)**
- A policy that reads KV pressure in a regime where KV pressure never moves is a coin flip wearing a lab coat.
- Concrete example (from our own harness): a KV-threshold policy admitted 1,241 of 1,241 requests while the signal it reads stayed in [0.0000, 0.0071] against a 0.9 threshold. Results table looked ordinary.
- **Signal liveness is the load-bearing fact. It is reported by nobody.**

**Slide 17 — Why this is a structural finding, not a nitpick (1:00)**
- Not "one paper forgot a number." Sixteen papers, six axes, one axis unreported.
- Selection fails on a single missing fact. That fact determines whether a reported improvement is interpretable at all.
- This is what the survey names, and what the follow-on tool (AdmitPerf) is built to enforce.

**Slide 18 — The seven reporting items (1:00)**
- One slide, seven bullets: capacity-relative load, calibrated deadlines, signal liveness, repeats + spread, parameter provenance, metric definition, configuration disclosure.
- Say: "We are not claiming this is the minimum set. We are claiming these are load-bearing. Omit one and a result can change without the reader knowing."

**Slide 19 — Production evidence (0:30)**
- One-line summary of the eight-incident mapping. Real outages, mapped to admission failure modes.
- Point: this is not academic. The literature and the postmortems are describing the same layer.

---

### Act IV — What to do (19:00–24:00, 5 slides)

**Slide 20 — If you are running inference (1:00)**
- Before you deploy a policy, ask five questions (the axes). Then ask a sixth: does the signal it reads move in my regime?
- If you cannot answer the sixth, the policy is not yet applicable to your deployment. Run a probe first.

**Slide 21 — If you are writing a paper (1:00)**
- Report the range of your signal. It costs one column in one table.
- Report a baseline that is not "no admission control." Pick one other policy from the sixteen.
- Report parameter provenance. Chronos's gamma alone swings admit rate from 1.8% to 100%.

**Slide 22 — Seven open problems, one slide (1:00)**
- OP1–OP7 as one-liners. OP7 (which reporting items are load-bearing) is the one AdmitPerf answers by breaking them.

**Slide 23 — What is next (1:00)**
- The survey names the gap. AdmitPerf (companion tool, MLSys 2027 D&B target) puts the seven items under measurement.
- Capability declaration, inert-signal detection, load-validity gate.

**Slide 24 — Recap and close (1:00)**
- Three findings: the layer, the empty baseline set, the missing fact.
- One ask: report the range of the signal your policy reads.
- Link to CSUR preprint and AdmitPerf harness.

**Slide 25 — Q&A (5:00–8:00)**
- Anticipate: (1) what about Token Pools / SAGA / ProServe — answer: partial occupants, in the master table. (2) is this survey minimal — answer: no, load-bearing not minimal, that distinction is deliberate. (3) can AdmitPerf actually break all seven — answer: five yes, two arguable-by-construction only.

---

## Reusable one-liners

- "Admission sits at a different layer from the one the serving literature studies."
- "Sixteen policies, no shared baseline. Selection is a leap of faith, not a comparison."
- "A policy that reads a signal that never moves is a coin flip wearing a lab coat."
- "Signal range is one column in one table. It is reported by nobody."
- "The postmortem and the paper are describing the same layer."

---

## Venue fit

- **Best fit:** MLSys workshop (ES-FoMo, ML-for-Systems), USENIX SREcon, CNCF AI Days, InfoQ Dev Summit inference track.
- **Also fits:** DeveloperWeek Cloud, PlatformCon SF, ODSC AI West.
- **Trim to 20 min:** cut slides 8–10 (fold axes 1–3 into one), keep everything else.
- **Trim to 15 min:** drop Act IV slides 21–23, close on slide 24 directly after finding three.
- **Extend to 45 min:** add a live walk of AdmitPerf's inert-signal detector on the KV-threshold example from slide 16.
