# paper.tex is the single source of truth. There is no paper.md.
#
# Three build modes, one source. The tmlr package hides the author block
# unless [accepted] or [preprint] is passed, so the anonymous submission
# and the de-anonymised preprint come from the same file.
#
#   make pdf        anonymous, for TMLR submission      -> paper.pdf
#   make preprint   de-anonymised, for arXiv            -> paper-preprint.pdf
#   make camera     camera-ready (post-acceptance)      -> paper-camera.pdf
#
# Build with tectonic: no TeX Live install, fetches packages on demand.
# `brew install tectonic` if missing.

TECTONIC ?= tectonic
PAPER    := paper

.PHONY: all pdf preprint camera check style anon dist clean

all: pdf

## pdf — anonymous build for TMLR submission
pdf:
	$(TECTONIC) -X compile $(PAPER).tex --keep-logs

## preprint — de-anonymised build for arXiv
preprint:
	@sed 's|^\\usepackage{tmlr}$$|\\usepackage[preprint]{tmlr}|' $(PAPER).tex > $(PAPER)-preprint.tex
	$(TECTONIC) -X compile $(PAPER)-preprint.tex
	@rm -f $(PAPER)-preprint.tex
	@echo "OK: $(PAPER)-preprint.pdf (author names visible)"

## camera — camera-ready build, post-acceptance
camera:
	@sed 's|^\\usepackage{tmlr}$$|\\usepackage[accepted]{tmlr}|' $(PAPER).tex > $(PAPER)-camera.tex
	$(TECTONIC) -X compile $(PAPER)-camera.tex
	@rm -f $(PAPER)-camera.tex
	@echo "OK: $(PAPER)-camera.pdf"

## check — build, then gate on refs, style, and anonymity
check: pdf style anon
	@if grep -qiE 'undefined (reference|citation)' $(PAPER).log; then \
		echo "FAIL: unresolved references or citations:"; \
		grep -iE 'undefined (reference|citation)' $(PAPER).log; \
		exit 1; \
	else \
		echo "OK: every \\ref and \\cite resolves"; \
	fi

## style — author conventions: no em-dashes in source or output
style:
	@fail=0; \
	n=$$(grep -c "—" $(PAPER).tex || true); \
	if [ "$$n" != "0" ]; then echo "FAIL: $$n unicode em-dash(es)"; fail=1; fi; \
	n=$$(grep -o -- "---" $(PAPER).tex | wc -l | tr -d ' '); \
	if [ "$$n" != "0" ]; then echo "FAIL: $$n LaTeX em-dash(es) (---)"; \
		grep -n -- "---" $(PAPER).tex; fail=1; fi; \
	if [ $$fail -eq 0 ]; then echo "OK: no em-dashes"; else exit 1; fi

## anon — TMLR rejects non-anonymous submissions without review.
## Greps the rendered PDF for the authors' own identifying strings.
## Third-party repository URLs from cited papers are expected and allowed.
anon:
	@if ! command -v pdftotext >/dev/null 2>&1; then \
		echo "SKIP: pdftotext not installed (brew install poppler)"; exit 0; fi; \
	hits=$$(pdftotext $(PAPER).pdf - 2>/dev/null | \
		grep -icE "harshuljain|tanmay|tanya sah|parv|khatri|audible|@gmail|AdmissionControlPolicies|AdmitPerf" || true); \
	if [ "$$hits" != "0" ]; then \
		echo "FAIL: $$hits identifying string(s) in paper.pdf:"; \
		pdftotext $(PAPER).pdf - 2>/dev/null | \
		  grep -inE "harshuljain|tanmay|tanya sah|parv|khatri|audible|@gmail|AdmissionControlPolicies|AdmitPerf"; \
		exit 1; \
	else echo "OK: anonymous (no identifying strings)"; fi

## dist — build both submission bundles into dist/
##   dist/tmlr-submission/  anonymous PDF, for OpenReview
##   dist/arxiv-preprint/   LaTeX source + .bbl, for arXiv
dist: check preprint
	@rm -rf dist && mkdir -p dist/tmlr-submission dist/arxiv-preprint
	@# --- TMLR: OpenReview takes a PDF only ---
	@cp $(PAPER).pdf dist/tmlr-submission/
	@# --- arXiv: wants LaTeX source; it does NOT run bibtex, so ship the .bbl ---
	@sed 's|^\\usepackage{tmlr}$$|\\usepackage[preprint]{tmlr}|' $(PAPER).tex > dist/arxiv-preprint/main.tex
	@$(TECTONIC) -X compile $(PAPER).tex --keep-intermediates --keep-logs >/dev/null 2>&1 || true
	@cp $(PAPER).bbl dist/arxiv-preprint/main.bbl
	@cp references.bib tmlr.sty tmlr.bst fancyhdr.sty math_commands.tex dist/arxiv-preprint/
	@cp $(PAPER)-preprint.pdf dist/arxiv-preprint/reference-render.pdf
	@cp dist-readme-tmlr.md   dist/tmlr-submission/SUBMIT.md
	@cp dist-readme-arxiv.md  dist/arxiv-preprint/SUBMIT.md
	@echo
	@echo "dist/tmlr-submission/  -> upload paper.pdf to OpenReview"
	@echo "dist/arxiv-preprint/   -> tar up the source files and upload to arXiv"
	@ls -1 dist/tmlr-submission dist/arxiv-preprint

## clean — remove build artefacts, keep the pdfs
clean:
	rm -f $(PAPER).log $(PAPER).blg $(PAPER).aux $(PAPER).bbl $(PAPER).out \
	      $(PAPER)-preprint.tex $(PAPER)-camera.tex
	rm -rf dist
