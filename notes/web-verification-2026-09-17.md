# Web verification of the survey's claims

*2026-09-17. Searches run against the live web to test the corpus and the
framing. Everything below is either a verified abstract or a clearly labelled
search snippet.*

---

## 1. The niche is unclaimed. This is the important result.

There is **no systematic review of admission control for LLM inference serving**.
Searched directly for one; the nearest neighbours are:

| Work | What it covers | Why it does not collide |
|---|---|---|
| [A Control-Oriented Survey of Load Balancing for LLM Inference Serving](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=6516666) (Ma et al., SSRN 2026) | load balancing as a coupled control problem; phase asymmetry, KV residency, heavy-tailed load | routing and balancing, not ingress admission |
| [Taming the Titans](https://arxiv.org/pdf/2504.19720) (INLG 2025) | efficient serving, instance to cluster scale | admission is one subsection |
| [LLM Inference Serving: Survey of Recent Advances](https://arxiv.org/pdf/2407.12391) | system-level enhancements since 2023 | admission cited in passing |
| [Towards Efficient Generative LLM Serving](https://dl.acm.org/doi/10.1145/3754448) (ACM CSUR) | algorithms to systems | no admission axis |

**Conclusion: the survey's core positioning holds.** Admission control appears
as a component inside broader surveys and has never been the primary axis.

**Action**: Ma et al. 2026 must go into Table 1. It is the closest related
survey and its absence is exactly the "missing related work" the reviewer
flagged. It is also a control-theoretic framing, which is a useful contrast: we
organize by admission granularity and signal, they organize by control loop.

---

## 2. The corpus has holes, and one of them is serious

Checked each of the following against `paper.md`, `references.bib`, `docs/` and
`notes/`. None of these appear anywhere.

### Serious: admission-primary, peer-reviewed, missing

**[Scorpio](https://arxiv.org/html/2505.23022)** (arXiv:2505.23022, accepted at
WISE 2026). Verified from the abstract page. An SLO-aware serving system built
in three stages, the first of which is admission control:

- "TTFT Guard, which employs least-deadline-first reordering and **rejects
  unattainable requests**"
- "TPOT Guard, which utilizes a **VBS-based admission control** and a novel
  credit-based batching mechanism"
- heterogeneous TTFT and TPOT targets, predictive feasibility module
- reports up to 14.4x goodput and 46.5% better SLO adherence under high load

This is an admission-primary, deadline-aware, peer-reviewed paper missing from a
systematic review of admission control. A reviewer who knows the area will find
it immediately. It also changes the count in the abstract: "fourteen
admission-primary papers" becomes at least fifteen.

### Notable: admission-adjacent, missing

**[Niyama](https://arxiv.org/abs/2503.22562)** (arXiv:2503.22562, Microsoft
Research). Verified. QoS-driven co-scheduling of mixed workloads, fine-grained
QoS classes, hybrid fairness/efficiency prioritization, and "**selective request
relegation** that enables graceful service degradation during overload". Not
outright rejection, so it is degradation rather than admission, but it satisfies
inclusion rule 3(b) and its overload behaviour is directly comparable.

### Also absent, from search snippets (each needs verifying before citing)

| Work | Relevance |
|---|---|
| OmniServe | "regulates admissions", 43.3% higher prefill SLO compliance, sub-1ms admission overhead |
| [Service-Induced Congestion in Memory-Constrained LLM Serving](https://arxiv.org/pdf/2606.15555) | overload theory; optimal admission control in queues with abandonments |
| [Token Latency Fairness](https://arxiv.org/abs/2609.18112) | multi-tenant performance isolation |
| [LLMVisor](https://arxiv.org/pdf/2608.08382) | per-request latency attribution, explicitly motivated as enabling SLO-aware admission |
| FairInference / FairServe | user and application-aware fair serving |
| [Adaptive Memory Admission Control for LLM Agents](https://arxiv.org/pdf/2603.04549) | agent-level admission |
| [Agent Control Protocol](https://arxiv.org/pdf/2603.18829) | admission control for agent actions |
| [ConsistencyGate](https://arxiv.org/html/2607.22962) | self-consistency admission control for agent memory |
| [AgentServeSim](https://arxiv.org/pdf/2606.09613) | simulator for multi-turn agent serving |

The last four matter for section 3.5, because they are agent-side and the empty
cell is an agent-level claim.

---

## 3. Production practice exists, and it helps rather than hurts

[Cohere's serving fairness post](https://cohere.com/blog/serving-fairness) (June
2026) describes a production design in which "every request passes through
admission control before joining the scheduling queue", followed by three
selectors: performance tier, deficit round robin, and priority.

This is the objection to finding 1 in concrete form: practitioners *do* admission
control. It does not sink the claim, it sharpens it. The nine research systems
absorb overload downstream; practitioners build ingress admission ad hoc and
publish it on engineering blogs rather than in venues where it can be compared.
That is a better statement of the problem than "nobody does admission control".

---

## 4. What this means for the framing

The current framing is roughly "admission control is missing". The evidence says
something sharper and more defensible:

> **Admission control is being reinvented independently across the field, in
> research systems and in production, and no two instances can be compared.**

Under that framing every finding gets stronger:

- **Finding 1** stops being "nobody does it", which is attackable, and becomes
  "the nine flagship research systems handle overload downstream; the work that
  does admit or reject sits outside them". Cohere and Scorpio become supporting
  evidence rather than counterexamples.
- **Finding 2** is unchanged and is the spine of the paper.
- **Finding 3** needs the most work. The agent-side papers above are exactly the
  borderline cases the reviewer asked about.
- **Finding 4** is unchanged, and is what AdmitPerf evidences.

---

## 5. Actions, in order

1. **Read and classify Scorpio.** Admission-primary. Update the count, add it to
   Table 2, and check whether it changes the "no two share a baseline" claim.
   It reports goodput and SLO attainment, so its metric definitions matter.
2. **Add Ma et al. 2026 to Table 1** and state the contrast.
3. **Add Niyama** as admission-adjacent.
4. **Verify the nine snippet works**, then classify or explicitly exclude each.
   An explicit exclusion with a reason is a fine outcome and shows the sweep was
   real.
5. **Reframe finding 1** along the lines in section 4 above.
6. **Rework 3.5** using the agent-side papers as the near-miss table.

Nothing here requires a GPU, and none of it invalidates the survey. One serious
omission, one missing related survey, a reframe that makes the argument harder
to attack, and a confirmation that nobody else has taken this ground.
