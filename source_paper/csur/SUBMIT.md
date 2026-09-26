# ACM Computing Surveys (CSUR) submission

Submit through **ACM Manuscript Central (ScholarOne)**.

```bash
make csur          # anonymous, current default
make csur-named    # author names visible
make cover         # one-page cover letter
make supp          # the supplementary archive
```

## What to upload

| slot | file | designation |
|---|---|---|
| 1 | `paper.pdf` | Manuscript |
| 2 | `cover-letter.pdf` | Cover letter, or paste `COVER-LETTER.md` into the form |
| 3 | `supplementary.zip` | Supplemental Material |

The third is not optional. Under `anonymous` the paper tells reviewers the
coding sheets "are included as supplementary material", so submitting without
it breaks a promise the manuscript makes in two places (§8 and §11).

`make supp` builds it from `notes/` and `docs/`, and scans the built zip rather
than the staging directory, so what is scanned is what is uploaded. It carries
forty per-paper coding sheets, the four taxonomy documents, and a README
explaining what a reviewer is looking at.

Five files are excluded by name and the exclusion is load-bearing. Four of them
(`sensitivity-table`, `evidence-audit`, `numbers-ledger`,
`web-verification-2026-09-17`) name the companion tool, whose repository
carries the authors' names. The paper goes to some trouble to hide that name
under `anonymous`, and shipping it in the supplement would undo that. The
fifth, `section-6.2-why-this-minimum`, is a draft for a section that no longer
exists and carries empirical claims the paper deliberately does not make.

Also excluded, for different reasons: `docs/reviewer-responses.md` names a
person who commented on an earlier draft, and `docs/eval-log.md` and
`docs/outline.md` are project-management files rather than audit material.

The gate fails on any new file naming the tool, so adding a note and forgetting
to check cannot leak.

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
that must be self-contained. At 30 pages in `acmsmall` this is a full survey and
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

### acmart version: shipping on 1.83, knowingly

The build uses **acmart 1.83 (2022/02/19)**. Current is **2.20 (2026/08/16)**,
a major version and four years newer. This is not a choice: Tectonic 0.17 bundles
TeX Live 2022, and no newer bundle is published at its host. Generating 2.20 from
CTAN needs docstrip, which Tectonic sandboxes against, so it needs a full TeX
installation (`brew install --cask mactex-no-gui`, around 4 GB).

Shipping on 1.83 is the deliberate call. 1.83 still produces a structurally valid
ACM article, CSUR's guidelines do not name a required version, and production
normalises formatting anyway. Against that, a major-version bump the night before
submission can move page counts, break a table that is already tight to the
margin, and introduce warnings with no time to absorb them.

Worth doing after submission, not before. If a reviewer or production asks for
the current template, install MacTeX and rebuild; nothing in the source is
version-specific.

### Bibliography completeness

`ACM-Reference-Format` is far stricter than the TMLR style was. Warnings are down
from 117 to 28, with nothing invented:

| fixed | how |
|---|---|
| 27 publishers, 24 addresses | determined by the venue: USENIX Association / Berkeley; ACM / New York; Curran / Red Hook; IEEE / Piscataway; ACL / Stroudsburg |
| 16 arXiv entries | `@article` carrying a fabricated `journal={arXiv preprint ...}` became `@misc` with `eprint`. A preprint has no volume, number or pages, so those warnings were the style file objecting to the entry type |
| 1 technical report | Jain 1984 was an `@article` with the report number in the journal field; now `@techreport` |
| 8 page ranges | pulled from CrossRef (QLM, AQUA, Aegaeon, Jenga, Past-Future, AdaServe, OmniServe) and OpenAlex (PagedAttention, Pie, KVFlow, MLPerf), each matched on title before accepting |

**The remaining 28 break down as follows.**

Twenty lack page ranges. Roughly half are USENIX proceedings (Orca, Sarathi,
Llumnix, DistServe, VTC, Mooncake, FastServe, ServeGen); USENIX does not expose
page numbers in a machine-readable form and its site returns 403 to scripted
requests, so these need reading off the proceedings PDF. Five are ICML or PMLR
papers whose volumes are not yet indexed. The rest are individually awkward:
Chronos is in Frontiers, which assigns article numbers rather than pages;
Mitzenmacher and Shahout is a tutorial with no page range; Token Pools is at a
first-edition venue that is not yet indexed anywhere.

Six lack an address, all PMLR or MLSys, neither of which has a fixed publisher
address to state. Two lack a volume, correctly.

None of this is fatal and the bibliography renders. ACM production will ask for
the page ranges rather than reject the submission, and this section is the
worklist if they do.

## Before submitting

- [ ] **Verify the review model** in ScholarOne (see above). This is the one that
      can cost a desk rejection, and it is the only open item that cannot be
      settled from outside the submission system.
      **Default is anonymous** and stays that way unless the form says otherwise,
      because the two errors are not symmetric: anonymised to a single-blind
      venue is untidy, named to a double-anonymous venue is a desk rejection.
      If the form says single-blind, `make csur-named` and re-upload. Everything
      else is already conditional on the class option, so nothing else changes.
- [x] **CCS concepts** set. "Surveys and overviews" is the anchor at 500,
      alongside NLP and neural networks; distributed architectures and
      distributed-systems principles at 300.
- [x] **Keywords** set. CCS predates LLM serving and cannot name it, so the
      keyword block carries the terms a reader or search engine would actually
      use, including "LLM inference serving" and "GPU serving".
- [x] **Supplementary archive** built and scanned. `make supp`.
- [ ] **Note the arXiv preprint on the title page** if it is already posted. The cover letter already tells the editors this is intended.
- [ ] **Address the cover letter** to a named editor if ScholarOne asks for one.
- [ ] Drop `anonymous` from the class options for the camera-ready.

## Note on the shared preamble

`../preamble.tex` contains `\let\Bbbk\relax` before loading `amssymb`. acmart
predefines `\Bbbk`, and without that line the CSUR build dies at load. Harmless to
the other venues.
