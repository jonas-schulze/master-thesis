ALLDIRs := $(wildcard *-par/*.dir)
BACKUPs := $(wildcard *-par/*\#*.dir)

# Don't merge dirs created by DrWatson.savesafe:
DIRs = $(filter-out $(BACKUPs), $(ALLDIRs))
H5s = $(DIRs:.dir=.h5)

.PHONY: merge_all
merge_all: $(H5s)

%.h5: %.dir
	julia --project=@. -e 'using Stuff; mergedata(datadir("$<"), datadir("$@"))'
