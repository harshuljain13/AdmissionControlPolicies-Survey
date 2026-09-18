# Admission Control for LLM Inference Serving: A Systematic Review

*Version: v0.2 draft, 2026-09-11. Ready for arXiv preprint.*
*Target: arXiv preprint (submit next), then ACM CSUR Emerging Topics.*

## Paper

- **Main draft**: `paper.md` (884 lines, 7,121 words)
- **BibTeX references**: `references.bib` (~45 entries)
- **Zero em-dashes** (per author preference, verified via `grep -c "—" paper.md`)

## Contribution

- Four-axis taxonomy for admission-control policies: unit (request / agent / tenant), setting (online / offline / hybrid), SLO awareness (deadline / throughput / fairness / cost), signal (scalar / dual-gate / LP-composite / formal WCRT).
- Four sub-branches added during reading: signal structure, SLO granularity (job / request / per-stage), fairness type (task / tenant / priority), concurrency context (concurrent-batch server / serial edge).
- Per-cluster synthesis of forty admission and admission-adjacent works.
- Reproducibility audit: 13 of 34 deep-read works have released code.
- Methodology contract proposal to enable cross-paper comparison.
- Mapping of six public production incidents (OpenAI × 5, Anthropic × 3, Azure) to admission failure modes.
- Seven open problems, each grounded in either public peer review or the primary source's own limitations.

## Three headline findings

1. **9-for-9 no ingress admission**: nine top-venue LLM serving papers (Orca OSDI '22, Sarathi-Serve OSDI '24, Llumnix OSDI '24, DistServe OSDI '24, Past-Future ASPLOS '25, Aegaeon SOSP '25, Jenga SOSP '25, AdaServe EuroSys '26, PASCAL HPCA 2026) include no ingress-level admission control. All respond to overload via batching, migration, placement, autoscaling, or memory management.
2. **Zero baseline overlap**: 14 admission-primary papers, no two share a baseline system. Cross-paper comparison is impossible from the literature alone.
3. **Empty intersection**: `agent-level × online × deadline-aware × fair` has no published entry. Direct seed for future work.

## Layout

```
survey/
├── README.md            ← this file
├── paper.tex            ← LaTeX source (compiled with tectonic)
├── paper.md             ← markdown source of truth (884 lines, 7,121 words)
├── paper.pdf            ← current compiled PDF (15 pp)
├── references.bib       ← ~45 BibTeX entries
├── docs/
│   ├── outline.md            ← original 10-section structural outline
│   ├── taxonomy.md           ← 4 axes + 4 sub-branches with policy assignments
│   ├── papers-index.md       ← 50-paper index tiered by priority
│   ├── open-problems.md      ← 37 candidate open problems, 7 selected for the paper
│   └── eval-log.md           ← bi-daily eval checkpoints (Days 2, 4, 6)
├── notes/               ← per-paper deep-read notes (34 files)
└── figures/             ← empty (figures deferred to v0.3 for CSUR submission)
```

## Related

- Umbrella roadmap: `../Roadmap.md`
- 3-week execution plan: `../steps.md`
- Deferred follow-on benchmark: `../admitbench/`
- Prior-art dossier: `../private/prior-art/`

## Reproducibility

All per-paper notes are grounded in cited primary sources. Where a paper's own numbers are quoted, the exact operating point (model, engine version, hardware, workload subset) is included. No experiments were run; this is a systematic review, not a measurement study.

## Timeline

Executed as a 14-day sprint from 2026-09-10 to 2026-09-11 (accelerated ~10x versus original 21-day plan via parallel deep-read agents). See `../steps.md` and `docs/eval-log.md` for day-by-day.

## Citation

Not yet published. Preprint pending.

## License

CC-BY 4.0 for text and tables. Per-paper notes are derivative summaries of cited primary sources.

> **`paper.tex` is the source of truth.** `paper.md` is an earlier draft kept for
> reference only; it lacks the Master classification, Signal-overhead and
> Production evidence sections and should not be edited.
