# Supplementary material

Audit trail for "Admission Control for LLM Inference Serving: A Systematic
Review". Everything here is plain markdown and needs no tooling to read.

The paper states that the per-paper coding sheets, taxonomy placements, and
inclusion and exclusion decisions are released to support third-party audit and
to reproduce the master table. This archive is that release. The public
repository is withheld for anonymous review.

## notes/

Forty coding sheets, one per work read at depth. Each records what the policy
decides, on what signal, at what granularity, and what the paper does and does
not report.

These are the working notes the master table was built from rather than
write-ups produced afterwards, so some contain judgments that were later
revised and a few that were reversed. That is deliberate. A reviewer who
disagrees with a placement can see the reasoning that produced it instead of
only the result.

Where a note carries a caveat such as "verify before quoting", the caveat is
live. Those claims were checked against the primary source before use, and in
two cases the check changed what the paper says.

## docs/

| file | what it is |
|---|---|
| `applicability.md` | The seven properties recorded for each of the sixteen admission-primary papers. This is the evidence behind the third finding: six columns fill from published text, and one fills for no paper in the set. |
| `papers-index.md` | The corpus by tier, carrying the inclusion or exclusion decision for each work and the artifact status per tier. |
| `taxonomy.md` | Axis definitions and per-work placements, at more length than the paper allows. |
| `open-problems.md` | Working notes behind the seven open problems, including the published evidence cited for each. |

## What is not here

Project-management files, drafting scaffolding, and notes naming people who
commented on earlier drafts are excluded. The first two are not audit material;
the last would compromise anonymous review. Notes naming the companion tooling
are excluded for the same reason, since that name is withheld from the
manuscript under anonymous review.

LaTeX sources and compiled artifacts are excluded as production material rather
than review material.
