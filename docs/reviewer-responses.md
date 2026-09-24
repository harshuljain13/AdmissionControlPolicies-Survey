# Reviewer comments, and where each is now answered

*Bhau's five comments on the v0.2 draft (2026-09-16), mapped to the current
paper. Section numbers are from the CSUR build.*

| # | Comment | Where it is answered now |
|---|---|---|
| 1 | §6.1 proposed a methodology contract without evidence that its items matter | §8.1 no longer proposes a contract. It reports seven items that diverge across the corpus, states explicitly that we do not claim the set is minimal or that its members matter equally, and hands the validation question to OP7. `docs/applicability.md` is the evidence behind the divergence claim. |
| 2 | §1.1 positions only against other surveys | §1.1 now adds benchmarks and evaluation frameworks: MLPerf Inference and Etalon by name, plus the LLMPerf / GenAI-Perf / GuideLLM tooling, with the distinction stated — they measure a system under a given load and do not vary what it refuses. |
| 3 | The unclaimed intersection is asserted rather than stress-tested | §3.7 re-derives it under the re-cut axes and reports that it survives, naming why each near-miss fails: CONCUR is offline and throughput-oriented, Continuum is Class B and JCT-oriented. It also surfaces a second and sharper gap beneath it, that no agent-level admission-primary policy both serves online traffic and deploys without an engine fork, and names ThunderAgent as the near-miss whose deployability is unestablished. |
| 4 | Tenant SLO fairness is used but never defined | Definition 3 gives Jain's fairness index in weighted form, with the equation, its range, why served tokens rather than admitted counts, and the caveat that it is a coarse instrument, alongside Equinox's critique of the token basis. |
| 5 | The reproducibility claim is imprecise | §8 separates artifact availability, which is counted per tier because a corpus-wide denominator would span textbooks, from methodology reproducibility, which is not counted here and is stated as OP7. Two qualifications are inline: Chronos released a simulator, and AQUA is the preemption-based foil rather than an admission policy. |

## Raised after that review

| Source | Point | Status |
|---|---|---|
| External review, 2026-09-23 | Numeric contradiction, 17 vs 16 admission-primary | Fixed. The Method tier structure had never been updated after the corpus grew; four of six tier counts were wrong and summed to 53. |
| " | "Four broad surveys" above a five-row table | Fixed. |
| " | Duplicate ProServe bibliography entries, both cited | Fixed; the 2026 key removed. |
| " | `\shortauthors` de-anonymises every page | Not reproduced. acmart suppresses it under `[anonymous]`; running headers on pages 3, 5 and 7 carry the title alone. The anonymity gate now checks headers directly, since it would not have caught a real instance. |
| " | Missing-work attack surface | Appendix A lists works set aside, split into examined-and-excluded and identified-but-not-examined. The second list includes three agent-side candidates that bear on the agent-level claims. |
| " | Signal-liveness claim rests on absence of evidence | §11 owns it. The claim is stated as an absence across the evaluation sections extracted, and OP7 states the measurement that would settle it. No experiment is claimed. |
| " | Single-coder screening | §11 discloses it, names the three contestable placements (FairServe, SAGA, Mooncake), and points at the released coding sheets. |
| " | Cross-reference against Mitzenmacher's agenda | §10 does this, and says the lists overlap on reasoning workloads and schedulability rather than claiming they are disjoint. |
