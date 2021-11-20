### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 3dfd9d2e-89fc-4cba-9942-f7cf2142be2b
using DrWatson

# ╔═╡ fe6218a8-d31f-47ba-948c-819ea42d379f
@quickactivate

# ╔═╡ 8f401775-95cd-4d7e-9318-5f3908edf37e
using DataFrames, CairoMakie, PlutoUI, UnPack

# ╔═╡ 2e393b06-46f5-11ec-3258-8371b50807e7
md"# Parareal Timeline"

# ╔═╡ 09b6dd8a-15a6-4ad0-8582-e859a4e693bf
let
	global dataset
	dirs = readdir(datadir("dense-par"))
	@bind dataset Select(dirs; default=first(dirs))
end

# ╔═╡ 961530f7-61e7-410c-b7b4-7dbdacb6088e
@bind nevent Select(1:10, default=1)

# ╔═╡ d95a40fd-7d48-420c-b49e-e40e721639a6
md"""
The above plot shows the time a worker process (stage) started, each time it received a new initial value to compute a single iteration with, and when it finished.
"""

# ╔═╡ 390b6d88-bf4a-41e8-ad9d-d44c14abb681
md"## Waiting times"

# ╔═╡ 536adf23-691d-49be-8656-8340f3089582
md"""
## Flat leading slope

The discussion below applies only to cases without JIT warm-up,
i.e. `wc == wf == false`.

Note the flat temporal slope of the first "Running" dots,
which is caused by the (JIT) compilation time of each individual process.
Overall, the time it takes to compute the first "global" coarse solution,
i.e. the time from starting the stages until the last stage finished computing its "local" coarse solution, equals

```math
n_\text{stages} \cdot t_{\text{jit}, c} +
n_\text{stages} \cdot t_{\text{solve}, c} +
n_\text{stages} \cdot t_\text{transmit}.
```

Note that the initial value has to be sent from the managing process to the first stage.
Options to remedy this:

1. Warm up all the stages by computing a "dummy" solution.
2. Let the first stage compute all the coarse solutions one after the other.

Option 1 would reduce the time to

```math
1 \cdot t_{\text{jit}, c} +
n_\text{stages} \cdot t_{\text{solve}, c} +
n_\text{stages} \cdot t_\text{transmit}
```

by "hiding" the compilation time in the unused span between Start and the first Running event.
Also, it has some similarities to multiple shooting,
which would actually make use of that first "dummy" solution.
Maybe multiple shooting is a better contender for JIT-heavy environments.
Furthermore, it might be beneficial to warm up both the coarse and the fine solver,
as otherwise the second iterations might show a similar flat slope.

Option 2, however, would reduce the time to

```math
2 \cdot t_{\text{jit}, c} +
n_\text{stages} \cdot t_{\text{solve}, c} +
2 \cdot t_\text{transmit}
```

if all the transfers are done concurrently.
The second compilation time is due to all stages needing to "warm up" their coarse solvers in order to be at the same final state.
However, this "warm up" is technically part of the second iteration of the parareal algorithm,
i.e. already computing a necessary part of the solution.

Overall, option 1 is easier to implement.
"""

# ╔═╡ 1aed787b-9793-428e-95b3-e7c8b2695f05
md"""
## Steep intermediate slopes

Note the steeper slope starting at iteration 3 of the final stage.
At this point, all solvers are warmed up.
Apparently, due to a too-small buffer size of the `RemoteChannel`s between the stages,
or due to the fact that the transfers are not done concurrently at the moment,
previous stages have to wait for their successors to receive their next "local" initial value.
This situation clogs the whole pipeline and only clears up after the last stage is fully warmed up.

Fixing this should also have an impact on the temporal slope of the first iterations.
"""

# ╔═╡ 88630af8-3193-4487-871d-cce8e93985d4
md"## Internal Stuff"

# ╔═╡ b2df1ca8-ff2d-4f63-a484-a59b84dbcd82
model, config, _ = parse_savename(dataset);

# ╔═╡ 4cabaffe-99fa-4d7e-b8e9-34afb0830fa3
desc = savename(config, connector=", ");

# ╔═╡ 9c21b470-ae46-42d2-a192-d7e3691dd7a8
logfile = datadir("dense-par", dataset, "EVENTLOG.h5")

# ╔═╡ 3783109b-7db2-4b1a-8fcc-459b22791fe2
begin
	df = DataFrame(load(logfile))
	df[!, :time_sent] .-= df[1, :time_sent]
	df
end

# ╔═╡ 74a288c3-f5c2-4e41-aef0-6d44c8d3628b
@bind nstage Select(1:maximum(df.stage), default=1)

# ╔═╡ 0fc4017b-318a-43ce-89cd-b33ee53e0286
combine(groupby(df, :stage)) do g
	wid = findall(==("Waiting"), g.status)
	rid = wid .+ 1
	@assert all(in(("Running", "DoneWaiting")), g.status[rid])
	wtime = g.time_sent[wid]
	rtime = g.time_sent[rid]
	Ref(rtime - wtime)
end

# ╔═╡ 42b6371c-c1a9-45c2-8a27-98a47d8d0c32
states = unique(df.status)

# ╔═╡ 2f487c91-3b22-4941-a309-eafc3ce295f1
@bind event Select(states, default="Running" in states ? "Running" : "DoneWaiting")

# ╔═╡ 5b208c16-5a6a-4067-a0e4-b68c6aa1aade
md"""
## Linear Approximation of "$event"s

Find the best ``t \mapsto \alpha + \beta \cdot t \approx \text{stage}``:
"""

# ╔═╡ b838b465-42cd-41fa-9751-c8b0cd93f345
let
	global slope
	events = filter(:status => ==(event), df)
	filter!(:stage => >=(nstage), events)
	slope = combine(
		groupby(events, :stage),
		:time_sent => (t -> get(t, nevent, missing)) => :time,
	)
	dropmissing!(slope)
	slope
end

# ╔═╡ 18aeb876-5106-4ef2-a091-8e3c3c2c0836
let
	global α, β
	x = slope.time
	y = slope.stage
	A = [ones(length(x)) x]
	α, β = A \ y
end

# ╔═╡ ba95bb72-57d7-41a5-94e4-2ba6d2c9fd3d
md"""
The `nevent`-th occurences of `event` starting from stage `nstage` evolve at
~$(round(1/β, digits=3)) seconds per stage.
"""

# ╔═╡ edfbd427-6d01-45f6-ae10-d309fe2723a7
let
	@unpack nc, nf, oc, of = config
	wc = get(config, "wc", false)
	wf = get(config, "wf", false)
	tconf = @strdict wc wf nc nf oc of
	tdesc = savename(tconf, connector=", ")

	f = Figure()
	ax = Axis(
		f[1, 1],
		title = """
		Timeline ($model, $tdesc)
		$(round(1/β, digits=3)) seconds per stage
		""",
		ylabel = "stage",
		xticks = 0:60:maximum(df.time_sent),
		xtickformat = xs -> ["$(round(Int, x÷60))min" for x in xs],
	)
	hideydecorations!(ax, ticklabels=false, label=false)

	names = Dict(
		"DoneWaiting" => "Running",
	)

	for s in ["Started", "Running", "DoneWaiting", "Done"]
		s in states || continue
		selection = df.status .== s
		scatter!(
			df[selection, :time_sent],
			df[selection, :stage];
			label=get(names, s, s),
		)
	end

	abline!(ax, α, β)

	Legend(f[1, 2], ax)

	f
end

# ╔═╡ Cell order:
# ╟─2e393b06-46f5-11ec-3258-8371b50807e7
# ╠═09b6dd8a-15a6-4ad0-8582-e859a4e693bf
# ╟─ba95bb72-57d7-41a5-94e4-2ba6d2c9fd3d
# ╠═2f487c91-3b22-4941-a309-eafc3ce295f1
# ╠═961530f7-61e7-410c-b7b4-7dbdacb6088e
# ╠═74a288c3-f5c2-4e41-aef0-6d44c8d3628b
# ╟─edfbd427-6d01-45f6-ae10-d309fe2723a7
# ╟─d95a40fd-7d48-420c-b49e-e40e721639a6
# ╟─5b208c16-5a6a-4067-a0e4-b68c6aa1aade
# ╠═b838b465-42cd-41fa-9751-c8b0cd93f345
# ╠═18aeb876-5106-4ef2-a091-8e3c3c2c0836
# ╟─390b6d88-bf4a-41e8-ad9d-d44c14abb681
# ╠═0fc4017b-318a-43ce-89cd-b33ee53e0286
# ╟─536adf23-691d-49be-8656-8340f3089582
# ╟─1aed787b-9793-428e-95b3-e7c8b2695f05
# ╟─88630af8-3193-4487-871d-cce8e93985d4
# ╠═b2df1ca8-ff2d-4f63-a484-a59b84dbcd82
# ╠═4cabaffe-99fa-4d7e-b8e9-34afb0830fa3
# ╠═42b6371c-c1a9-45c2-8a27-98a47d8d0c32
# ╠═9c21b470-ae46-42d2-a192-d7e3691dd7a8
# ╠═3783109b-7db2-4b1a-8fcc-459b22791fe2
# ╠═3dfd9d2e-89fc-4cba-9942-f7cf2142be2b
# ╠═fe6218a8-d31f-47ba-948c-819ea42d379f
# ╠═8f401775-95cd-4d7e-9318-5f3908edf37e
