@assert @isdefined(outdir)
@assert @isdefined(sol)
@assert @isdefined(runtime)

@info "Storing solution at $outdir"
safesave(outdir, sol)
metadata = Dict{String,Any}()
@pack! metadata = runtime
@tag! metadata
storemeta(outdir, metadata)
