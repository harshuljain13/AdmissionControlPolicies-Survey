# Applicability table — Tier 1 (admission-primary)

*Built 2026-09-21 (Phase T). Source columns are transcribed from `notes/<paper>.md`
§ "Taxonomy placement"; derived columns are marked and justified below. This file
is the evidence behind §8.1's claim about which reporting items vary.*

## Controlled vocabulary

**Signal quantity** — the quantity the policy compares against a threshold:

`kv_pressure` · `queue_depth` · `deadline_slack` · `wait_estimate` ·
`predicted_length` · `batch_state` · `rate` · `analytic` (no runtime signal)

**Portability** — derived from the decision moment in `tab:master`:
`ing` → **A** (decidable at ingress from observable engine state);
`qb`/`mf` → **B** (requires control over batch formation, so an engine fork).

**Request metadata assumed** — what a request must carry for the policy to act at
all. `none` means the policy needs only the request and system state.

## The table

| # | Policy | Unit | Setting | SLO-awareness | Signal quantity | Metadata assumed | Port. | Liveness reported |
|---|---|---|---|---|---|---|---|---|
| 1 | QLM | request | online | deadline + class fairness | `wait_estimate` + `queue_depth` | SLO class | **A** | unreported |
| 2 | Chronos | request | online | deadline (TTFT+TBT) | `deadline_slack` | deadlines | **A** | unreported |
| 3 | SOLA | request | online | deadline (TTFT+TPOT) | `deadline_slack` + `batch_state` | deadlines | **B** | unreported |
| 4 | FastServe | request | online | deadline (avg + tail) | `queue_depth` + `predicted_length` | none | **B** | unreported |
| 5 | SLOs-Serve | request | online | multi-SLO, per-stage | `deadline_slack` | per-stage deadlines | **A** | unreported |
| 6 | Fluid-WAIT | request | online | stability | `queue_depth` + `kv_pressure` | none | **A** | unreported |
| 7 | Scorpio | request | online | deadline (TTFT+TPOT) | `deadline_slack` + `predicted_length` | deadlines | **A** | unreported |
| 8 | Flow-controlled | request | online | stability + tail | `rate` | none | **A** | unreported |
| 9 | Service-Induced Cong. | request | theoretical | stability | `analytic` | none | **A** | n/a (no evaluation) |
| 10 | Shen et al. | request | online | reward-based | `analytic` + config dist. | none | **A** | unreported |
| 11 | ProServe | request | online | priority + deadline | `deadline_slack` + priority | priority class, deadline | **B** | unreported |
| 12 | CONCUR | agent-session | **offline** | throughput | `kv_pressure` (dual gate: utilisation + hit rate) | session id | **A** | unreported |
| 13 | Continuum | agent-session | online | JCT | `kv_pressure` + `queue_depth` + `session_state` | session id | **B** | unreported |
| 14 | FairBatching | request | online | fairness (prefill/decode) | `batch_state` | none | **B** | unreported |
| 15 | Clairvoyant | request | serial / edge | latency | `predicted_length` | none | **A** | unreported |
| 16 | AQUA | request | online | responsiveness | `kv_pressure` + offload cost | none | **B** | unreported |

CONCUR was initially marked **B** here on the assumption that a session-level AIMD
controller needs batch control. `notes/concur.md` settles it the other way: "CONCUR
is implemented as a controller on top" of SGLang, reading KV utilisation and prefix
hit rate from engine metrics and pausing or admitting whole sessions. That is Class
A, and `tab:master`'s `ing` coding was correct. No disagreement remains between this
table and the paper.

## Counts

| Column | Populated | Unreported / undetermined |
|---|---|---|
| Unit | 16 | 0 |
| Setting | 16 | 0 |
| SLO-awareness | 16 | 0 |
| Signal quantity | 16 | 0 |
| Metadata assumed | 16 | 0 |
| Portability | 16 | 0 |
| **Signal liveness reported** | **0** | **16** (15 unreported, 1 n/a) |

**The finding: of the seven columns, six are fully populated from the papers
themselves. The seventh is empty. Not one of the sixteen admission-primary papers
reports the observed range of the quantity its policy reads.**

That is a stronger result than "reported inconsistently": it is uniform absence, and
it is the column that determines whether a reported improvement is interpretable at
all.

## What this does and does not establish

**Does**: every other axis is recoverable from the published text. A reader can
determine what a policy watches, what it assumes, and whether it is deployable in
front of an unmodified engine. Selection fails on exactly one missing fact.

**Does not**: this is an absence in our extraction of each paper's evaluation
section, not a guarantee that no paper mentions a signal range anywhere. A figure
axis showing KV occupancy over time would arguably satisfy the item and would not
have been captured by reading the evaluation setup. §8.1 states this limitation.

## Derived-column method

**Portability** follows the decision moment already assigned in `tab:master`, so it
introduces no new judgment. Class A means the decision
needs only the request and state the engine already exposes; Class B means it needs
to influence which requests enter a batch, which cannot be done from outside.

**Metadata assumed** is read off the mechanism: a policy that compares against a
deadline requires the request to carry one; an agent-session policy requires a
session identifier; a policy that predicts length from the prompt requires nothing
beyond the request. Where a paper's own text does not settle it, the cell would read
`unreported` — no cell did.

**Signal liveness** was checked by searching each note and each paper's evaluation
description for a reported range, minimum/maximum, or distribution of the signal the
policy reads. Scorpio, Aegaeon, Token Pools, Niyama and TokenScale were additionally
checked against full text during the reference audit.

## Distribution, for §3

By portability: **10 Class A**, **6 Class B**. A practitioner who cannot fork their
engine has ten candidates, not sixteen.

By signal quantity: `deadline_slack` 5 · `kv_pressure` 4 · `queue_depth` 4 ·
`predicted_length` 3 · `batch_state` 2 · `analytic` 2 · `wait_estimate` 1 · `rate` 1.

By metadata: **8 require nothing** beyond the request; 5 require a deadline or SLO
class (Chronos, SOLA, SLOs-Serve, Scorpio, QLM); 2 require a session id (CONCUR,
Continuum); 1 requires a priority class as well as a deadline (ProServe). 8+5+2+1=16.
