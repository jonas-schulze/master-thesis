BUILDDIR = output
DIRS = $(BUILDDIR) $(BUILDDIR)/content
DEPS = Makefile *.bib *.tex content/*.tex

$(BUILDDIR)/thesis.pdf: $(DEPS) | $(DIRS)
	pdflatex -output-directory $(BUILDDIR) thesis
	biber --output-directory $(BUILDDIR) thesis
	makeglossaries -d $(BUILDDIR) thesis
	pdflatex -output-directory $(BUILDDIR) thesis
	pdflatex -output-directory $(BUILDDIR) thesis

$(DIRS):
	mkdir -p $@

.PHONY: update
update: | $(DIRS)
	pdflatex -output-directory $(BUILDDIR) thesis

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)
