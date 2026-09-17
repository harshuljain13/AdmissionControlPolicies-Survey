# Sensitivity table: what moves the answer

*Generated 2026-09-17 from result bundles. Every number here was read out of a
`summary.json` or `decisions.jsonl` by script, not from notes or memory.*

**Rule for this file**: if a number cannot be traced to a path in the repo, it
does not go in. Numbers quoted from conversation have already been wrong once.

Hardware for every A10G row: one NVIDIA A10G on Modal, Qwen2.5-0.5B-Instruct,
vLLM 0.29.0, `max_num_seqs=10`, `gpu_memory_utilization=0.85`,
`max_model_len=6144` unless stated.

---

## The six knobs

| # | Knob | Range observed | Effect on the reported result | Provenance |
|---|---|---|---|---|
| 1 | Context window vs traffic token sizes | 2048 vs traffic up to 6144 tokens | ~32% of requests rejected by the engine and recorded as failures | **evidence destroyed** — recreate, 3 min |
| 2 | Workload sample (seed 0, 1, 2) | same config, three seeds | chronos admitted **0.0%, 34.0%, 4.1%**; attainment 0.000, 0.222, 0.024 | A10G, `half-capacity-headroom/results` |
| 3 | Signal the policy reads | `kv_used_fraction` **0.0000–0.0046** across 485 decisions, threshold 0.9 | `kv_threshold` admits 100% in all three runs; attainment 0.5537 vs baseline 0.5553 — statistically the baseline | A10G, same bundles |
| 4 | Cost-model constants (α, γ) | paper's 7B/A100 values vs a plausible 0.5B/A10G pair | chronos admit rate **1.8% → 100%** | **analysis only** — frozen state, synthetic arrivals, fitting disabled |
| 5 | Offered load vs capacity | 4/s measured; higher loads not yet on real hardware | winner changes (mock engine only so far) | **half** — 2x row is a stub engine |
| 6 | Deadline vs the machine's own latency | 500 ms deadline, TTFT p50 **281–293 ms** under load | a formally correct policy refuses 96% of traffic | A10G for the loaded p50; **unloaded baseline not yet measured** |

Three rows are final. Three need short runs, totalling under ten minutes of GPU.

---

## Row 2 in full — the same experiment, three seeds

Source: `experiments/half-capacity-headroom/results`, rate 4.0/s, 120 s,
3 repeats, seeds 0/1/2.

| Policy | admit rate | offered attainment | TTFT p50 |
|---|---|---|---|
| `no_admission` | 100% · 100% · 100% | 0.555 · 0.580 · 0.546 | 281–293 ms |
| `kv_threshold[0.9]` | 100% · 100% · 100% | 0.546 · 0.592 · 0.554 | 281–290 ms |
| `chronos_inspired` | **0.0% · 34.0% · 4.1%** | **0.000 · 0.222 · 0.024** | 276–288 ms |

Two things to take from this table, and one trap to avoid.

**The baseline misses 45% of its deadlines.** At 4 arrivals per second this
deployment is not comfortable. An earlier reading of these same bundles put the
baseline at 0.96, which was wrong; the committed files say 0.55. The experiment's
name, `half-capacity-headroom`, is now a misnomer and should be corrected.

**Chronos's spread is the finding, not its level.** One configuration, three
traffic samples, and its admit rate covers almost the whole range it could
occupy. A paper reporting any single one of these runs would be reporting
something true and useless. This is the argument for requiring repeats and
publishing spread.

**The trap**: this is sample variance, not nondeterminism. The seeds differ
(0, 1, 2), so the traffic differs. Do not write "identical runs".

---

## Row 3 in full — a policy that could not fire

Source: `experiments/half-capacity-headroom/results/kv_threshold-threshold-0-9--r1/decisions.jsonl`

- 485 decisions recorded
- `kv_used_fraction` ranged **0.0000 to 0.0046**
- the policy's threshold was **0.9**

The signal reached half a percent of the level it needed. The policy was
structurally incapable of refusing anything, and its results are therefore a
measurement of the baseline wearing a different name — attainment 0.5537 against
the baseline's 0.5553.

Note what makes this legible: `admitperf/docs/policies.md` states that on a small
model with a low concurrency cap the binding constraint is the concurrency cap
and the signal that moves is `waiting_requests`. That predicted this result
before it was measured. A paper reporting a KV-threshold policy on a small model
without reporting the observed KV range has not reported enough for a reader to
know whether a policy ran at all.

---

## Row 4 — what it is and is not

The cost-model sweep was produced by replaying the admission test with:

- arrivals synthesized locally, not taken from a run
- system state **frozen** at `running_requests=2` for every decision
- telemetry fitting disabled, so the constants stayed where they were set

It therefore demonstrates the **arithmetic sensitivity of Algorithm 1** to its
constants. It does not demonstrate policy behaviour on a live engine, where the
same constants also move the fitted α, the utilization estimate, and the state
the test reads.

Publishable as analysis, labelled as analysis. To make it an empirical row, run
two live configurations with γ set explicitly — about ten minutes.

---

## What is missing, and what it costs

| Gap | Fix | Cost |
|---|---|---|
| Row 1 evidence destroyed by an overwrite | re-run the 2048-window config, one repeat, keep the bundle | ~3 min |
| Row 6 compares against loaded latency | `infra calibrate` for the unloaded baseline | ~2 min |
| Row 5 overload half is a stub engine | the `which-policy-when` run | ~75 min |

Total: under $2 of GPU time.

---

## Provenance notes

The bundles cited here predate the provenance work, so they carry **no commit
and no `signal_range` field**. Row 3 required reading 485 decision records by
hand. Every future run records both. When these rows are re-measured, they
should be re-measured on a harness that can say what produced them.
