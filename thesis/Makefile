BUILDDIR = output
DIRS = tables $(BUILDDIR) $(BUILDDIR)/content $(BUILDDIR)/appendix
DEPS = Makefile *.bib *.tex */*.tex
DEPS += tables/warmup4.tex tables/warmup8.tex

.PHONY: update
update: | $(DIRS)
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
