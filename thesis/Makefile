BUILDDIR = output
DIRS = tables $(BUILDDIR) $(BUILDDIR)/content $(BUILDDIR)/appendix
DEPS = Makefile *.bib *.tex */*.tex githash.txt
TABLES_CSV = $(wildcard tables/*.csv)
TABLES_TEX = $(TABLES_CSV:.csv=.tex)
DEPS += $(TABLES_TEX)

.PHONY: update
update: githash.txt $(TABLES_TEX) | $(DIRS)
	pdflatex -output-directory $(BUILDDIR) thesis

.PHONY: all
all: $(BUILDDIR)/thesis.pdf

$(BUILDDIR)/thesis.pdf: $(DEPS) | $(DIRS)
	pdflatex -output-directory $(BUILDDIR) thesis
	biber --output-directory $(BUILDDIR) thesis
	makeglossaries -d $(BUILDDIR) thesis
	pdflatex -output-directory $(BUILDDIR) thesis
	pdflatex -output-directory $(BUILDDIR) thesis

$(DIRS):
	mkdir -p $@

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)

tables/%.tex: tables/%.csv
	sed -e 's/,/ \& /g' -e 's/$$/ \\\\/' < $< > $@

.PHONY: githash.txt
githash.txt:
	git rev-parse --short HEAD > $@
