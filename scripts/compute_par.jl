@assert @isdefined(kind)

using Stuff
using ParaReal: TimingFileObserver

conf = ParallelConfig(kind)
@info "Read configuration $(savename(conf))"
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
runtime = @elapsed begin
    sol = solve(
        p, a;
        logger=logger,
        warmupc=conf.wc,
        warmupf=conf.wf,
    )
end

include(scriptsdir("save_results.jl"))
