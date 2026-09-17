# Evidence audit: how far can each claim actually be pushed?

*2026-09-17. Every row checked against bundles on disk, not against memory.*

The survey's credibility rests on a reproducibility audit of other people's
work. Publishing that on top of evidence we have not audited ourselves would be
the worst possible failure mode. This is that audit, done adversarially.

Verdict scale: **A** usable as a headline claim · **B** usable with the
statement corrected · **C** not usable until re-measured.

---

## Row 1 — Context budget: "32% of traffic returned HTTP 400"

**Verdict: C. The raw evidence has been destroyed.**

The run that produced it wrote to `results/Experiment1`. The later run wrote to
the same directory and overwrote it. Every bundle now on disk reports
`failed=0`; no bundle anywhere has `failed>0`. The 462-failure measurement
exists only in a conversation transcript, which is not evidence.

Two things follow:

1. **The mechanism is still provable without a run.** `batch` class generates
   512-4096 input + 512-2048 output = up to 6144 tokens; `max_model_len` was
   2048; vLLM rejects anything that does not fit. That arithmetic is
   deterministic and checkable from the config alone. The *rate* (32%) is not
   recoverable without re-running.
2. **This is a harness defect, not just bad luck.** `bench run --out <dir>`
   silently writes into a non-empty directory. A tool built to make results
   reproducible destroyed its own. Fix before anything else.

**To upgrade to A**: re-run the 2048-window configuration for one repeat
(~3 min of A10G) and keep the bundle. Or state only the mechanism and drop the
percentage.

---

## Row 2 — Repeat variance: "0%, 38%, 0% admitted"

**Verdict: B. Real, but I described it wrongly.**

Bundles are on disk and readable. But the three repeats used **seeds 0, 1 and
2** — they are three different traffic samples, not three identical runs. I
wrote "three identical repeats" in the spec and said it in conversation. That
is wrong, and a reviewer would catch it immediately.

The corrected claim is still worth having, and arguably stronger for the
contract argument: *three repeats of one configuration, differing only in the
workload seed, produced 0%, 38% and 0% admitted.* That is an enormous spread
across samples, which is precisely the argument for requiring repeats and
reporting spread. It is not evidence of nondeterminism.

**To upgrade to A**: state it as sample variance, not as nondeterminism. Free.

---

## Row 3 — Signal liveness: "kv_threshold never fired"

**Verdict: A. Now directly evidenced.**

Checked `decisions.jsonl` for the A10G run: across **485 decisions**,
`kv_used_fraction` ranged **0.0000 to 0.0046** against a threshold of 0.9. The
signal reached half a percent of the level required to trigger. The policy was
structurally incapable of refusing anything.

Previously this was inferred from "it admitted 100%", which is weaker — a
policy can admit everything because conditions were fine. The recorded range
settles it.

**Note**: this is the claim `signal_range` in the manifest would make automatic
rather than requiring a by-hand dig through decision logs.

---

## Row 4 — Cost model: "admit rate moves 1.8% to 100% on gamma"

**Verdict: C as an empirical claim. B as an analytical one.**

This never touched a GPU. It is a replay in which:

- arrivals were synthesized locally (`random.expovariate`), not taken from a run
- the system state was **frozen** at `running_requests=2` for every decision
- telemetry fitting was disabled so the constants stayed where I put them

So it demonstrates the *arithmetic sensitivity of the admission test* to gamma.
It does not demonstrate what the policy does on a live engine at those
constants, because on a live engine gamma also moves the fitted alpha, the
utilization, and the state the test reads.

**To upgrade**: either relabel it honestly as an analytical sensitivity of
Algorithm 1 (free, and still publishable — the cliff is real arithmetic), or
run two live configurations with gamma set explicitly (~10 min of A10G).

---

## Row 5 — Load: "the winning policy changes with offered load"

**Verdict: C. Half of it is a stub engine.**

The 0.5x-capacity half is real A10G. The overload half — `queue_depth` beating
the baseline by 12.2 points — is the **mock engine**, whose own docstring says
its numbers mean nothing about hardware. A paper cannot rest a headline row on
it.

**To upgrade to A**: the one paid run (P3, ~75 min, ~$1.40). This is the row it
exists for.

---

## Row 6 — Deadline scale: "500ms deadline against 418ms service time"

**Verdict: B. The comparison is against the wrong number.**

418ms is the **loaded** TTFT p50, measured while the workload was running. The
unloaded baseline was never measured: `infra calibrate` has not been run on this
deployment, and no bundle carries a `baseline` block.

So the honest current statement is "the deadline sat close to the loaded p50",
which is a weaker and slightly circular observation — under enough load any
deadline sits near the p50.

**To upgrade to A**: run `infra calibrate` (about 2 minutes) and compare the
deadline to the unloaded p50. That is also exactly the contract item this row is
meant to justify, so not having it is doubly awkward.

---

## Cross-cutting threats that apply to every row

| Threat | State | Cost to fix |
|---|---|---|
| **No git sha in the manifest** — bundles record `admitperf 0.0.1`, a version that never changes, so which code produced which result is unknowable. The Chronos fix landed *between* the two runs and we cannot prove from disk which side of it a bundle is on. | open | small |
| **`--out` overwrites** — destroyed row 1. | open | small |
| **One deployment, one model, one GPU** — A10G, Qwen2.5-0.5B, throughout. Nothing generalizes, and the paper must say so. | inherent | state it |
| **Synthetic workload** — Poisson over three SLO classes, not the Azure trace the contract itself asks for. | inherent | state it |
| **3 repeats, half-range not a confidence interval** — honest, but thin. | inherent | state it |
| **Signal range not recorded** — row 3 required a manual dig; not reproducible by a reader. | open | small |

---

## What this means

**For the paper**: three of six rows are publishable today (2 corrected, 3 as
is). Two need a short run. One needs its raw evidence recreated or its number
dropped. The §6.2 argument survives — the knobs are real and the mechanisms are
demonstrable — but it must be written from the audited statements, not the ones
in my earlier summaries.

**For the harness**: AdmitPerf lost a result by overwriting it and cannot say
which code produced any bundle. Those are not polish items. A tool proposing a
provenance contract that does not record its own provenance will be the first
thing a reviewer points at.

**Do these before the paid run**, because the paid run should land in a harness
that can prove what produced it:

1. record git sha + working-tree-dirty flag in every manifest
2. refuse to write into a non-empty results directory
3. record `signal_range` per run
4. `infra calibrate` on the next deployment, so row 6 has its denominator
