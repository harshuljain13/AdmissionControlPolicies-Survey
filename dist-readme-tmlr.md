# TMLR submission bundle

**Upload `paper.pdf` to OpenReview. That is the whole submission.**

TMLR takes a PDF, not LaTeX source. From the author guide: the file "must be PDF,
generated using the TMLR LaTeX stylefile and template". Source is never requested,
not even at camera-ready.

## Before you upload

- [ ] **The PDF is anonymous.** This bundle is built by `make dist`, which runs the
      `anon` gate first: it greps the rendered PDF for author names, emails, the
      artifact repository URL and the companion tool's name. The build fails if any
      appear. TMLR states that "non-anonymous submissions will be rejected without
      review", so do not substitute a hand-built PDF here.
- [ ] **All four authors have active OpenReview profiles**, with affiliations,
      conflicts of interest and publication history filled in. TMLR checks this at
      intake.
- [ ] **Each author has remaining submission quota** under the Generalized Harmonic
      Quota Rule. Desk-rejected submissions still consume quota.
- [ ] **Suggest action editors** when prompted.
- [ ] **Declare** funding, competing interests, and any conflicts not implied by
      institutional history. These stay hidden from reviewers until a decision.

## Not needed

- **Broader Impact Statement** — required only if the work carries significant risk
  of harm. A literature survey does not.
- **Author Contributions** and **Acknowledgments** — the template says to add these
  only once accepted and de-anonymised. Both would de-anonymise the submission.
- **Supplementary material** — optional, up to 100MB, PDF or ZIP, and it must be
  anonymised too. The per-paper coding sheets would go here if you choose to
  include them; §8.1 currently refers to them as supplementary material.

## After acceptance

Rebuild with `make camera`, which passes `[accepted]` to the tmlr package. That
reveals the author block, the artifact URL and the companion tool's name, all of
which are conditional on `\if@accepted` in `paper.tex`. Set `\month` and `\year`,
and add the OpenReview forum link to `\openreview`.
