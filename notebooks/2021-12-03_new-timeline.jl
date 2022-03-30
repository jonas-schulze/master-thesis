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

# ╔═╡ 9dc8147e-a9a4-4db3-b783-2b0e8ea52aac
using StatsBase: median

# ╔═╡ ea4dbc42-51f2-11ec-3feb-e7e6d7aeea38
md"""
# New Timeline Explorer

Select event log directory, `ldir`, to analyze:
"""

# ╔═╡ 3b496553-814f-4577-8dd6-6776af0afddb
let
	dirs = readdir(logdir())
	filter!(!startswith("."), dirs)
	filter!(!endswith(".gz"), dirs)
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

# ╔═╡ 52871948-356f-449f-b5a3-fb479945cfdd
min_k = minimum(skipmissing(long.k))

# ╔═╡ 45c6302c-afda-4f2f-a93e-a5761658fe7c
md"""
Transforming to wide format and discarding

* all singleton events
* the first occurence of `:Waiting[Recv]` per stage $(@bind drop_first_waiting CheckBox(default=true))
* all occurences of `:Waiting*` $(@bind drop_all_waiting CheckBox(default=false))
* all occurences of `:CheckConv` $(@bind drop_all_checkconv CheckBox(default=false))
* all occurences of `:ComputingU` $(@bind drop_all_computingu CheckBox(default=false))

yields:
"""

# ╔═╡ 33159e26-d481-4f9e-9a0a-f615259165cb
is_waiting_recv(tag::Symbol) = tag == :Waiting || tag == :WaitingRecv

# ╔═╡ 1115cd97-ed84-4793-b97c-598dcd5b600a
is_waiting(tag::Symbol) = startswith(string(tag), "Waiting")

# ╔═╡ 3c813346-a80a-4f8c-9c1c-d8c8ef4152ea
begin
	wide = unstack(long, :type, :time; allowduplicates=true)
	dropmissing!(wide, [:start, :stop])
	if drop_first_waiting
		filter!([:tag, :k] => (tag, k) -> !is_waiting_recv(tag) || k > min_k, wide)
	end
	drop_all_waiting && filter!(:tag => !is_waiting, wide)
	drop_all_checkconv && filter!(:tag => !=(:CheckConv), wide)
	drop_all_computingu && filter!(:tag => !=(:ComputingU), wide)
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
	:duration => mean => :duration, # seconds
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
	nowaiting = filter(:tag => !is_waiting_recv, wide)
	combine(
		groupby(nowaiting, :tag),
		:duration => minimum,
		:duration => mean,
	)
end

# ╔═╡ b938bffb-c40a-4f33-9abe-e2c4189f470b
md"""
## Parallel Efficiency

If we take the last fine solutions computed per stage as a proxy for the sequential runtime,
we are able to estimate the parallel efficiency of the parareal method,
or the present implementation thereof.
"""

# ╔═╡ e734f294-c2e8-48c7-ace4-4bc96eb5aad1
N = maximum(wide.n)

# ╔═╡ 61230673-84d8-48cc-a8b2-0e372878e765
computing_f = filter(:tag => ==(:ComputingF), wide);

# ╔═╡ 703cab34-3a40-4777-a6f4-90534694bf19
last_k = combine(groupby(computing_f, :n), :k => maximum => :k);

# ╔═╡ 6d5124f5-1e13-4712-929e-b08cb0f3bd1d
final_computing_f = innerjoin(computing_f, last_k; on=names(last_k))

# ╔═╡ a3c8eb4b-1ad7-4b76-8791-cffe15c312f2
#t_seq = N * t_F
t_seq = sum(final_computing_f.duration)

# ╔═╡ 67177efa-4f0c-46d6-b908-25ce3fa99c41
t_par = maximum(long.time)

# ╔═╡ dac09b25-6568-4321-b775-01576997c5b8
speedup = t_seq / t_par

# ╔═╡ 3c688a18-4349-499c-81cc-c27381be6afa
efficiency = t_seq / (N*t_par)

# ╔═╡ 8158bfcd-cc73-4655-8eaa-53ec28107dd3
md"""
## Runtime Estimation

Assumptions:

1. runtime of $F, G$ is independent of $n, k$
2. runtime of $F$ scales linearly with resolution
3. time to compute actual parareal update $U_{n+1}^{k+1}$ is negligible
4. communication is negligible
5. all stages perform $K$ iterations

Assumptions 1 and therefore 2 are false for low-rank codes.
Due the last assumption, this is an estimated upper bound on the actual runtime,
since due to convergence a stage may perform less than $K$ iterations.

The estimated runtime is then given by
"""

# ╔═╡ 1b5c5ef2-f5b5-4a0a-a43f-e1149f8846ba
t_par

# ╔═╡ 48fa4527-ad9d-4234-a296-2e287d3dfee9
x = 10

# ╔═╡ db841a95-e981-472c-bb82-b63b5b41bc4c
md"### Parameters"

# ╔═╡ 30109542-42f1-4081-8118-e91ad168e23b
t_warmup = maximum(wide[wide.tag .== :WarmingUpC, :duration], init=0)

# ╔═╡ 9c856059-b10b-471f-9daf-b69fe32038bd
t_G = median(wide[wide.tag .== :ComputingC, :duration])

# ╔═╡ 34dc0ef7-9a34-4062-a648-a4fffbdb7572
t_F = median(wide[wide.tag .== :ComputingF, :duration])

# ╔═╡ 4bf31390-d8fc-47b4-a4ca-916f6dd68da4
K = maximum(computing_f.k)

# ╔═╡ 35423cbd-3dea-4213-8f20-bc8a4829c83c
md"""
### Sanity Checks
"""

# ╔═╡ ec2f4843-094a-4254-9bcc-55459a93201e
md"## Internal Stuff"

# ╔═╡ 34276091-7190-4237-b22c-a7d185f1f533
ARGS

# ╔═╡ 7e478254-c005-49b0-9b38-5fb2420a96fe
function _filter(df; kwargs...)
	nt = NamedTuple(kwargs)
	ks = collect(keys(nt))
	pred(vs...) = NamedTuple(zip(ks, vs)) === nt
	# use === to handle missing better
	filter(ks => pred, df)
end

# ╔═╡ 786b3ed6-69c2-4d8b-97a9-2e4dc05128d0
#t_rampup = (t_par - (t_warmup + N*t_G + K*(t_F + t_G) + t_F)) / N 
t_rampup = only(_filter(delays, tag=:ComputingC, k=0).start_delay) - t_G
#t_rampup = only(_filter(delays, tag=:ComputingF, k=0).start_delay) - t_G
#t_rampup = mean(diff(vcat(t_warmup, first_send.stop[1:end-1]))) - t_G

# ╔═╡ 3a3913d0-0078-4c8f-8544-c80a04277f93
function t̂_par(;
	N=N, K=K,
	t_warmup=t_warmup,
	t_rampup=t_rampup,
	t_G=t_G,
	t_F=t_F,
)
	t_warmup + N*(t_rampup + t_G) + K*(t_F + t_G) + t_F
end

# ╔═╡ c16c0f43-f67f-44b3-a8a4-e7c3c076ee3d
t̂_par()

# ╔═╡ f126805b-ca4e-48cb-829d-1b8a51857aea
err = abs(t_par - t̂_par()) / t_par

# ╔═╡ c8c5eba2-727e-4e0b-a04a-ba13e5628254
margin = ceil(Int, 100err)

# ╔═╡ a0cfebf5-158d-4bfc-b3e6-c1c701c02426
md"which is wihtin $margin% of the actual runtime."

# ╔═╡ 4d47b803-c6f2-456b-9fb3-4f784493e7a9
t̂_par_x = t̂_par(t_F=x*t_F)

# ╔═╡ a4839d95-0140-4414-a7ae-ee6d2bb964a5
efficiency_x = x * t_seq / (N * t̂_par_x)

# ╔═╡ 1a7b4350-cb76-46ed-9f39-114d8661084a
md"""
### Higher Temporal Resolution

If $F$ took $x times as long,
the efficiency would be $(round(efficiency_x / efficiency, digits=2)) times as much.
"""

# ╔═╡ bc08f6c0-a26d-4cdd-ab8a-e9376f95f939
t̂_par_ideal = t̂_par(t_rampup=0)

# ╔═╡ 965e8641-9d1a-4410-aab9-a607194b8b9e
efficiency_ideal = t_seq / (N * t̂_par_ideal)

# ╔═╡ 29738399-70c2-4e1c-a171-66e5371145b5
md"""
### Ideal Conditions

Without any ramp-up delay, the parallel efficiency would be
$(round(efficiency_ideal / efficiency, digits=2)) times as much.
"""

# ╔═╡ 0f4e6b3f-a5f3-47f4-afdc-2a64543f4b10
t̂_par_x_ideal = t̂_par(t_F=x*t_F, t_rampup=0)

# ╔═╡ 6ec15f47-a8b1-4819-a33f-07fe9999f375
efficiency_x_ideal = x * t_seq / (N * t̂_par_x_ideal)

# ╔═╡ a19e9eb2-4300-4fce-99f0-342240cb6881
md"""
### Higher Temporal Resolution Under Ideal Conditions

Without any ramp-up delay and if $F$ took $x times as long,
the parallel efficiency would be
$(round(efficiency_x_ideal / efficiency, digits=2)) times as high.
"""

# ╔═╡ 45ddf305-0646-4f34-8b12-e5861457c3d4
first_send = _filter(wide, tag=:WaitingSend, k=0);

# ╔═╡ cc55b617-1cc1-4bce-a837-e25047049730
@assert issorted(first_send.n)

# ╔═╡ dc5499fc-9ec7-4a30-a8da-9e6cd915b1ea
let
	df = _filter(long; n=N, tag=:ComputingC, k=0)
	df[!, :estimate] = [
		t_warmup + (N-1)*(t_rampup + t_G),
		t_warmup + N*(t_rampup + t_G),
	]
	df
end

# ╔═╡ b27e4f95-fc29-4bed-a712-aed66c3cfa41
let
	df = _filter(long; n=N, tag=:ComputingF, type=:stop)
	df[!, :estimate] = [
		t_warmup + N*(t_rampup + t_G) + k*(t_F + t_G) + t_F for k in 0:K
	]
	df
end

# ╔═╡ 571fa07c-a132-4180-932a-0c6ec55e6ec8
TableOfContents()

# ╔═╡ Cell order:
# ╟─ea4dbc42-51f2-11ec-3feb-e7e6d7aeea38
# ╠═3b496553-814f-4577-8dd6-6776af0afddb
# ╠═03411522-4c84-4e82-81b8-f54e45988fa9
# ╟─38c28b69-59a8-46b3-b08e-c527e91a29ef
# ╠═c787987e-9241-423e-bb90-5e04f724dd30
# ╠═52871948-356f-449f-b5a3-fb479945cfdd
# ╟─45c6302c-afda-4f2f-a93e-a5761658fe7c
# ╠═3c813346-a80a-4f8c-9c1c-d8c8ef4152ea
# ╠═33159e26-d481-4f9e-9a0a-f615259165cb
# ╠═1115cd97-ed84-4793-b97c-598dcd5b600a
# ╠═2ac964d3-cc44-4754-9416-afd8c689fc64
# ╟─2b8dfcad-70ac-4a5e-a5c9-f0d959ecca73
# ╠═e34b4e67-e1ea-4166-80fc-e2001e9b52f8
# ╠═a12610eb-b6ae-4eba-8dad-a4c8b9d9ccf9
# ╠═d9b7f93b-a7cc-4f43-98cb-c05ec104599e
# ╟─605451ee-dc25-4966-8e9c-3c59711e3a64
# ╠═bccadd7d-6126-4940-a4aa-4a892ffc0e47
# ╟─b938bffb-c40a-4f33-9abe-e2c4189f470b
# ╠═dac09b25-6568-4321-b775-01576997c5b8
# ╠═3c688a18-4349-499c-81cc-c27381be6afa
# ╠═e734f294-c2e8-48c7-ace4-4bc96eb5aad1
# ╠═61230673-84d8-48cc-a8b2-0e372878e765
# ╠═703cab34-3a40-4777-a6f4-90534694bf19
# ╠═6d5124f5-1e13-4712-929e-b08cb0f3bd1d
# ╠═a3c8eb4b-1ad7-4b76-8791-cffe15c312f2
# ╠═67177efa-4f0c-46d6-b908-25ce3fa99c41
# ╟─8158bfcd-cc73-4655-8eaa-53ec28107dd3
# ╠═3a3913d0-0078-4c8f-8544-c80a04277f93
# ╠═c16c0f43-f67f-44b3-a8a4-e7c3c076ee3d
# ╟─a0cfebf5-158d-4bfc-b3e6-c1c701c02426
# ╠═1b5c5ef2-f5b5-4a0a-a43f-e1149f8846ba
# ╠═f126805b-ca4e-48cb-829d-1b8a51857aea
# ╠═c8c5eba2-727e-4e0b-a04a-ba13e5628254
# ╟─1a7b4350-cb76-46ed-9f39-114d8661084a
# ╠═48fa4527-ad9d-4234-a296-2e287d3dfee9
# ╠═4d47b803-c6f2-456b-9fb3-4f784493e7a9
# ╠═a4839d95-0140-4414-a7ae-ee6d2bb964a5
# ╠═29738399-70c2-4e1c-a171-66e5371145b5
# ╠═bc08f6c0-a26d-4cdd-ab8a-e9376f95f939
# ╠═965e8641-9d1a-4410-aab9-a607194b8b9e
# ╟─a19e9eb2-4300-4fce-99f0-342240cb6881
# ╠═0f4e6b3f-a5f3-47f4-afdc-2a64543f4b10
# ╠═6ec15f47-a8b1-4819-a33f-07fe9999f375
# ╟─db841a95-e981-472c-bb82-b63b5b41bc4c
# ╠═30109542-42f1-4081-8118-e91ad168e23b
# ╠═9c856059-b10b-471f-9daf-b69fe32038bd
# ╠═34dc0ef7-9a34-4062-a648-a4fffbdb7572
# ╠═786b3ed6-69c2-4d8b-97a9-2e4dc05128d0
# ╠═45ddf305-0646-4f34-8b12-e5861457c3d4
# ╠═cc55b617-1cc1-4bce-a837-e25047049730
# ╠═4bf31390-d8fc-47b4-a4ca-916f6dd68da4
# ╟─35423cbd-3dea-4213-8f20-bc8a4829c83c
# ╠═dc5499fc-9ec7-4a30-a8da-9e6cd915b1ea
# ╠═b27e4f95-fc29-4bed-a712-aed66c3cfa41
# ╟─ec2f4843-094a-4254-9bcc-55459a93201e
# ╠═f7697dc2-5084-4d01-ad47-7bb8a1cb578e
# ╠═29380fa3-e8d5-40ac-bd32-71efbb0455c8
# ╠═90dd638d-a520-44a8-8586-ba63ed745f33
# ╠═c4e4ba56-fee0-434d-821b-d27d7cf12d4a
# ╠═9dc8147e-a9a4-4db3-b783-2b0e8ea52aac
# ╠═34276091-7190-4237-b22c-a7d185f1f533
# ╠═7e478254-c005-49b0-9b38-5fb2420a96fe
# ╠═571fa07c-a132-4180-932a-0c6ec55e6ec8
