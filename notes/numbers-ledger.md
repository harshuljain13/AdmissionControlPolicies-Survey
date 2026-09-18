# Numbers ledger

*2026-09-17. Every corpus count in the paper, where it comes from, and what it
was before. Written because three different numbers for the same quantity were
in circulation and a reviewer can add up a tier list.*

## The tier list is the source of truth

| Tier | What it holds | Was | Now | Change |
|---|---|---|---|---|
| 1 | admission-primary | 15 | **16** | + Scorpio (WISE 2026) |
| 2 | queueing/fairness-primary, admission-adjacent | 8 | **9** | + Niyama |
| 3 | KV-cache management with admission implications | 6 | 6 | |
| 4 | top-venue scheduling, admission secondary or absent | 9 | 9 | |
| 5 | foundational background | 6 | 6 | |
| 6 | prior surveys, for differentiation | 5 | **6** | + Ma et al. 2026 |

Derived:

- **Deep-read corpus** = tiers 1 to 4 = 16 + 9 + 6 + 9 = **40**
- **Background** = tiers 5 and 6 = 6 + 6 = **12**
- **Total surveyed** = **52**

## What was wrong before

| Claim | Old value | Problem |
|---|---|---|
| deep-read works | "thirty-four" in paper.md, "thirty-eight" in paper.tex | the two files disagreed; neither matched the tier sum |
| total corpus | "forty works" (md), "forty-four" (tex) | tiers summed to 49, so both were wrong |
| "40 papers deep-read" in 4.2 | 40 | tiers 1 to 4 summed to 38 at the time |
| admission-primary | "fourteen" | Tier 1 held 15 |
| Table 2 rows | 9, presented as the full set | the text implied all admission-primary papers were tabulated |

## The claim that had to change, and why

Finding 2 read: *"no two share a baseline system, metric definition, trace,
model, or engine."*

Table 2 refutes it. Counting ticks by column: **vLLM 5** (QLM, SOLA, FastServe,
SLOs-Serve, Fluid-WAIT), **Sarathi 3**, and EDF, FCFS, SHEPHERD, DistServe at 2
each. The neighbouring sentence, "zero column has more than three ticks", was
also false.

The finding now reads: the only baseline shared by more than one paper is an
unconfigured serving engine, which is the absence of admission control rather
than an alternative to it; exactly one published admission policy (SHEPHERD) is
used as a baseline by two papers (QLM and Ascendra). Policies are measured
against doing nothing, almost never against each other.

This is checkable from the same table and says something worse about the field
than the sentence it replaces.

## Still to verify before submission

- Scorpio's Table 2 row currently records only vLLM. Its paper also names **S3**
  and **Mooncake**; Mooncake is itself early-rejection admission control, which
  would make Scorpio one of the rare policy-versus-policy comparisons. Add both
  columns once the evaluation section is read in full.
- Niyama is filed in Tier 2 on the strength of its abstract ("selective request
  relegation ... graceful service degradation during overload"). Confirm on a
  full read that relegation is admission-adjacent rather than pure scheduling.
- The nine further works in `web-verification-2026-09-17.md` are not yet
  classified. Each needs either a tier or a stated exclusion.
- `paper.md` and `paper.tex` have drifted before. Decide which is authoritative
  and say so in the README.
