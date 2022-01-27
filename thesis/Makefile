BUILDDIR = output
DIRS = $(BUILDDIR) $(BUILDDIR)/content $(BUILDDIR)/appendix
DEPS = Makefile *.bib *.tex content/*.tex

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
