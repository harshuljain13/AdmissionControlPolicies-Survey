# paper.tex is the single source of truth. There is no paper.md.
#
# Build with tectonic: no TeX Live install, fetches packages on demand,
# reproducible across machines. `brew install tectonic` if missing.

TECTONIC ?= tectonic
PAPER    := paper

.PHONY: all pdf check style clean

all: pdf

## pdf — build paper.pdf from paper.tex
pdf:
	$(TECTONIC) -X compile $(PAPER).tex --keep-logs

## check — build, then fail loudly on unresolved refs or citations
check: pdf style
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

## style — author conventions: no em-dashes in source or output
style:
	@fail=0; \
	n=$$(grep -c "—" $(PAPER).tex || true); \
	if [ "$$n" != "0" ]; then echo "FAIL: $$n unicode em-dash(es)"; fail=1; fi; \
	n=$$(grep -o -- "---" $(PAPER).tex | wc -l | tr -d ' '); \
	if [ "$$n" != "0" ]; then echo "FAIL: $$n LaTeX em-dash(es) (---)"; \
		grep -n -- "---" $(PAPER).tex; fail=1; fi; \
	if [ $$fail -eq 0 ]; then echo "OK: no em-dashes"; else exit 1; fi
