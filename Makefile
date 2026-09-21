# source_paper/body.tex is the only source for content.
# source_paper/venues/<venue>/paper.tex is a thin, venue-specific wrapper.
#
# Three builds, one source. The tmlr package hides the author block unless
# [accepted] or [preprint] is passed, so the anonymous submission and the
# de-anonymised preprint cannot drift apart.
#
#   make pdf        anonymous, for TMLR      -> venues/tmlr/paper.pdf
#   make preprint   de-anonymised, for arXiv -> venues/tmlr/paper-preprint.pdf
#   make camera     camera-ready             -> venues/tmlr/paper-camera.pdf
#
# VENUE=<name> selects the wrapper; tmlr is the default.
#   make check      build + gate on refs, style, anonymity
#   make dist       assemble submission/<venue>/ bundles
#
# Build with tectonic: no TeX Live install, fetches packages on demand.
# `brew install tectonic` if missing.

TECTONIC ?= tectonic
SRC      := source_paper
VENUE    ?= tmlr
V        := $(SRC)/venues/$(VENUE)
PAPER    := paper

.PHONY: all pdf preprint camera check style anon dist clean

all: pdf

## pdf — anonymous build, for TMLR
pdf:
	$(TECTONIC) -X compile $(V)/$(PAPER).tex --keep-logs

## preprint — de-anonymised build, for arXiv
preprint:
	@sed 's|^\\usepackage{tmlr}$$|\\usepackage[preprint]{tmlr}|' \
	    $(V)/$(PAPER).tex > $(V)/$(PAPER)-preprint.tex
	$(TECTONIC) -X compile $(V)/$(PAPER)-preprint.tex
	@rm -f $(V)/$(PAPER)-preprint.tex
	@echo "OK: $(V)/$(PAPER)-preprint.pdf (author names visible)"

## camera — camera-ready build, post-acceptance
camera:
	@sed 's|^\\usepackage{tmlr}$$|\\usepackage[accepted]{tmlr}|' \
	    $(V)/$(PAPER).tex > $(V)/$(PAPER)-camera.tex
	$(TECTONIC) -X compile $(V)/$(PAPER)-camera.tex
	@rm -f $(V)/$(PAPER)-camera.tex
	@echo "OK: $(V)/$(PAPER)-camera.pdf"

## check — build, then gate on references, style, and anonymity
check: pdf style anon
	@if grep -qiE 'undefined (reference|citation)' $(V)/$(PAPER).log; then \
		echo "FAIL: unresolved references or citations:"; \
		grep -iE 'undefined (reference|citation)' $(V)/$(PAPER).log; \
		exit 1; \
	else \
		echo "OK: every ref and cite resolves"; \
	fi

## style — author convention: no em-dashes in source or output
style:
	@fail=0; \
	n=$$(grep -c "—" $(SRC)/body.tex $(SRC)/abstract.tex | awk -F: '{t+=$$2} END{print t+0}'); \
	if [ "$$n" != "0" ]; then echo "FAIL: $$n unicode em-dash(es)"; fail=1; fi; \
	n=$$(grep -o -- "---" $(SRC)/body.tex $(SRC)/abstract.tex | wc -l | tr -d ' '); \
	if [ "$$n" != "0" ]; then echo "FAIL: $$n LaTeX em-dash(es) (---)"; \
		grep -n -- "---" $(SRC)/body.tex $(SRC)/abstract.tex; fail=1; fi; \
	if [ $$fail -eq 0 ]; then echo "OK: no em-dashes"; else exit 1; fi

## anon — TMLR rejects non-anonymous submissions without review.
## Greps the rendered PDF for the authors' own identifying strings.
## Third-party repository URLs from cited papers are expected and allowed.
anon:
	@if ! command -v pdftotext >/dev/null 2>&1; then \
		echo "SKIP: pdftotext not installed (brew install poppler)"; exit 0; fi; \
	hits=$$(pdftotext $(V)/$(PAPER).pdf - 2>/dev/null | \
		grep -icE "harshuljain|tanmay|tanya sah|parv|khatri|@gmail|AdmissionControlPolicies|AdmitPerf" || true); \
	if [ "$$hits" != "0" ]; then \
		echo "FAIL: $$hits identifying string(s) in $(PAPER).pdf:"; \
		pdftotext $(V)/$(PAPER).pdf - 2>/dev/null | \
		  grep -inE "harshuljain|tanmay|tanya sah|parv|khatri|@gmail|AdmissionControlPolicies|AdmitPerf"; \
		exit 1; \
	else echo "OK: anonymous (no identifying strings)"; fi

## dist — assemble one bundle per venue under submission/
##   submission/tmlr/   anonymous PDF, for OpenReview
##   submission/arxiv/  LaTeX source + .bbl, for arXiv
dist: check preprint
	@rm -rf submission && mkdir -p submission/tmlr submission/arxiv
	@# TMLR: OpenReview takes a PDF, never source.
	@cp $(V)/$(PAPER).pdf submission/tmlr/
	@cp docs/submission/tmlr.md submission/tmlr/SUBMIT.md
	@# arXiv: wants source. It runs LaTeX but NOT bibtex, so the .bbl must ship.
	@# arXiv gets a FLAT bundle, so rewrite the ../../ input paths.
	@sed -e 's|^\\usepackage{tmlr}$$|\\usepackage[preprint]{tmlr}|' \
	     -e 's|{\.\./\.\./|{|g' \
	    $(V)/$(PAPER).tex > submission/arxiv/main.tex
	@cp $(SRC)/preamble.tex $(SRC)/abstract.tex $(SRC)/body.tex submission/arxiv/
	@$(TECTONIC) -X compile $(V)/$(PAPER).tex --keep-intermediates --keep-logs >/dev/null 2>&1 || true
	@cp $(V)/$(PAPER).bbl submission/arxiv/main.bbl
	@cp $(SRC)/references.bib $(V)/tmlr.sty $(V)/tmlr.bst $(V)/fancyhdr.sty submission/arxiv/
	@cp $(V)/$(PAPER)-preprint.pdf submission/arxiv/reference-render.pdf
	@cp docs/submission/arxiv.md submission/arxiv/SUBMIT.md
	@echo
	@echo "submission/tmlr/   -> upload paper.pdf to OpenReview"
	@echo "submission/arxiv/  -> tar the source files (not reference-render.pdf) and upload"
	@ls -1 submission/tmlr submission/arxiv

## clean — remove build artefacts and generated bundles
clean:
	rm -f $(V)/$(PAPER).log $(V)/$(PAPER).blg $(V)/$(PAPER).aux \
	      $(V)/$(PAPER).bbl $(V)/$(PAPER).out \
	      $(V)/$(PAPER)-preprint.tex $(V)/$(PAPER)-camera.tex
	rm -rf submission
