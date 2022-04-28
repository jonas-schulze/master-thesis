using Stuff

kind = Symbol(get(ENV, "MY_KIND", "dense"))
conf = SequentialConfig(kind)
save_X = something(readenv("MY_X"), false)
@info "Read configuration $(savename(conf))" save_X

@info "Loading data"
p = load_rail(conf)
a = algorithms(conf)

@info "Launching solver"
runtime = @elapsed begin
    sol = solve(
        p, a;
        dt=Δt(p, conf.nsteps),
        save_state=save_X,
    )
end

@info "Saving Results"
outfile = datadir("$kind-seq", savename(conf, "h5"))
safesave(outfile, sol)
h5open(outfile, "r+") do h5
    h5["runtime"] = runtime
end
