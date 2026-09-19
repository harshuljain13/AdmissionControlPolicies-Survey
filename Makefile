# paper.tex is the single source of truth. There is no paper.md.
#
# Build with tectonic: no TeX Live install, fetches packages on demand,
# reproducible across machines. `brew install tectonic` if missing.

TECTONIC ?= tectonic
PAPER    := paper

.PHONY: all pdf check clean

all: pdf

## pdf — build paper.pdf from paper.tex
pdf:
	$(TECTONIC) -X compile $(PAPER).tex --keep-logs

## check — build, then fail loudly on unresolved refs or citations
check: pdf
	@if grep -qiE 'undefined (reference|citation)' $(PAPER).log; then \
		echo "FAIL: unresolved references or citations:"; \
		grep -iE 'undefined (reference|citation)' $(PAPER).log; \
		exit 1; \
	else \
		echo "OK: every \\ref and \\cite resolves"; \
	fi

## clean — remove build artefacts, keep the pdf
clean:
	rm -f $(PAPER).log $(PAPER).blg $(PAPER).aux $(PAPER).bbl $(PAPER).out
