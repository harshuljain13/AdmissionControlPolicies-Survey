# One source, two venues.
#
#   source_paper/body.tex        the content. Edit this.
#   source_paper/tmlr/           anonymous build, for TMLR via OpenReview
#   source_paper/arxiv/          de-anonymised build, for arXiv
#
# Everything a venue needs lives in that venue's folder. There is no
# separate staging tree.
#
#   make csur     -> source_paper/csur/paper.pdf       upload to ACM CSUR
#   make tmlr     -> source_paper/tmlr/paper.pdf       upload to OpenReview
#   make arxiv    -> source_paper/arxiv/upload.tar.gz  upload to arXiv
#   make check    tmlr build + gate on refs, em-dashes, anonymity
#   make camera   camera-ready, post-acceptance
#
# Build with tectonic; `brew install tectonic` if missing.

# Pin the build timestamp so the PDFs are bit-reproducible. Without this,
# tectonic embeds the current time and every rebuild produces a diff even
# when nothing changed, which is noise in history and a merge conflict
# waiting to happen between four authors.
export SOURCE_DATE_EPOCH := 1700000000

TECTONIC ?= tectonic
SRC      := source_paper
TMLR     := $(SRC)/tmlr
ARXIV    := $(SRC)/arxiv
CSUR     := $(SRC)/csur
WORKSHOP := $(SRC)/workshop-paper

.PHONY: all tmlr arxiv csur csur-named csur-camera cover camera workshop workshop-mlsys workshop-iclr workshop-preprint wsgate check text supp style anon verify links clean

all: check

## tmlr — anonymous build. This PDF is the TMLR submission.
tmlr:
	$(TECTONIC) -X compile $(TMLR)/paper.tex --keep-logs

## csur — ACM Computing Surveys, anonymous for review.
## acmart ships with TeX Live, so nothing is vendored into csur/.
csur:
	$(TECTONIC) -X compile $(CSUR)/paper.tex --keep-logs
	@if ! command -v pdftotext >/dev/null 2>&1; then exit 0; fi; \
	 hits=$$(pdftotext $(CSUR)/paper.pdf - 2>/dev/null | \
	   grep -icE "harshuljain|tanmay|tanya sah|parv|khatri|dolly|@gmail|AdmissionControlPolicies|AdmitPerf" || true); \
	 if [ "$$hits" != "0" ]; then echo "FAIL: $$hits identifying string(s)"; exit 1; \
	 else echo "OK: $(CSUR)/paper.pdf anonymous"; fi

## cover — the CSUR cover letter, one page, not anonymised.
## Goes in the ScholarOne cover-letter field or attached as PDF.
cover:
	$(TECTONIC) -X compile $(CSUR)/cover-letter.tex
	@n=$$(pdfinfo $(CSUR)/cover-letter.pdf 2>/dev/null | awk '/^Pages/{print $$2}'); \
	 if [ "$$n" = "1" ]; then echo "OK: $(CSUR)/cover-letter.pdf (1 page)"; \
	 else echo "WARN: cover letter is $$n pages; one is conventional"; fi
	@# the letter quotes the manuscript's page count; fail if they disagree
	@l=$$(grep -oE '[0-9]+ pages in the acmsmall' $(CSUR)/cover-letter.tex | grep -oE '^[0-9]+'); \
	 p=$$(pdfinfo $(CSUR)/paper.pdf 2>/dev/null | awk '/^Pages/{print $$2}'); \
	 if [ -n "$$p" ] && [ "$$l" != "$$p" ]; then \
	   echo "FAIL: letter says $$l pages, paper is $$p"; exit 1; \
	 else echo "OK: letter's page count matches the manuscript"; fi

## csur-named — same, with author names visible.
## Use only if ScholarOne confirms CSUR is single-blind; see csur/SUBMIT.md.
csur-named:
	@sed 's|\[acmsmall,review,anonymous\]|[acmsmall,review]|' \
	    $(CSUR)/paper.tex > $(CSUR)/named.tex
	$(TECTONIC) -X compile $(CSUR)/named.tex
	@rm -f $(CSUR)/named.tex
	@echo "OK: $(CSUR)/named.pdf (author names visible)"

## csur-camera — camera-ready. Drops both [review] and [anonymous], which
## reveals the author block, the artifact URL and the companion tool's name.
## Nothing in body.tex changes; the three are conditional on acmart's
## \if@ACM@anonymous.
csur-camera:
	@sed 's|\[acmsmall,review,anonymous\]|[acmsmall]|' \
	    $(CSUR)/paper.tex > $(CSUR)/camera.tex
	$(TECTONIC) -X compile $(CSUR)/camera.tex
	@rm -f $(CSUR)/camera.tex
	@echo
	@echo "OK: $(CSUR)/camera.pdf"
	@echo "Before sending to ACM, fill in the fields they assign:"
	@echo "  acmVolume, acmNumber, acmArticle, acmDOI, received"
	@echo "and add Acknowledgments / Author Contributions if wanted; both"
	@echo "would have de-anonymised the submission, so neither exists yet."

## arxiv — de-anonymised PDF, plus the flat tarball arXiv wants.
## arXiv compiles source itself and does NOT run bibtex, so the .bbl ships.
arxiv:
	$(TECTONIC) -X compile $(ARXIV)/paper.tex --keep-intermediates --keep-logs
	@cd $(ARXIV) && cp ../body.tex ../abstract.tex ../preamble.tex ../references.bib . && \
	 sed 's|{\.\./|{|g' paper.tex > main.tex && \
	 cp paper.bbl main.bbl && \
	 tar czhf upload.tar.gz main.tex main.bbl body.tex abstract.tex \
	     preamble.tex references.bib tmlr.sty tmlr.bst fancyhdr.sty && \
	 rm -f main.tex main.bbl body.tex abstract.tex preamble.tex references.bib
	@echo
	@echo "  $(ARXIV)/paper.pdf       <- read or share this"
	@echo "  $(ARXIV)/upload.tar.gz   <- upload this to arXiv"

## verify — mechanical format checks against the CSUR build.
## Everything here is checkable without a human; the rest is in
## source_paper/csur/SUBMIT.md.
verify: csur
	@echo
	@echo "=== ACM CSUR format verification ==="
	@fail=0; \
	 printf '%-34s' "acmsmall trim size"; \
	 sz=$$(pdfinfo $(CSUR)/paper.pdf 2>/dev/null | awk '/Page size/{print $$3"x"$$5}'); \
	 case "$$sz" in 486x720) echo "OK ($$sz pt = 6.75x10in)";; *) echo "FAIL ($$sz, acmsmall is 486x720)"; fail=1;; esac; \
	 printf '%-34s' "all fonts embedded"; \
	 ne=$$(pdffonts $(CSUR)/paper.pdf 2>/dev/null | awk 'NR>2 && $$5=="no"' | wc -l | tr -d ' '); \
	 if [ "$$ne" = "0" ]; then echo "OK"; else echo "FAIL ($$ne not embedded)"; fail=1; fi; \
	 printf '%-34s' "CCS concepts present"; \
	 pdftotext $(CSUR)/paper.pdf - 2>/dev/null | grep -q "CCS Concepts" && echo "OK" || { echo "FAIL"; fail=1; }; \
	 printf '%-34s' "keywords present"; \
	 pdftotext $(CSUR)/paper.pdf - 2>/dev/null | grep -q "Additional Key Words" && echo "OK" || { echo "FAIL"; fail=1; }; \
	 printf '%-34s' "ACM reference format block"; \
	 pdftotext $(CSUR)/paper.pdf - 2>/dev/null | grep -q "ACM Reference Format" && echo "OK" || { echo "FAIL"; fail=1; }; \
	 printf '%-34s' "anonymous"; \
	 h=$$(pdftotext $(CSUR)/paper.pdf - 2>/dev/null | grep -icE "harshuljain|tanmay|tanya sah|parv|khatri|dolly|@gmail|AdmissionControlPolicies|AdmitPerf" || true); \
	 if [ "$$h" = "0" ]; then echo "OK"; else echo "FAIL ($$h strings)"; fail=1; fi; \
	 printf '%-34s' "no unresolved refs/cites"; \
	 n=$$(pdftotext $(CSUR)/paper.pdf - 2>/dev/null | grep -c "\[?\]" || true); \
	 if [ "$$n" = "0" ]; then echo "OK"; else echo "FAIL ($$n)"; fail=1; fi; \
	 printf '%-34s' "bibliography completeness"; \
	 b=$$(grep -c "^Warning--" $(CSUR)/paper.blg 2>/dev/null || echo 0); \
	 if [ "$$b" = "0" ]; then echo "OK"; else echo "$$b warnings (see 'make bibwarn')"; fi; \
	 echo; \
	 if [ $$fail -eq 0 ]; then echo "format checks passed"; else echo "FORMAT CHECKS FAILED"; exit 1; fi

## links — resolve every url, doi and arXiv id in the bibliography.
## ACM DL, USENIX and SSRN return 403 to scripted requests; those are
## reported separately since a 403 means bot-blocked, not broken.
links:
	@echo "resolving every link in references.bib ..."
	@grep -oE '(url|doi|eprint)[[:space:]]*=[[:space:]]*\{[^}]+\}' $(SRC)/references.bib \
	  | sed -e 's/^url[[:space:]]*=[[:space:]]*{//' \
	        -e 's/^doi[[:space:]]*=[[:space:]]*{/https:\/\/doi.org\//' \
	        -e 's/^eprint[[:space:]]*=[[:space:]]*{/https:\/\/arxiv.org\/abs\//' \
	        -e 's/}$$//' | sort -u > /tmp/.bl; \
	 ok=0; blocked=0; bad=0; \
	 while read u; do \
	   c=$$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 15 -A "Mozilla/5.0" "$$u" 2>/dev/null); \
	   case "$$c" in \
	     2*|3*) ok=$$((ok+1));; \
	     403)   blocked=$$((blocked+1));; \
	     *)     bad=$$((bad+1)); echo "  DEAD $$c  $$u";; \
	   esac; \
	 done < /tmp/.bl; \
	 echo "  $$ok resolved, $$blocked bot-blocked (403, not broken), $$bad dead"; \
	 [ $$bad -eq 0 ] || exit 1

## bibwarn — what ACM-Reference-Format wants and the .bib does not supply
bibwarn: csur
	@grep "^Warning--" $(CSUR)/paper.blg | sed 's/^Warning--//' | \
	  awk '{k=$$0; sub(/ in [^ ]+$$/,"",k); c[k]++} END{for(i in c) printf "  %4d  %s\n", c[i], i}' | sort -rn

## camera — camera-ready, post-acceptance
camera:
	@sed 's|^\\usepackage{tmlr}$$|\\usepackage[accepted]{tmlr}|' \
	    $(TMLR)/paper.tex > $(TMLR)/camera.tex
	$(TECTONIC) -X compile $(TMLR)/camera.tex
	@rm -f $(TMLR)/camera.tex
	@echo "OK: $(TMLR)/camera.pdf"

## text — every build's text must be machine-extractable.
## Ligatures in T1-encoded Type1 fonts break this silently:
## "classification" extracts as "classi" + "cation", so pdftotext,
## Google Scholar and screen readers all see neither. Only catchable by
## looking for words that are definitely in the paper.
text:
	@fail=0; for f in $(CSUR)/paper.pdf $(TMLR)/paper.pdf $(ARXIV)/paper.pdf; do \
	  [ -f $$f ] || continue; \
	  for w in classification specific efficiency insufficient; do \
	    n=$$(pdftotext -q $$f - 2>/dev/null | grep -oc $$w || true); \
	    if [ "$$n" = "0" ]; then echo "FAIL: $$f cannot extract '$$w'"; fail=1; fi; \
	  done; done; \
	 if [ $$fail = 0 ]; then echo "OK: every build is text-extractable"; else exit 1; fi

## supp — the supplementary archive the anonymous paper promises.
## Rebuilds from notes/ and docs/, then scans the built zip rather than
## the staging tree, so what is scanned is what gets uploaded.
##
## Five notes files are excluded and the exclusion is load-bearing.
## Four name the companion tool, whose repository carries the authors'
## names; the manuscript hides that name under \if@ACM@anonymous, and
## shipping it in the supplement would undo that in one search. The
## fifth drafts a section that no longer exists and carries empirical
## claims the paper deliberately does not make. Two of the five also
## argue about paper.md, a file deleted in 988f24f, which reads as an
## open process question that was settled weeks ago.
SUPPEXCL := numbers-ledger section-6.2-why-this-minimum evidence-audit \
            sensitivity-table web-verification-2026-09-17
supp:
	@rm -rf /tmp/survey-supp && mkdir -p /tmp/survey-supp/notes /tmp/survey-supp/docs
	@cp notes/*.md /tmp/survey-supp/notes/
	@for f in $(SUPPEXCL); do rm -f /tmp/survey-supp/notes/$$f.md; done
	@for f in applicability papers-index taxonomy open-problems; do cp docs/$$f.md /tmp/survey-supp/docs/; done
	@cp $(CSUR)/supp-README.md /tmp/survey-supp/README.md
	@find /tmp/survey-supp \( -name '.DS_Store' -o -name '*.swp' -o -name '*~' \) -delete
	@rm -f $(CSUR)/supplementary.zip
	@cd /tmp/survey-supp && zip -qrX $(CURDIR)/$(CSUR)/supplementary.zip README.md notes docs -x '.*' '*/.*'
	@python3 -c "import zipfile,re,sys,os; \
	 p='$(CSUR)/supplementary.zip'; z=zipfile.ZipFile(p); \
	 n=[x for x in z.namelist() if not x.endswith('/')]; \
	 pat=re.compile(rb'harshul|tanmay|tanya sah|khatri|\\bparv\\b|harshuljain13|AdmissionControlPolicies|@gmail|\\badmitperf\\b|\\baudible\\b|\\bamazon\\b|/Users/|paper\\.md',re.I); \
	 bad=[x for x in n if pat.search(z.read(x))]; \
	 sys.exit('FAIL: identifying strings in '+', '.join(bad)) if bad else \
	 print('OK: supplementary.zip, %d files, %.0f KB, no identifying strings' % (len(n), os.path.getsize(p)/1024))"

## workshop — the signal-liveness workshop paper, all three builds.
## body.tex and abstract.tex are venue neutral; each wrapper carries the
## venue's own class, author block and bibliography style. Style files
## are vendored per folder because tectonic ignores TEXINPUTS.
##
##   mlsys     MLSys, two column, mlsys2026.sty from the conference
##   iclr      ICLR, single column, iclr2027_conference.sty from the
##             official Master-Template
##   preprint  neither venue, names visible, for circulation
##
## Both venue builds are anonymous by default. That includes the
## self-citation to the companion survey, which is the leak authors
## routinely miss: the bibliography names all five of us even when the
## title block does not. \surveyref selects the anonymised key.
workshop: workshop-mlsys workshop-iclr workshop-preprint

workshop-mlsys:
	@cd $(WORKSHOP)/mlsys && $(TECTONIC) -X compile paper.tex >/dev/null
	@$(MAKE) --no-print-directory wsgate WS=$(WORKSHOP)/mlsys ANON=1

workshop-iclr:
	@cd $(WORKSHOP)/iclr && $(TECTONIC) -X compile paper.tex >/dev/null
	@$(MAKE) --no-print-directory wsgate WS=$(WORKSHOP)/iclr ANON=1

workshop-preprint:
	@cd $(WORKSHOP)/preprint && $(TECTONIC) -X compile paper.tex >/dev/null
	@$(MAKE) --no-print-directory wsgate WS=$(WORKSHOP)/preprint ANON=0

## wsgate — shared checks. ANON=1 additionally forbids author names,
## which catches the bibliography self-citation.
wsgate:
	@p=$(WS)/paper.pdf; \
	 n=$$(pdftotext -q $$p - 2>/dev/null | grep -c '\[?\]' || true); \
	 [ "$$n" = "0" ] || { echo "FAIL: $(WS) has $$n unresolved citation(s)"; exit 1; }; \
	 n=$$(pdftotext -q $$p - 2>/dev/null | grep -c '—' || true); \
	 [ "$$n" = "0" ] || { echo "FAIL: $(WS) has $$n em-dash(es)"; exit 1; }; \
	 if [ "$(ANON)" = "1" ]; then \
	   n=$$(pdftotext -q $$p - 2>/dev/null | grep -icE "harshul|tanmay|tanya sah|khatri|dolly|@gmail" || true); \
	   [ "$$n" = "0" ] || { echo "FAIL: $(WS) leaks $$n identifying string(s)"; exit 1; }; \
	 fi; \
	 echo "OK: $$p ($$(pdfinfo $$p | awk '/^Pages/{print $$2}') pages$(if $(filter 1,$(ANON)),, , named))"

## check — build the TMLR PDF, then gate it
check: tmlr style anon text
	@if grep -qiE 'undefined (reference|citation)' $(TMLR)/paper.log; then \
		echo "FAIL: unresolved references or citations:"; \
		grep -iE 'undefined (reference|citation)' $(TMLR)/paper.log; exit 1; \
	else echo "OK: every ref and cite resolves"; fi

## style — author convention: no em-dashes
style:
	@fail=0; \
	n=$$(cat $(SRC)/body.tex $(SRC)/abstract.tex | grep -c "—" || true); \
	if [ "$$n" != "0" ]; then echo "FAIL: $$n unicode em-dash(es)"; fail=1; fi; \
	n=$$(cat $(SRC)/body.tex $(SRC)/abstract.tex | grep -o -- "---" | wc -l | tr -d ' '); \
	if [ "$$n" != "0" ]; then echo "FAIL: $$n LaTeX em-dash(es) (---)"; \
		grep -n -- "---" $(SRC)/body.tex $(SRC)/abstract.tex; fail=1; fi; \
	if [ $$fail -eq 0 ]; then echo "OK: no em-dashes"; else exit 1; fi

## anon — TMLR rejects non-anonymous submissions without review.
anon:
	@if ! command -v pdftotext >/dev/null 2>&1; then \
		echo "SKIP: pdftotext not installed (brew install poppler)"; exit 0; fi; \
	hits=$$(pdftotext $(TMLR)/paper.pdf - 2>/dev/null | \
		grep -icE "harshuljain|tanmay|tanya sah|parv|khatri|dolly|@gmail|AdmissionControlPolicies|AdmitPerf" || true); \
	if [ "$$hits" != "0" ]; then \
		echo "FAIL: $$hits identifying string(s) in tmlr/paper.pdf:"; \
		pdftotext $(TMLR)/paper.pdf - 2>/dev/null | \
		  grep -inE "harshuljain|tanmay|tanya sah|parv|khatri|dolly|@gmail|AdmissionControlPolicies|AdmitPerf"; \
		exit 1; \
	else echo "OK: anonymous (no identifying strings)"; fi
	@# The running header is the classic leak: a \shortauthors that the class
	@# forgets to suppress puts the author line on every page. Checked
	@# separately because a bare surname collides with cited works (we cite
	@# Jain's fairness index, by a different Jain).
	@if command -v pdftotext >/dev/null 2>&1; then \
		hd=$$(for pg in 3 5 7; do pdftotext -f $$pg -l $$pg $(TMLR)/paper.pdf - 2>/dev/null | head -2; done | \
		      grep -icE "jain|sah|khatri|dolly" || true); \
		if [ "$$hd" != "0" ]; then echo "FAIL: author name in a running header"; exit 1; \
		else echo "OK: running headers carry no author name"; fi; fi

## clean — remove build output, keep sources
clean:
	rm -f $(SRC)/*.aux $(SRC)/*.bbl $(SRC)/*.blg $(SRC)/*.log $(SRC)/*.out
	rm -f $(TMLR)/paper.pdf $(TMLR)/camera.pdf $(TMLR)/camera.tex \
	      $(TMLR)/paper-preprint.pdf $(TMLR)/*.aux $(TMLR)/*.bbl \
	      $(TMLR)/*.blg $(TMLR)/*.log $(TMLR)/*.out
	rm -f $(ARXIV)/paper.pdf $(ARXIV)/upload.tar.gz $(ARXIV)/*.aux \
	      $(ARXIV)/*.bbl $(ARXIV)/*.blg $(ARXIV)/*.log $(ARXIV)/*.out
	rm -f $(CSUR)/paper.pdf $(CSUR)/named.pdf $(CSUR)/named.tex $(CSUR)/cover-letter.pdf \
	      $(CSUR)/camera.pdf $(CSUR)/camera.tex $(CSUR)/*.aux $(CSUR)/*.bbl $(CSUR)/*.blg \
	      $(CSUR)/*.log $(CSUR)/*.out
