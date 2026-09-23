# ACM Computing Surveys (CSUR) submission

Submit through **ACM Manuscript Central (ScholarOne)**. Upload the PDF.

```bash
make csur          # anonymous, current default
make csur-named    # author names visible
```

## ⚠ Verify the review model before you submit

**CSUR's anonymity requirement could not be confirmed from the public guidelines**
(`dl.acm.org` blocks automated retrieval, and searches returned conflicting
signals). What is known:

- CSUR's author guidelines do **not** contain the strict double-anonymous
  instructions that sibling ACM journals carry. TODS states outright that it is
  policy to use double-blind review for all papers; TOMM requires that names,
  affiliations, funding sources and acknowledgements appear nowhere in the
  submission, and that file metadata not identify authors. CSUR states no such
  thing.
- ACM has been rolling double-anonymous review out across its journals, so the
  absence of a statement is not proof of a single-blind process.

`make csur` defaults to **anonymous**, because the asymmetry favours it: submitting
anonymised to a single-blind venue is untidy, while submitting named to a
double-anonymous one is a desk rejection. **Check ScholarOne's submission form
before uploading** and switch with `make csur-named` if CSUR is single-blind.

Two things sit in the body and would de-anonymise regardless of the class option,
so both are conditional on acmart's `\if@ACM@anonymous`:

- the artifact repository URL, which carries the GitHub username
- the name of the companion tool, whose repository carries the author names

## Scope: this is a good fit

CSUR publishes "surveys of and tutorials on areas of computing research or
practice", and describes a survey article as one that "assumes general knowledge
of the area and emphasizes classification of existing literature, developing a
perspective, and evaluating trends". That is a direct description of this paper:
a taxonomy classifying the corpus, a perspective on where admission control sits,
and an account of what the literature does and does not report.

This is why CSUR rather than TMLR. Not because TMLR rejects surveys, which it does
not, but because TMLR's scope is "the computational and mathematical principles
that enable intelligence through learning", and this is a queueing and systems
survey. Out-of-scope is TMLR's first listed desk-rejection reason.

## Length

There is no hard cap on a full survey. The 15-page limit applies only to **short**
survey papers, which CSUR describes as "well-focused perspective pieces/essays"
that must be self-contained. At 26 pages in `acmsmall` this is a full survey and
the limit does not apply.

## Prior publication and the arXiv preprint

CSUR requires "original contributions not published elsewhere", counting widely
disseminated conference proceedings and newsletters as publication. Preprint
servers are not in that list, and ACM permits preprint posting, but the guidelines
add that **prior appearance must be noted on the title page**.

So if the arXiv preprint goes up first, say so on the title page of the CSUR
submission. Confirm the current wording in ScholarOne rather than relying on this
note.

## Before submitting

- [ ] **Verify the review model** in ScholarOne (see above). This is the one that
      can cost a desk rejection.
- [ ] **CCS concepts are placeholders.** Regenerate from <https://dl.acm.org/ccs>
      and replace the `CCSXML` block. Reviewers notice defaults.
- [ ] **Keywords** reviewed.
- [ ] **Note the arXiv preprint on the title page** if it is already posted.
- [ ] Drop `anonymous` from the class options for the camera-ready.

## Note on the shared preamble

`../preamble.tex` contains `\let\Bbbk\relax` before loading `amssymb`. acmart
predefines `\Bbbk`, and without that line the CSUR build dies at load. Harmless to
the other venues.
