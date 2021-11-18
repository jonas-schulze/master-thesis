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
using DrWatson, DataFrames, CairoMakie, PlutoUI

# ╔═╡ fe6218a8-d31f-47ba-948c-819ea42d379f
@quickactivate

# ╔═╡ 2e393b06-46f5-11ec-3258-8371b50807e7
md"""
# Parareal Timeline

Select the `dataset` for which to visualize the timeline:
"""

# ╔═╡ 0c54e190-8dab-4021-8b89-88299c2f07af
let
	global dataset
	dirs = readdir(datadir("dense-par"))
	@bind dataset Select(dirs; default=first(dirs))
end

# ╔═╡ d95a40fd-7d48-420c-b49e-e40e721639a6
md"""
The above plot shows the time a worker process (stage) started, each time it received a new initial value to compute a single iteration with, and when it finished.
"""

# ╔═╡ 536adf23-691d-49be-8656-8340f3089582
md"""
## Flat leading slope

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

# ╔═╡ edfbd427-6d01-45f6-ae10-d309fe2723a7
let
	f = Figure()
	ax = Axis(
		f[1, 1],
		title = "Timeline ($model, $desc)",
		ylabel = "stage",
		xticks = 0:60:maximum(df.time_sent),
		xtickformat = xs -> ["$(round(Int, x÷60))min" for x in xs],
	)
	hideydecorations!(ax, ticklabels=false, label=false)
	
	_started = df.status .== "Started"
	_running = df.status .== "Running"
	_done = df.status .== "Done"
	
	scatter!(df[_started, :time_sent], df[_started, :stage]; label="Started")
	scatter!(df[_running, :time_sent], df[_running, :stage]; label="Running")
	scatter!(df[_done, :time_sent], df[_done, :stage]; label="Done")

	Legend(f[1, 2], ax)

	f
end

# ╔═╡ Cell order:
# ╟─2e393b06-46f5-11ec-3258-8371b50807e7
# ╟─0c54e190-8dab-4021-8b89-88299c2f07af
# ╟─edfbd427-6d01-45f6-ae10-d309fe2723a7
# ╟─d95a40fd-7d48-420c-b49e-e40e721639a6
# ╟─536adf23-691d-49be-8656-8340f3089582
# ╟─1aed787b-9793-428e-95b3-e7c8b2695f05
# ╟─88630af8-3193-4487-871d-cce8e93985d4
# ╠═b2df1ca8-ff2d-4f63-a484-a59b84dbcd82
# ╠═4cabaffe-99fa-4d7e-b8e9-34afb0830fa3
# ╠═9c21b470-ae46-42d2-a192-d7e3691dd7a8
# ╠═3783109b-7db2-4b1a-8fcc-459b22791fe2
# ╠═3dfd9d2e-89fc-4cba-9942-f7cf2142be2b
# ╠═fe6218a8-d31f-47ba-948c-819ea42d379f
