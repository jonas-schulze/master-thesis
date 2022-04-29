using Stuff
using ParaReal: TimingFileObserver

kind = Symbol(ENV["MY_KIND"])
conf = ParallelConfig(kind)
save_X = something(readenv("MY_X"), false)
roundrobin = something(readenv("MY_ROUNDROBIN"), 1)
@info "Read configuration $(savename(conf))" save_X roundrobin
algc, algf = algorithms(conf)

include(scriptsdir("add_workers.jl"))

@info "Loading data"
rail = load_rail(conf)
p = ParaReal.Problem(rail)
a = ParaReal.Algorithm(csolve, fsolve)

# Setup logging
outdir = datadir("$kind-par", savename(conf, "dir"))
logdir = datadir("logfiles", savename(conf))
logger = TimingFileObserver(LoggingFormats.LogFmt(), Base.time, logdir)

@info "Launching solver"
ws = repeat(workers(), outer=roundrobin)
runtime = @elapsed begin
    sol = solve(
        p, a;
        schedule=ProcessesSchedule(ws),
        logger=logger,
        warmupc=conf.wc,
        warmupf=conf.wf,
    )
end

include(scriptsdir("save_results.jl"))
