### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ beb66898-a474-11ec-3dbb-41f087ae87c7
using DrWatson

# ╔═╡ 956151fd-d3be-40d3-97bd-b1c6a556d853
using Stuff

# ╔═╡ 3bc5994e-27a8-4b62-942b-dd1add954e42
@quickactivate

# ╔═╡ d376571e-997f-444c-9038-498ba614624e
using CairoMakie

# ╔═╡ 315e7622-4659-4073-80f5-5bfb9fec2989
using DataFrames

# ╔═╡ 386e9bca-4119-46c5-9d64-159fb65bbd94
using PlutoUI

# ╔═╡ 96a5a545-4990-4cbc-983b-0978a16b27b5
md"""
# Numerical Error vs Reference
"""

# ╔═╡ 4b6f8f72-c970-4f29-a536-1658f1523dfb
datadir(::SequentialConfig{X}, args...) where {X} =
	DrWatson.datadir("$X-seq", args...)

# ╔═╡ 66eadee2-fb59-4ad7-a497-77b7449cb6c3
function find_dataset(conf)
	datadir(conf, savename(conf, "h5"))
end

# ╔═╡ d926301d-2182-4f3c-9c6b-5fd263da4606
ref = find_dataset(SequentialConfig{:dense}(ncpus=1, nsteps=900, order=4))

# ╔═╡ bb185a25-30a5-4f22-9ff4-ed4636e61f30
τ = 10.0

# ╔═╡ 0a52e188-5653-478b-8edc-4ef7f4ff5914
begin
	df = DataFrame(t = 0:τ:4500)
	h5open(ref) do h5
		df[!, :K] = [read(h5["K/t=$t"]) for t in df.t]
	end
	df
end

# ╔═╡ e4d8e78d-439f-4daf-9599-0c1f5c9e995f
ref_t = 0:τ/2:4500

# ╔═╡ 71aacbeb-c830-45d2-a4f5-443dcb127879
ref_k = h5open(ref) do h5
	[h5["K/t=$t"][1,77] for t in ref_t]
end

# ╔═╡ cf76c752-491b-42dc-ae94-ac43e5f131ff
begin
	desc(x) = desc(x...)
	desc(data, order) = Symbol(data, order)
end

# ╔═╡ 75637d54-4918-4b72-8ade-cb2882b01317
conf = [
	desc(x, o) => SequentialConfig{x}(ncpus=1, nsteps=450, order=o)
	for x in (:lowrank, :dense) for o in 1:2
]

# ╔═╡ 0e8ab850-70d9-45a8-a4ea-32c2b417c5b0
files = [k => find_dataset(c) for (k, c) in conf]

# ╔═╡ df9f58a0-44c2-4fbb-9e52-797142c8c939
datasets = map(first, files)

# ╔═╡ 2297866e-4681-4ff5-8d10-0d909e4b3a18
begin
	# skip zero error at end
	df_err = DataFrame(t=df.t[1:end-1])
	@sync for (ds, f) in files
		@async h5open(f) do h5
			df_err[!, ds] = [δ(read(h5["K/t=$t"]), K) for (t, K) in zip(df_err.t, df.K)]
		end
	end
	df_err
end

# ╔═╡ c70ae8c4-3958-4593-a261-c407034c9903
begin
	df_k = DataFrame(t=df.t)
	@sync for (ds, f) in files
		@async h5open(f) do h5
			df_k[!, ds] = [h5["K/t=$t"][1,77] for t in df.t]
		end
	end
	df_k
end

# ╔═╡ b434a321-4c1d-4d49-88a2-1000505bdac9
function alternating_scatter!(ax, x, y, scatter_x; kwargs...)
	lines!(
		ax, x, y;
		kwargs...,
	)
	scatter_ids = findall(in(scatter_x), x)
	scatter!(
		ax, scatter_x, y[scatter_ids];
		kwargs...,
		#color = :white, # overwrite line color
	)
end

# ╔═╡ 04603e32-7f71-4474-999d-4ce4d13cca02
md"""
# Low-Rank vs Dense Algorithms

There clearly is a problem with Ros2.
Check whether the low-rank algorithms (of the same step size) yield the same iterates as the dense algorithms do.
"""

# ╔═╡ 7aec1323-78cb-44e7-a61c-1c1f0ee7695b
function err(x, ref)
	haskey(x, "L") || return δ(x, ref)
	L, D = read(x["L"]), read(x["D"])
	X = L*D*L'
	Ref = read(ref)
	δ(X, Ref)
end

# ╔═╡ 3b9a82c6-3325-4627-aa15-82d9b5fcc90e
begin
	# skip zero error at end
	lowrank_vs_dense = DataFrame(t=df.t[1:end-1])
	for order in 1:2
		lr = h5open(files[order][2])
		de = h5open(files[order+2][2])

		for mat in ("X", "K")
			lowrank_vs_dense[!, "order$(order)_$mat"] = [
				err(lr["$mat/t=$t"], de["$mat/t=$t"])
				for t in lowrank_vs_dense.t
			]
		end

		close(lr)
		close(de)
	end
	lowrank_vs_dense
end

# ╔═╡ 2528f411-f0a3-485a-9f8c-e64350d2b686
md"""
# Rank of X
"""

# ╔═╡ 806f1929-006e-497f-8da9-539427f0ef41
begin
	ranks = DataFrame(t=df.t)
	for (ds, f) in files[1:2]
		h5open(f) do h5
			ranks[!, ds] = [size(h5["X/t=$t/D"], 1) for t in ranks.t]
		end
	end
	ranks
end

# ╔═╡ 77ff08e8-447b-44d6-88cb-ad82d8af1a47
md"""
# Style

The style (colors, marker, etc.) must be identical to the parareal version of all plots.
Therefore, select the subset of combinations to use for the sequential plots:
"""

# ╔═╡ cb4e2a25-9286-4d82-9d86-ff01b26a5bc8
ids = [1,3,4,6]

# ╔═╡ 58ea6ecf-d819-4b4e-a028-a3ed1ef4e3c4
color = to_colormap(:rainbow, 6)[ids]

# ╔═╡ 49f5374c-485b-4e59-aeeb-230436aa619f
# matches color of low-rank solutions in error plot
lr_color = color[1:2]

# ╔═╡ 907533af-ac4d-4ae5-b54e-d304b2e0f33c
label = Dict(
	:lowrank1 => "LRSIF 1",
	:lowrank2 => "LRSIF 2",
	:dense1 => "Dense 1",
	:dense2 => "Dense 2",
)

# ╔═╡ d132cdeb-4170-4bda-9dee-2230ba76025b
marker = [:cross, :utriangle, :rect, :xcross, :dtriangle, :diamond][ids]

# ╔═╡ dfa68c91-d577-4054-986e-63d5f7860977
#nscatter = length(files) + 1
nscatter = length(files)

# ╔═╡ c172eac6-37ee-4418-94b4-6d1661180653
function alternating_scatter_points(t_anker, Δt, i, (t0, tf))
	# ensure accuracy within 0.1:
	t_anker′ = t_anker + i*(10Δt÷nscatter)/10
	ts = union(reverse(t_anker′:-Δt:t0), t_anker′:Δt:tf)
	return ts
end

# ╔═╡ 150fabb3-782a-4e2f-b6b8-00db59c4f5fd
scatter_ts = [
	alternating_scatter_points(0, 1000, i, (0, 4300)) for i in 0:nscatter-1
]

# ╔═╡ 7af83a90-de33-4a52-bc8b-6426aa43892b
@assert all(ts -> all(in(df.t), ts), scatter_ts)

# ╔═╡ 5d31b4f3-c43b-469e-a79c-b315b987a23e
zoomed_scatter_ts = [
	alternating_scatter_points(4350, 10nscatter, i, (4320, 4500-1)) for i in 0:nscatter-1
]

# ╔═╡ bfd17733-3ad9-4895-8c38-075492677879
@assert all(ts -> all(in(df.t), ts), zoomed_scatter_ts)

# ╔═╡ ee265157-3900-4215-9937-bd66de5eb2e7
md"# Internal Stuff"

# ╔═╡ add0543d-31ab-42c1-bd21-d896f20b4422
let
	files = [
		"/usr/local/texlive/2018/texmf-dist/fonts/type1/adobe/utopia/putr8a.pfb",
		joinpath(homedir(), "utopia", "putr8a.pfb"),
	]
	i = findfirst(isfile, files)
	global utopia_regular = files[i]
end

# ╔═╡ 760d7dc8-75c7-4c1a-bc2b-aeaa492aa689
fig = let
	fig = Figure(
		font=utopia_regular,
	)

	padding = (0, 0, 5, 0)
	Label(fig[1, 1:2, Top()], "Trajectory"; padding)
	Label(fig[2, 1:2, Top()], "Relative Error"; padding)

	axs = [Axis(
		fig[i,j];
		yaxisposition = ifelse(j == 2, :right, :left),
		yscale = ifelse(i == 1, identity, log10),
		xtime...,
		xlabel="",
	) for i in 1:2, j in 1:2]
	linkxaxes!(axs[:, 1]...)
	linkxaxes!(axs[:, 2]...)
	hidexdecorations!.(axs[1,:], grid=false)

	xmin = 4320
	ids_k = df_k.t .>= xmin
	ids_err = df_err.t .>= xmin

	for (ds, c, m, ts, zts) in zip(
		datasets,
		color,
		marker,
		scatter_ts,
		zoomed_scatter_ts,
	)
		kwargs = (;
			label=label[ds],
			color=c,
			marker=m,
			strokecolor=c,
			strokewidth=1,
		)
		# trajectory
		alternating_scatter!(
			axs[1,1], df_k[!, :t], df_k[!, ds], ts;	kwargs...)
		alternating_scatter!(
			axs[1,2], df_k[ids_k, :t], df_k[ids_k, ds], zts; kwargs...)
		# error
		alternating_scatter!(
			axs[2,1], df_err[!, :t], df_err[!, ds], ts; kwargs...)
		alternating_scatter!(
			axs[2,2], df_err[ids_err, :t], df_err[ids_err, ds], zts; kwargs...)
	end

	# Plot reference solution
	ids = ref_t .>= xmin
	kwargs = (;
		label="Reference",
		color=:gray,
		linestyle=:dash,
		marker=:circle,
		strokecolor=:gray,
		strokewidth=1,
	)
	#alternating_scatter!(axs[1,1], ref_t, ref_k, scatter_ts[end]; kwargs...)
	#alternating_scatter!(axs[1,2], ref_t[ids], ref_k[ids], zoomed_scatter_ts[end]; kwargs...)
	lines!(axs[1,1], ref_t, ref_k; kwargs...)
	lines!(axs[1,2], ref_t[ids], ref_k[ids]; kwargs...)

	vspan!(axs[1,1], xmin, 4500, color=(:gray, 0.2))
	vspan!(axs[2,1], xmin, 4500, color=(:gray, 0.2))

	Legend(
		fig[3,1:2],
		axs[1,2],
		"Rosenbrock Scheme and Order";
		merge = true,
		tellheight = true,
		tellwidth = false,
		orientation = :horizontal,
	)

	fig
end

# ╔═╡ 0bd8a706-7056-41e1-b9ba-a8cbb52b806a
save(projectdir("thesis", "figures", "fig_results_sequential.pdf"), fig)

# ╔═╡ f1055f65-029c-465e-97e4-48faa2c79def
fig_err = let
	fig = Figure(
		resolution=(550,300), # half
		font=utopia_regular,
	)

	ax = Axis(
		fig[1,1];
		title="Relative Error LRSIF vs Dense",
		yscale=log10,
		xtime...,
		xlabel="",
	)

	for o in 1:2
		lines!(
			ax,
			lowrank_vs_dense.t,
			lowrank_vs_dense[!, "order$(o)_K"],
			label = "LRSIF $o",
			color = lr_color[o],
			linewidth = 1,
		)
		ids = 1:100:450
		scatter!(
			ax,
			lowrank_vs_dense.t[ids],
			lowrank_vs_dense[ids, "order$(o)_K"];
			color = lr_color[o],
			label = "LRSIF $o",
			marker = marker[o],
		)
	end

	#axislegend("Scheme", position=:rc, merge=true)
	Legend(fig[1,2], ax, "Scheme", merge=true)

	fig
end

# ╔═╡ bd1f6835-9637-4ecc-9dbc-d284ba6ba104
save(projectdir("thesis", "figures", "fig_results_sequential_err.pdf"), fig_err)

# ╔═╡ e233b985-408a-424c-bc30-1d9a3642250d
fig_rank = let
	fig = Figure(
		resolution=(550,300),
		font=utopia_regular,
	)
	ax = Axis(
		fig[1,1];
		title="Rank",
		xtime...,
		xlabel="",
	)

	for o in 1:2
		ds = datasets[o]
		lines!(
			ax,
			ranks.t,
			ranks[!, ds];
			color = lr_color[o],
			label = "LRSIF $o",
			linewidth=1,
		)
		ids = 1:100:450
		scatter!(
			ax,
			ranks.t[ids],
			ranks[ids, ds];
			color = lr_color[o],
			label = "LRSIF $o",
			marker = marker[o],
		)
	end

	#axislegend("Scheme", position=:lb, merge=true)
	Legend(fig[1,2], ax, "Scheme", merge=true)

	fig
end

# ╔═╡ a842d066-4263-4fad-b5ad-8ed9af5e3b04
save(projectdir("thesis", "figures", "fig_results_sequential_rank.pdf"), fig_rank)

# ╔═╡ 1e172867-6837-4f74-9b4d-08d652368bdf
TableOfContents()

# ╔═╡ Cell order:
# ╠═96a5a545-4990-4cbc-983b-0978a16b27b5
# ╠═75637d54-4918-4b72-8ade-cb2882b01317
# ╠═4b6f8f72-c970-4f29-a536-1658f1523dfb
# ╠═66eadee2-fb59-4ad7-a497-77b7449cb6c3
# ╠═0e8ab850-70d9-45a8-a4ea-32c2b417c5b0
# ╠═df9f58a0-44c2-4fbb-9e52-797142c8c939
# ╠═d926301d-2182-4f3c-9c6b-5fd263da4606
# ╠═bb185a25-30a5-4f22-9ff4-ed4636e61f30
# ╠═0a52e188-5653-478b-8edc-4ef7f4ff5914
# ╠═2297866e-4681-4ff5-8d10-0d909e4b3a18
# ╠═c70ae8c4-3958-4593-a261-c407034c9903
# ╠═e4d8e78d-439f-4daf-9599-0c1f5c9e995f
# ╠═71aacbeb-c830-45d2-a4f5-443dcb127879
# ╠═cf76c752-491b-42dc-ae94-ac43e5f131ff
# ╠═760d7dc8-75c7-4c1a-bc2b-aeaa492aa689
# ╠═0bd8a706-7056-41e1-b9ba-a8cbb52b806a
# ╠═b434a321-4c1d-4d49-88a2-1000505bdac9
# ╟─04603e32-7f71-4474-999d-4ce4d13cca02
# ╠═f1055f65-029c-465e-97e4-48faa2c79def
# ╠═bd1f6835-9637-4ecc-9dbc-d284ba6ba104
# ╠═3b9a82c6-3325-4627-aa15-82d9b5fcc90e
# ╠═7aec1323-78cb-44e7-a61c-1c1f0ee7695b
# ╟─2528f411-f0a3-485a-9f8c-e64350d2b686
# ╠═49f5374c-485b-4e59-aeeb-230436aa619f
# ╠═e233b985-408a-424c-bc30-1d9a3642250d
# ╠═a842d066-4263-4fad-b5ad-8ed9af5e3b04
# ╠═806f1929-006e-497f-8da9-539427f0ef41
# ╟─77ff08e8-447b-44d6-88cb-ad82d8af1a47
# ╠═cb4e2a25-9286-4d82-9d86-ff01b26a5bc8
# ╠═58ea6ecf-d819-4b4e-a028-a3ed1ef4e3c4
# ╠═907533af-ac4d-4ae5-b54e-d304b2e0f33c
# ╠═d132cdeb-4170-4bda-9dee-2230ba76025b
# ╠═150fabb3-782a-4e2f-b6b8-00db59c4f5fd
# ╠═7af83a90-de33-4a52-bc8b-6426aa43892b
# ╠═5d31b4f3-c43b-469e-a79c-b315b987a23e
# ╠═bfd17733-3ad9-4895-8c38-075492677879
# ╠═dfa68c91-d577-4054-986e-63d5f7860977
# ╠═c172eac6-37ee-4418-94b4-6d1661180653
# ╠═ee265157-3900-4215-9937-bd66de5eb2e7
# ╠═beb66898-a474-11ec-3dbb-41f087ae87c7
# ╠═3bc5994e-27a8-4b62-942b-dd1add954e42
# ╠═956151fd-d3be-40d3-97bd-b1c6a556d853
# ╠═d376571e-997f-444c-9038-498ba614624e
# ╠═315e7622-4659-4073-80f5-5bfb9fec2989
# ╠═add0543d-31ab-42c1-bd21-d896f20b4422
# ╠═386e9bca-4119-46c5-9d64-159fb65bbd94
# ╠═1e172867-6837-4f74-9b4d-08d652368bdf
