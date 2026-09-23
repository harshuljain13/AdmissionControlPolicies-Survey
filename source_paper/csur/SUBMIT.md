# ACM Computing Surveys (CSUR) submission

**Upload `paper.pdf`** via ACM's Manuscript Central / ScholarOne portal for CSUR.

## Build

```bash
make csur
```

Produces `paper.pdf` with `[acmsmall,review,anonymous]`: line-numbered for
reviewers and with authors suppressed. `make csur` fails if any identifying
string reaches the rendered PDF.

## Why CSUR rather than TMLR

Not because TMLR rejects surveys; it has a Survey Certification for work that is
"an exceptionally thorough or insightful survey". The issue is subject matter.
TMLR publishes work advancing "the computational and mathematical principles that
enable intelligence through learning", and this survey is queueing and systems.
Out-of-scope is the first listed desk-rejection reason there, decided within a
week. CSUR is the venue for systematic reviews in computing, where a systems
survey needs no argument to belong.

## Anonymity

CSUR review is double-blind. The `anonymous` class option suppresses the author
block, but two things sit in the body and would leak past it, so both are
conditional on acmart's `\if@ACM@anonymous`:

- the artifact repository URL, which carries the GitHub username
- the name of the companion tool, whose repository carries the author names

Drop `anonymous` from the class options for the camera-ready.

## Before submitting

- [ ] **CCS concepts** are placeholders. Regenerate them from the ACM CCS tool at
      <https://dl.acm.org/ccs> and paste the real `CCSXML` block. Reviewers do
      notice defaults.
- [ ] **Keywords** reviewed.
- [ ] **`\country{}`** is set to India for all four authors. Correct if wrong;
      acmart warns when it is missing.
- [ ] **Length.** CSUR has no hard limit but expects comprehensiveness; 26 pages
      in `acmsmall` is within normal range for the venue.
- [ ] **ACM's authorship and conflict policies** reviewed separately from the
      formatting requirements.

## Note on the shared preamble

`../preamble.tex` contains `\let\Bbbk\relax` before loading `amssymb`. acmart
predefines `\Bbbk`, and without that line the CSUR build dies at load time. It is
harmless to the other venues.
