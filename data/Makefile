ALLDIRs := $(wildcard *-par/*.dir)
BACKUPs := $(wildcard *-par/*\#*.dir)

# Don't merge dirs created by DrWatson.savesafe:
DIRs = $(filter-out $(BACKUPs), $(ALLDIRs))
H5s = $(DIRs:.dir=.h5)

.PHONY: merge_all
merge_all: $(H5s)

%.h5: %.dir
	julia --project=@. -e 'using Stuff; mergedata(datadir("$<"), datadir("$@"))'

# This makefile is severely broken: it is not possible to merge individual dirs.
# Specifying them as a goal via e.g. `make dense-par/rail...h5` would include `=`,
# which causes `make` to parse the argument as a variable instead of a goal.
# TODO: Investigate how to use `:` instead of `=` for `DrWatson.savename`.
# Would this break parsing Julia ranges?
