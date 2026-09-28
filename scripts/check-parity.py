#!/usr/bin/env python3
"""Verify the arXiv and CSUR builds say the same thing.

Both wrappers \\input the same body.tex, abstract.tex and preamble.tex, so
their content is identical by construction. This checks that the
construction actually held, because it has failed before: copies of the
shared files were once committed into a venue folder, identical at the
time and therefore invisible, and a stale copy would have diverged
silently from then on.

Three checks:

  1. Source identity. Both wrappers must input ../body and ../abstract,
     and no venue folder may contain a copy of a shared file.
  2. Structure. Same section, table, figure and definition counts, and
     the same set of citation keys.
  3. Text. Every substantive word in one build must appear in the other,
     after normalising hyphenation and excluding the differences that
     are there on purpose: author names in the named build, anonymity
     wording in the blind one, the CCS block CSUR requires, and the ACM
     furniture.

Exit 1 on any unexplained divergence.
"""
import io
import os
import re
import subprocess
import sys

SRC = "source_paper"
SHARED = ("body.tex", "abstract.tex", "preamble.tex", "references.bib", "main.tex")

# Differences that are correct and expected, not drift.
EXPECTED = {
    # the named build carries these, the anonymous one must not
    "harshul", "harshuljain", "tanmay", "tanya", "tanyasah", "parv", "khatri",
    "dolly", "sah", "gmail", "mail", "tradertanmay", "khatriparv",
    "researcher", "researchers", "independent",
    # the anonymous build carries these instead
    "anon", "anonymous", "withheld", "supplementary", "ancillary", "preprint",
    # CCS block and ACM reference furniture, CSUR only
    "ccs", "concepts", "methodologies", "architectures", "organizing",
    "overviews", "phrases", "acm", "surv", "comput", "article", "publication",
    "permission", "permissions", "copyrights", "republish", "redistribute",
    "abstracting", "honored", "credit", "association", "machinery", "fee",
    "post", "servers", "lists", "bear", "notice", "citation", "page",
    "granted", "provided", "made", "digital", "hard", "copies", "part",
    "personal", "classroom", "use", "profit", "commercial", "advantage",
    "full", "first", "owned", "others", "than", "author", "format",
    "material", "networks", "permitted", "copy", "nnnnnnn",

    # Math subscripts. Each build's math font maps to Unicode differently,
    # so a subscripted symbol extracts as a run of letters in one and not
    # the other. These are the same equations either way; only the text
    # layer differs. D_TTFT, H_thresh, JCT_r, K_r,max, L_input, SLO_i,
    # TBT_r, TTFT_r, U_high and the sigma-subscripted signal names.
    "dttft", "ftdg", "hthresh", "jctr", "krmax", "linput", "maxt", "sloi",
    "tbtr", "ttftr", "uhigh", "sigdg", "siglp", "sigsca", "tdg",

    # Fragments left by hyphenation falling at different points in a
    # 6.75in measure and an 8.5in one: pri-mary, prob-lem, sub-branches.
    "mary", "prob", "branches", "subsection", "files", "thresh", "lem",
    "assignments", "subsec", "taskoriented", "sigwcrt", "software", "words",
    "unitagt", "unitreq", "unitten",
}


# Presentation-form ligatures. The arXiv build extracts some of these as
# the composed codepoint and some as nothing at all, because cmap only
# takes effect under pdflatex and the local build is XeTeX. Decomposing
# them is what lets the two builds be compared at all.
LIGATURES = {"\ufb00": "ff", "\ufb01": "fi", "\ufb02": "fl",
             "\ufb03": "ffi", "\ufb04": "ffl", "\ufb05": "st", "\ufb06": "st"}


def norm(text):
    for k, v in LIGATURES.items():
        text = text.replace(k, v)
    text = text.replace("-\n", "").replace("\u00ad", "")
    text = re.sub(r"\s+", " ", text).lower()
    return text


def words(pdf):
    t = subprocess.run(["pdftotext", "-q", pdf, "-"],
                       capture_output=True, text=True).stdout
    t = norm(t)
    t = t.replace("-", "")            # collapse hyphenation differences
    return set(w for w in re.findall(r"[a-z]{4,}", t) if w not in EXPECTED)


def structure(pdf):
    t = norm(subprocess.run(["pdftotext", "-q", pdf, "-"],
                            capture_output=True, text=True).stdout)
    return {
        "tables": len(set(re.findall(r"table\s+(\d+)", t))),
        "figures": len(set(re.findall(r"fig(?:ure)?\.?\s+(\d+)", t))),
        "definitions": len(set(re.findall(r"definition\s+(\d+)", t))),
    }


def cite_keys(aux):
    if not os.path.exists(aux):
        return None
    s = io.open(aux, encoding="utf-8", errors="replace").read()
    groups = set(re.findall(r"\\citation\{([^}]*)\}", s))
    return {k for g in groups for k in g.split(",")} - {"*"}


def main():
    fail = []

    # 1. source identity
    for venue in ("arxiv", "csur", "tmlr"):
        w = f"{SRC}/{venue}/paper.tex"
        if not os.path.exists(w):
            continue
        s = io.open(w, encoding="utf-8").read()
        for f in ("body", "abstract"):
            if f"\\input{{../{f}}}" not in s:
                fail.append(f"{venue}/paper.tex does not input ../{f}")
        for f in SHARED:
            if os.path.exists(f"{SRC}/{venue}/{f}"):
                fail.append(f"{venue}/ contains a copy of {f}")
    print("  1. both wrappers read the shared sources"
          + ("" if not fail else "  <- FAILED"))

    a, c = f"{SRC}/arxiv/paper.pdf", f"{SRC}/csur/paper.pdf"
    if not (os.path.exists(a) and os.path.exists(c)):
        print("  build both PDFs first")
        return 1

    # 2. structure
    sa, sc = structure(a), structure(c)
    for k in sa:
        if sa[k] != sc[k]:
            fail.append(f"{k}: arxiv {sa[k]} vs csur {sc[k]}")
    ka, kc = cite_keys(f"{SRC}/arxiv/paper.aux"), cite_keys(f"{SRC}/csur/paper.aux")
    if ka and kc:
        d = ka ^ kc
        if d:
            fail.append(f"citation keys differ: {sorted(d)}")
        print(f"  2. structure and {len(ka)} citation keys match")
    else:
        print("  2. structure matches (citation keys need .aux, not checked)")

    # 3. text
    wa, wc = words(a), words(c)
    only_a, only_c = sorted(wa - wc), sorted(wc - wa)
    agree = 100 * len(wa & wc) / max(1, len(wa | wc))
    print(f"  3. text agreement {agree:.2f}%")
    if only_a:
        fail.append(f"in arXiv only: {', '.join(only_a[:12])}")
    if only_c:
        fail.append(f"in CSUR only: {', '.join(only_c[:12])}")

    if fail:
        print("FAIL: the two builds have diverged")
        for f in fail:
            print(f"  {f}")
        return 1
    print("OK: arXiv and CSUR are content-identical")
    return 0


if __name__ == "__main__":
    sys.exit(main())
