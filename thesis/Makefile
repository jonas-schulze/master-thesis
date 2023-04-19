BUILDDIR = output
DIRS = tables $(BUILDDIR) $(BUILDDIR)/content $(BUILDDIR)/appendix
DEPS = Makefile *.bib *.tex */*.tex githash.txt
TABLES_CSV = $(wildcard tables/*.csv)
TABLES_TEX = $(TABLES_CSV:.csv=.tex)
DEPS += $(TABLES_TEX)
CODE_JL = $(wildcard code/standalone_*.jl)
CODE_TXT = $(addsuffix .txt, $(CODE_JL))
FIGS = figures/Steelprofile1.jpg
SLIDE_DEPS = $(CODE_TXT) $(FIGS)

.PHONY: update-slides
update-slides: $(SLIDE_DEPS) | $(DIRS)
	lualatex -output-directory $(BUILDDIR) slides

.PHONY: update
update: githash.txt $(TABLES_TEX) | $(DIRS)
	pdflatex -output-directory $(BUILDDIR) thesis

.PHONY: all
all: $(BUILDDIR)/thesis.pdf $(BUILDDIR)/slides.pdf

$(BUILDDIR)/thesis.pdf: $(DEPS) | $(DIRS)
	pdflatex -output-directory $(BUILDDIR) thesis
	biber --output-directory $(BUILDDIR) thesis
	pdflatex -output-directory $(BUILDDIR) thesis
	makeglossaries -d $(BUILDDIR) thesis
	pdflatex -output-directory $(BUILDDIR) thesis
	pdflatex -output-directory $(BUILDDIR) thesis

.PHONY: $(BUILDDIR)/slides.pdf
$(BUILDDIR)/slides.pdf: $(SLIDE_DEPS) | $(DIRS)
	pdflatex -output-directory $(BUILDDIR) slides
	biber --output-directory $(BUILDDIR) slides
	pdflatex -output-directory $(BUILDDIR) slides
	pdflatex -output-directory $(BUILDDIR) slides

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

code/%.jl.txt: code/%.jl
	sed -e 's/₀/%\\textsubscript{0}%/g' -e 's/ᵀ/%\\textsuperscript{T}%/g' $< > $@

figures/Steelprofile1.jpg:
	curl https://morwiki.mpi-magdeburg.mpg.de/morwiki/images/8/82/Steelprofile1.jpg > $@
