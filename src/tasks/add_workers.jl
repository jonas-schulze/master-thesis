@assert @isdefined(conf)
@assert @isdefined(algc)
@assert @isdefined(algf)

nc = conf.nc
nf = conf.nf

addworkers(conf)
@everywhere using Stuff
@everywhere begin
    set_num_threads()
    csolve(prob::GDREProblem) = solve(prob, $algc; dt=Δt(prob, $nc))
    fsolve(prob::GDREProblem) = solve(prob, $algf; dt=Δt(prob, $nf))
end

log_worker_info()
