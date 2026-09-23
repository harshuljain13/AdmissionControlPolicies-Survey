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

.PHONY: all tmlr arxiv csur csur-named camera check style anon clean

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
	   grep -icE "harshuljain|tanmay|tanya sah|parv|khatri|@gmail|AdmissionControlPolicies|AdmitPerf" || true); \
	 if [ "$$hits" != "0" ]; then echo "FAIL: $$hits identifying string(s)"; exit 1; \
	 else echo "OK: $(CSUR)/paper.pdf anonymous"; fi

## csur-named — same, with author names visible.
## Use only if ScholarOne confirms CSUR is single-blind; see csur/SUBMIT.md.
csur-named:
	@sed 's|\[acmsmall,review,anonymous\]|[acmsmall,review]|' \
	    $(CSUR)/paper.tex > $(CSUR)/named.tex
	$(TECTONIC) -X compile $(CSUR)/named.tex
	@rm -f $(CSUR)/named.tex
	@echo "OK: $(CSUR)/named.pdf (author names visible)"

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

## camera — camera-ready, post-acceptance
camera:
	@sed 's|^\\usepackage{tmlr}$$|\\usepackage[accepted]{tmlr}|' \
	    $(TMLR)/paper.tex > $(TMLR)/camera.tex
	$(TECTONIC) -X compile $(TMLR)/camera.tex
	@rm -f $(TMLR)/camera.tex
	@echo "OK: $(TMLR)/camera.pdf"

## check — build the TMLR PDF, then gate it
check: tmlr style anon
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
		grep -icE "harshuljain|tanmay|tanya sah|parv|khatri|@gmail|AdmissionControlPolicies|AdmitPerf" || true); \
	if [ "$$hits" != "0" ]; then \
		echo "FAIL: $$hits identifying string(s) in tmlr/paper.pdf:"; \
		pdftotext $(TMLR)/paper.pdf - 2>/dev/null | \
		  grep -inE "harshuljain|tanmay|tanya sah|parv|khatri|@gmail|AdmissionControlPolicies|AdmitPerf"; \
		exit 1; \
	else echo "OK: anonymous (no identifying strings)"; fi

## clean — remove build output, keep sources
clean:
	rm -f $(SRC)/*.aux $(SRC)/*.bbl $(SRC)/*.blg $(SRC)/*.log $(SRC)/*.out
	rm -f $(TMLR)/paper.pdf $(TMLR)/camera.pdf $(TMLR)/camera.tex \
	      $(TMLR)/paper-preprint.pdf $(TMLR)/*.aux $(TMLR)/*.bbl \
	      $(TMLR)/*.blg $(TMLR)/*.log $(TMLR)/*.out
	rm -f $(ARXIV)/paper.pdf $(ARXIV)/upload.tar.gz $(ARXIV)/*.aux \
	      $(ARXIV)/*.bbl $(ARXIV)/*.blg $(ARXIV)/*.log $(ARXIV)/*.out
	rm -f $(CSUR)/paper.pdf $(CSUR)/named.pdf $(CSUR)/named.tex $(CSUR)/*.aux $(CSUR)/*.bbl $(CSUR)/*.blg \
	      $(CSUR)/*.log $(CSUR)/*.out
