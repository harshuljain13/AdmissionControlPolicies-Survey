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

## Verifying the format

```bash
make verify     # mechanical checks: trim size, fonts, CCS, keywords,
                # reference block, anonymity, unresolved citations
make bibwarn    # what ACM-Reference-Format wants that the .bib omits
```

`make verify` covers what a machine can check. Note that acmsmall's trim size is
6.75 x 10 inches (486 x 720 pt), **not** US Letter; a checker expecting Letter will
report a false failure.

What it cannot check, and a human must:

- whether the CCS concepts are the *right* ones, only that they exist
- whether prose, tables and figures read correctly at acmsmall's narrower measure
- ACM's authorship, conflict and originality policies

### Bibliography completeness

`ACM-Reference-Format` is far stricter than the TMLR style. The count went from
117 warnings to 33:

| fixed | how |
|---|---|
| 27 publishers, 24 addresses | filled from the venue, which fixes them: USENIX Association / Berkeley CA; ACM / New York NY; Curran / Red Hook NY; IEEE / Piscataway NJ; ACL / Stroudsburg PA |
| 16 arXiv entries | `@article` with a fake `journal={arXiv preprint ...}` became `@misc` with `eprint`/`archivePrefix`. A preprint has no volume, number or page range, so the warnings were the style file correctly objecting to the entry type |
| 1 technical report | Jain's 1984 fairness index was an `@article` with the report number in the journal field; now `@techreport` with `number` and `institution` |

**The remaining 33 are deliberate:**

- **26 missing page ranges.** These are real and would need looking up per paper in
  the ACM DL, USENIX or PMLR listing. Nothing was invented. If ACM production asks,
  this is the list to work through.
- **6 missing addresses**, all PMLR or MLSys, neither of which has a fixed
  publisher address to state.
- **1 missing volume**, the SIGMETRICS tutorial, which has none.

The bibliography renders correctly in all cases; these are completeness notes,
not errors.

## Before submitting

- [ ] **Verify the review model** in ScholarOne (see above). This is the one that
      can cost a desk rejection.
- [x] **CCS concepts** set. "Surveys and overviews" is the anchor at 500,
      alongside NLP and neural networks; distributed architectures and
      distributed-systems principles at 300.
- [x] **Keywords** set. CCS predates LLM serving and cannot name it, so the
      keyword block carries the terms a reader or search engine would actually
      use, including "LLM inference serving" and "GPU serving".
- [ ] **Note the arXiv preprint on the title page** if it is already posted.
- [ ] Drop `anonymous` from the class options for the camera-ready.

## Note on the shared preamble

`../preamble.tex` contains `\let\Bbbk\relax` before loading `amssymb`. acmart
predefines `\Bbbk`, and without that line the CSUR build dies at load. Harmless to
the other venues.
