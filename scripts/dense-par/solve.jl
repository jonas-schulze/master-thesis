using Stuff

function _alg(order)
    order == 1 && return Ros1()
    order == 2 && return Ros2()
    order == 3 && return Ros3()
    order == 4 && return Ros4()
    error("unknown order: ", order)
end

# Read and validate configuration
!@isdefined(nc) && (nc = something(readenv("MY_NC"), 1))
!@isdefined(oc) && (oc = something(readenv("MY_OC"), 1))
!@isdefined(nf) && (nf = something(readenv("MY_NF"), 1))
!@isdefined(of) && (of = something(readenv("MY_OF"), 1))
!@isdefined(wc) && (wc = something(readenv("MY_WC"), true))
!@isdefined(wf) && (wf = something(readenv("MY_WF"), false))
nstages = something(
    nprocs() > 1 ? nworkers() : nothing,
    readenv("SLURM_NTASKS"),
    Sys.CPU_THREADS,
)
algc = _alg(oc)
algf = _alg(of)
config = (; nstages, nc, nf, oc, of, wc, wf)
@info "Configuration valid" config

# Launch workers
addworkers()
@everywhere using Stuff # exports GDREProblem a.o.
@everywhere set_num_threads()
log_worker_info()

@everywhere begin
    function _dt(prob, nsteps)
        t0, tf = prob.tspan
        (tf - t0) / nsteps
    end

    csolve(prob::GDREProblem) = solve(prob, $algc; dt=_dt(prob, $nc))
    fsolve(prob::GDREProblem) = solve(prob, $algf; dt=_dt(prob, $nf))
end

@info "Loading data"
using MAT
P = matread(datadir("Rail371.mat"))
@unpack E, A, B, C, X0 = P
Ed = collect(E) # d=dense
tspan = (4500., 0.) # backwards in time
prob = ParaReal.problem(GDREProblem(Ed, A, B, C, X0, tspan))
alg = ParaReal.algorithm(csolve, fsolve)

@info "Launching solver"
runtime = @elapsed(sol = solve(prob, alg; warmupc=wc, warmupf=wf))
@info "Solve took $runtime seconds"

dir = datadir("dense-par", savename("rail371", config, "dir"))
@info "Storing solution at $dir"
safesave(dir, sol)
metadata = Dict{String,Any}()
@pack! metadata = runtime
@tag! metadata
storemeta(dir, metadata)
