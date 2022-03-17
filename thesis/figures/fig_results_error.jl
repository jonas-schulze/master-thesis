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

# ╔═╡ 96a5a545-4990-4cbc-983b-0978a16b27b5
md"""
# Numerical Error
"""

# ╔═╡ a0df7dcc-7789-49ae-9817-32c994f0a0db
lr_jobs = [
	:lr11 => 351158,
	:lr12 => 351167,
	:lr22 => 351160,
];

# ╔═╡ cc56a776-df99-428b-b779-0c8ab9fb6ae4
de_jobs = [
	:de11 => 351236,
	:de12 => 351235,
	:de22 => 351290,
];

# ╔═╡ 66eadee2-fb59-4ad7-a497-77b7449cb6c3
function find_dataset(dir, jobid)
	files = readdir(datadir(dir))
	filter!(endswith(".h5"), files)
	i = findfirst(contains("jobid=$jobid"), files)
	i == nothing && return nothing
	return datadir(dir, files[i])
end

# ╔═╡ 67260252-72da-4483-b247-36f1ce572e11
lr_files = [k => find_dataset("lowrank-par", jobid) for (k, jobid) in lr_jobs];

# ╔═╡ 596e573e-9dfe-480b-83bd-c8122126c170
de_files = [k => find_dataset("dense-par", jobid) for (k, jobid) in de_jobs];

# ╔═╡ 4e786e87-0eb4-4eeb-91fb-e32821ff21eb
begin
	files = vcat(lr_files, de_files)
	files = filter(kv -> kv[2] != nothing, files)
end

# ╔═╡ df9f58a0-44c2-4fbb-9e52-797142c8c939
datasets = map(first, files)

# ╔═╡ a0699076-bd42-4d4b-9209-82e94c76d15f
onlaptop = length(datasets) < 6

# ╔═╡ d926301d-2182-4f3c-9c6b-5fd263da4606
ref = something(
	find_dataset("dense-par", 351270), # de44
	files[1][2],
)

# ╔═╡ bb185a25-30a5-4f22-9ff4-ed4636e61f30
τ = 0.1

# ╔═╡ 8ee748d2-5e86-450b-a941-1ef85a0ad820
err(r, s) = norm(r-s) / norm(r)

# ╔═╡ 0a52e188-5653-478b-8edc-4ef7f4ff5914
begin
	df = DataFrame(t = 0:τ:4500)
	h5open(ref) do h5
		df[!, :K] = [read(h5["K/t=$t"]) for t in df.t]
	end

	if onlaptop
		@info "Adding noise to reference K"
		noise = randn(size(df.K[1])) / 1000
		for i in eachindex(df[!, :K])
			df[i, :K] .+= noise
		end
	end
	df
end

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

# ╔═╡ 3480579f-fc30-4fa6-9769-275383a033e3
md"""
## TODO

* load data only if present, skip otherwise
* run whole script on mechthild (i.e. where all data is present)
* replicate Fig 1 from [Lang2015]
"""

# ╔═╡ 77ff08e8-447b-44d6-88cb-ad82d8af1a47
md"## Style"

# ╔═╡ 58ea6ecf-d819-4b4e-a028-a3ed1ef4e3c4
color = to_colormap(:rainbow, 6)

# ╔═╡ 907533af-ac4d-4ae5-b54e-d304b2e0f33c
label = Dict(
	:lr11 => "LRSIF 1/1",
	:lr12 => "LRSIF 1/2",
	:lr22 => "LRSIF 2/2",
	:de11 => "Dense 1/1",
	:de12 => "Dense 1/2",
	:de22 => "Dense 2/2",
)

# ╔═╡ d132cdeb-4170-4bda-9dee-2230ba76025b
# same order = same marker
#marker = repeat([:utriangle, :rect, :pentagon], outer=2)
marker = [:cross, :utriangle, :rect, :xcross, :dtriangle, :diamond]

# ╔═╡ c172eac6-37ee-4418-94b4-6d1661180653
function alternating_scatter_points(t_anker, Δt, i, (t0, tf))
	# ensure accuracy within 0.1:
	t_anker′ = t_anker + i*(10Δt÷6)/10
	ts = union(reverse(t_anker′:-Δt:t0), t_anker′:Δt:tf)
	return ts
end

# ╔═╡ 150fabb3-782a-4e2f-b6b8-00db59c4f5fd
scatter_ts = [
	alternating_scatter_points(0, 1000, i, (0, 4300)) for i in 0:5
]

# ╔═╡ 5d31b4f3-c43b-469e-a79c-b315b987a23e
zoomed_scatter_ts = [
	alternating_scatter_points(4350, 50, i, (4320, 4500-1)) for i in 0:5
]

# ╔═╡ ee265157-3900-4215-9937-bd66de5eb2e7
md"## Internal Stuff"

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
	fig = Figure(font=utopia_regular)

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

	vspan!(axs[1,1], xmin, 4500, color=(:gray, 0.2))
	vspan!(axs[2,1], xmin, 4500, color=(:gray, 0.2))

	Legend(
		fig[3,1:2],
		axs[1,1],
		"Parareal Scheme (Coarse/Fine Order)";
		merge = true,
		tellheight = true,
		tellwidth = false,
		orientation = :horizontal,
	)

	fig
end

# ╔═╡ 0bd8a706-7056-41e1-b9ba-a8cbb52b806a
save(projectdir("thesis", "figures", "fig_results_rail.pdf"), fig)

# ╔═╡ Cell order:
# ╠═96a5a545-4990-4cbc-983b-0978a16b27b5
# ╠═a0df7dcc-7789-49ae-9817-32c994f0a0db
# ╠═cc56a776-df99-428b-b779-0c8ab9fb6ae4
# ╠═66eadee2-fb59-4ad7-a497-77b7449cb6c3
# ╠═67260252-72da-4483-b247-36f1ce572e11
# ╠═596e573e-9dfe-480b-83bd-c8122126c170
# ╠═4e786e87-0eb4-4eeb-91fb-e32821ff21eb
# ╠═df9f58a0-44c2-4fbb-9e52-797142c8c939
# ╠═a0699076-bd42-4d4b-9209-82e94c76d15f
# ╠═d926301d-2182-4f3c-9c6b-5fd263da4606
# ╠═bb185a25-30a5-4f22-9ff4-ed4636e61f30
# ╠═8ee748d2-5e86-450b-a941-1ef85a0ad820
# ╠═0a52e188-5653-478b-8edc-4ef7f4ff5914
# ╠═2297866e-4681-4ff5-8d10-0d909e4b3a18
# ╠═c70ae8c4-3958-4593-a261-c407034c9903
# ╠═760d7dc8-75c7-4c1a-bc2b-aeaa492aa689
# ╠═0bd8a706-7056-41e1-b9ba-a8cbb52b806a
# ╠═b434a321-4c1d-4d49-88a2-1000505bdac9
# ╠═3480579f-fc30-4fa6-9769-275383a033e3
# ╠═77ff08e8-447b-44d6-88cb-ad82d8af1a47
# ╠═58ea6ecf-d819-4b4e-a028-a3ed1ef4e3c4
# ╠═907533af-ac4d-4ae5-b54e-d304b2e0f33c
# ╠═d132cdeb-4170-4bda-9dee-2230ba76025b
# ╠═150fabb3-782a-4e2f-b6b8-00db59c4f5fd
# ╠═5d31b4f3-c43b-469e-a79c-b315b987a23e
# ╠═c172eac6-37ee-4418-94b4-6d1661180653
# ╟─ee265157-3900-4215-9937-bd66de5eb2e7
# ╠═beb66898-a474-11ec-3dbb-41f087ae87c7
# ╠═3bc5994e-27a8-4b62-942b-dd1add954e42
# ╠═956151fd-d3be-40d3-97bd-b1c6a556d853
# ╠═d376571e-997f-444c-9038-498ba614624e
# ╠═315e7622-4659-4073-80f5-5bfb9fec2989
# ╠═add0543d-31ab-42c1-bd21-d896f20b4422
