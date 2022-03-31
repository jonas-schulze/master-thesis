using Stuff

kind = Symbol(get(ENV, "MY_KIND", "dense"))
conf = SequentialConfig(kind)
@info "Read configuration $(savename(conf))"

@info "Loading data"
p = load_rail(conf)
a = algorithms(conf)

@info "Launching solver"
runtime = @elapsed begin
    sol = solve(
        p, a;
        dt=Δt(p, conf.nsteps),
        save_state=true,
    )
end

@info "Saving Results"
outfile = datadir("$kind-seq", savename(conf, "h5"))
safesave(outfile, sol)
h5open(outfile, "r+") do h5
    h5["runtime"] = runtime
end
