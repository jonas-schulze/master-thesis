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

# ╔═╡ f7697dc2-5084-4d01-ad47-7bb8a1cb578e
using DrWatson

# ╔═╡ 90dd638d-a520-44a8-8586-ba63ed745f33
using PlutoUI, Stuff, DataFrames, StatsBase

# ╔═╡ 29380fa3-e8d5-40ac-bd32-71efbb0455c8
@quickactivate

# ╔═╡ c4e4ba56-fee0-434d-821b-d27d7cf12d4a
using LoggingFormats: LogFmt

# ╔═╡ ea4dbc42-51f2-11ec-3feb-e7e6d7aeea38
md"""
# New Timeline Explorer

Select event log directory, `ldir`, to analyze:
"""

# ╔═╡ 3b496553-814f-4577-8dd6-6776af0afddb
let
	dirs = readdir(logdir())
	filter!(!startswith("."), dirs)
	@bind ldir Select(dirs, default=first(dirs))
end

# ╔═╡ 03411522-4c84-4e82-81b8-f54e45988fa9
with_terminal() do
	print(read(logdir(ldir, "1.log"), String))
end

# ╔═╡ 38c28b69-59a8-46b3-b08e-c527e91a29ef
md"All the log entries parsed and concatenated then look like this:"

# ╔═╡ c787987e-9241-423e-bb90-5e04f724dd30
long = load_eventlog(LogFmt(), logdir(ldir))

# ╔═╡ 45c6302c-afda-4f2f-a93e-a5761658fe7c
md"""
Transforming to wide format and discarding

* all singleton events
* the first occurence of `:Waiting` per stage $(@bind drop_first_waiting CheckBox(default=true))

yields:
"""

# ╔═╡ 3c813346-a80a-4f8c-9c1c-d8c8ef4152ea
begin
	wide = unstack(long, :type, :time)
	dropmissing!(wide, [:start, :stop])
	if drop_first_waiting
		filter!([:tag, :k] => (tag, k) -> tag != :Waiting || k > 1, wide)
	end
	wide[!, :duration] = wide.stop - wide.start
	wide
end

# ╔═╡ 2ac964d3-cc44-4754-9416-afd8c689fc64
timeline(wide)

# ╔═╡ 2b8dfcad-70ac-4a5e-a5c9-f0d959ecca73
md"""
## Ramp-up delay

Due to JIT compilation, synchronous transmission (which for now is not worth avoiding,
cf. [julia#37706](https://github.com/JuliaLang/julia/issues/37706)), etc,
and the sequential coarse solution of the parareal algorithm,
there is a certain delay between a type of event reaching the next stage.
This delay is visible as the slope (or the inverse of it, technically) of the face connecting corresponding boxes in the previous timeline diagram.

Select type of event, `tag`, for which to analyze the delays (inverse slope, measured in seconds per stage) and durations (width) of its `k`th occurences in the timeline diagram:
"""

# ╔═╡ e34b4e67-e1ea-4166-80fc-e2001e9b52f8
@bind tag Select(unique(wide.tag))

# ╔═╡ a12610eb-b6ae-4eba-8dad-a4c8b9d9ccf9
delays = combine(
	groupby(wide, [:tag, :k]),
	:n => length => :n_count, # number of stages
	:start => mean∘diff => :start_delay, # seconds per stage
	:stop => mean∘diff => :stop_delay, # seconds per stage
	:duration => minimum, # seconds
);

# ╔═╡ d9b7f93b-a7cc-4f43-98cb-c05ec104599e
filter(:tag => ==(tag), delays)

# ╔═╡ 605451ee-dc25-4966-8e9c-3c59711e3a64
md"""
## Ideal Ramp-up

Suppose all messages would happen instantaneously,
then the ramp-up delay (`start_delay` for `tag = :ComputingC`) would match the duration of the coarse solve.
This is the target for potential code optimizations to aim for:
"""

# ╔═╡ bccadd7d-6126-4940-a4aa-4a892ffc0e47
let
	nowaiting = filter(:tag => !=(:Waiting), wide)
	combine(
		groupby(nowaiting, :tag),
		:duration => minimum,
		:duration => mean,
	)
end

# ╔═╡ ec2f4843-094a-4254-9bcc-55459a93201e
md"## Internal Stuff"

# ╔═╡ Cell order:
# ╟─ea4dbc42-51f2-11ec-3feb-e7e6d7aeea38
# ╟─3b496553-814f-4577-8dd6-6776af0afddb
# ╠═03411522-4c84-4e82-81b8-f54e45988fa9
# ╟─38c28b69-59a8-46b3-b08e-c527e91a29ef
# ╠═c787987e-9241-423e-bb90-5e04f724dd30
# ╟─45c6302c-afda-4f2f-a93e-a5761658fe7c
# ╠═3c813346-a80a-4f8c-9c1c-d8c8ef4152ea
# ╠═2ac964d3-cc44-4754-9416-afd8c689fc64
# ╟─2b8dfcad-70ac-4a5e-a5c9-f0d959ecca73
# ╠═e34b4e67-e1ea-4166-80fc-e2001e9b52f8
# ╠═a12610eb-b6ae-4eba-8dad-a4c8b9d9ccf9
# ╠═d9b7f93b-a7cc-4f43-98cb-c05ec104599e
# ╟─605451ee-dc25-4966-8e9c-3c59711e3a64
# ╠═bccadd7d-6126-4940-a4aa-4a892ffc0e47
# ╟─ec2f4843-094a-4254-9bcc-55459a93201e
# ╠═f7697dc2-5084-4d01-ad47-7bb8a1cb578e
# ╠═29380fa3-e8d5-40ac-bd32-71efbb0455c8
# ╠═90dd638d-a520-44a8-8586-ba63ed745f33
# ╠═c4e4ba56-fee0-434d-821b-d27d7cf12d4a
