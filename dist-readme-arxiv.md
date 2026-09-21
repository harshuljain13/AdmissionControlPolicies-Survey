# arXiv preprint bundle

**Upload the LaTeX source, not a PDF.** arXiv compiles submissions itself and
prefers source; PDF-only submissions are accepted but discouraged and lose the
HTML rendering.

```bash
cd dist/arxiv-preprint
tar czf ../arxiv-submission.tar.gz main.tex main.bbl references.bib \
        tmlr.sty tmlr.bst fancyhdr.sty math_commands.tex
```

Upload `arxiv-submission.tar.gz`.

## What is in here, and why

| file | why it is needed |
|---|---|
| `main.tex` | the paper, built with `\usepackage[preprint]{tmlr}` so author names are visible |
| `main.bbl` | **essential.** arXiv runs LaTeX but does *not* run BibTeX. Without the `.bbl` every citation renders as `[?]` |
| `references.bib` | not strictly required once `.bbl` exists; included so the source is self-contained |
| `tmlr.sty`, `tmlr.bst`, `fancyhdr.sty`, `math_commands.tex` | not in TeX Live, so arXiv cannot fetch them |
| `reference-render.pdf` | **do not upload.** Local render, for checking arXiv's output matches |

No image files: every figure is inline TikZ.

## This version is de-anonymised, deliberately

Unlike the TMLR bundle, this one shows all four authors, the artifact repository
URL, and names the companion tool. That is correct for a preprint and is what
`[preprint]` switches on.

## Does posting to arXiv conflict with the TMLR submission?

No. TMLR forbids overlap with work "published, accepted, or concurrently under
review at another archival peer-reviewed venue", and explicitly permits preprint
servers: overlap is allowed with "venues declared non-archival in writing", naming
arXiv directly.

One rule to respect: TMLR reviewers are instructed not to search for a matching
preprint, and the review copy's anonymity must be preserved "by not linking to
another version that includes the authors' names". So do not put the arXiv link in
the OpenReview submission.

## Practical notes

- **Order matters if you want the arXiv ID in the paper.** You cannot cite your own
  arXiv ID before you have one. Post first, then add it at camera-ready if wanted.
- **arXiv may flag the `\month`/`\year` defs or the `\if@accepted` block.** Both are
  harmless; they are plain LaTeX conditionals.
- **Check the compiled result on arXiv before announcing.** arXiv uses its own TeX
  Live, not tectonic, so compare against `reference-render.pdf`. The most likely
  difference is figure placement.
