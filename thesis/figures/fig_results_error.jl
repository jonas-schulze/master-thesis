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
lr_jobs = Dict(
	:lr11 => 351158,
	:lr12 => 351167,
	:lr22 => 351160,
);

# ╔═╡ cc56a776-df99-428b-b779-0c8ab9fb6ae4
de_jobs = Dict(
	:de11 => 351236,
	:de12 => 351235,
	:de22 => 351290,
);

# ╔═╡ 66eadee2-fb59-4ad7-a497-77b7449cb6c3
function find_dataset(dir, jobid)
	files = readdir(datadir(dir))
	i = findfirst(contains("jobid=$jobid"), files)
	i == nothing && return nothing
	return datadir(dir, files[i])
end

# ╔═╡ 67260252-72da-4483-b247-36f1ce572e11
lr_files = Dict(k => find_dataset("lowrank-par", jobid) for (k, jobid) in lr_jobs);

# ╔═╡ 596e573e-9dfe-480b-83bd-c8122126c170
de_files = Dict(k => find_dataset("dense-par", jobid) for (k, jobid) in de_jobs);

# ╔═╡ 4e786e87-0eb4-4eeb-91fb-e32821ff21eb
begin
	files = merge(lr_files, de_files)
	files = filter(kv -> kv[2] != nothing, files)
end

# ╔═╡ d926301d-2182-4f3c-9c6b-5fd263da4606
ref = something(
	find_dataset("dense-par", 351270), # de44
	files[:lr11],
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
	df
end

# ╔═╡ 2297866e-4681-4ff5-8d10-0d909e4b3a18
begin
	df_err = DataFrame(t=df.t)
	@sync for (ds, f) in files
		@async h5open(f) do h5
			df_err[!, ds] = [δ(read(h5["K/t=$t"]), K) for (t, K) in zip(df.t, df.K)]
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

# ╔═╡ 3480579f-fc30-4fa6-9769-275383a033e3
md"""
## TODO

* load data only if present, skip otherwise
* run whole script on mechthild (i.e. where all data is present)
* replicate Fig 1 from [Lang2015]
"""

# ╔═╡ ee265157-3900-4215-9937-bd66de5eb2e7
md"## Internal Stuff"

# ╔═╡ add0543d-31ab-42c1-bd21-d896f20b4422
let
	files = [
		"/usr/local/texlive/2018/texmf-dist/fonts/type1/adobe/utopia/putr8a.pfb",
		"~/utopia/putr8a.pfb",
	]
	i = findfirst(isfile, files)
	global utopia_regular = files[i]
end

# ╔═╡ 58ea6ecf-d819-4b4e-a028-a3ed1ef4e3c4
colormap = to_colormap(:rainbow, max(2, length(files)))

# ╔═╡ ff57c6a9-8e3c-4030-9099-21a0ab4b4736
fig_err = let
	fig = Figure(font=utopia_regular)
	ax = Axis(
		fig[1,1];
		title = "Relative Error vs Reference",
		yscale = Makie.pseudolog10,
		xtime...,
	)

	# I only have the lr11 dataset on my laptop,
	# which I also use as a dummy reference solution.
	# If running locally, adjust the axis limits for dummy data:
	length(files) <= 1 && ylims!(ax, -1, 1)

	# TODO: fix order of keys
	for (n, ds) in enumerate(keys(files))
		lines!(
			ax, df_err.t, df_err[!, ds];
			label="$ds",
			color=colormap[n],
		)
	end

	Legend(
		fig[2,1], ax, "Parareal Scheme";
		tellheight = true,
		tellwidth = false,
		orientation = :horizontal,
	)
	fig
end

# ╔═╡ 34cc5f84-0f7e-41e2-a1d5-f5def64b2578
save(projectdir("thesis", "figures", "fig_results_error.pdf"), fig_err)

# ╔═╡ 4236845d-0abf-4927-bfb3-09e691dbdcc9
fig_k = let
	fig = Figure(font=utopia_regular)
	# Global View
	ax = Axis(
		fig[1,1];
		xtime...,
	)
	# Zoomed View
	ax2 = Axis(
		fig[1,2];
		xtime...,
		yaxisposition = :right,
		#backgroundcolor = (:gray, 0.1),
	)
	xmin = 4320
	ids = df.t .>= xmin

	# TODO: fix order of keys

	# Compute limits of zoomed view, to draw a little magnifier in global view:
	∞ = typemax(Float64)
	ymin, ymax = ∞, -∞

	for (n, ds) in enumerate(keys(files))
		lines!(
			ax, df_k.t, df_k[!, ds];
			label="$ds",
			color=colormap[n],
		)

		k = df_k[ids, ds]
		lines!(
			ax2, df_k.t[ids], k;
			label="$ds",
			color=colormap[n],
		)

		m, M = extrema(k)
		ymin = min(ymin, m)
		ymax = max(ymax, M)
	end

	# Draw little maginifier:
	h = ymax - ymin
	w = 4500 - xmin
	Δw = 0.25w
	Δh = 0.25h
	poly!(
		ax,
		Point2f[
			(xmin-Δw, ymin-Δh),
			(4500+Δw, ymin-Δh),
			(4500+Δw, ymax+Δh),
			(xmin-Δw, ymax+Δh),
		],
		color=(:gray, 0.25),
	)

	Legend(
		fig[2,1:2], ax, "Parareal Scheme";
		tellheight = true,
		tellwidth = false,
		orientation = :horizontal,
	)
	fig
end

# ╔═╡ 61e2b6f9-efeb-46e6-9426-7f2154c575b7
save(projectdir("thesis", "figures", "fig_results_k177.pdf"), fig_k)

# ╔═╡ Cell order:
# ╠═96a5a545-4990-4cbc-983b-0978a16b27b5
# ╠═a0df7dcc-7789-49ae-9817-32c994f0a0db
# ╠═cc56a776-df99-428b-b779-0c8ab9fb6ae4
# ╠═66eadee2-fb59-4ad7-a497-77b7449cb6c3
# ╠═67260252-72da-4483-b247-36f1ce572e11
# ╠═596e573e-9dfe-480b-83bd-c8122126c170
# ╠═4e786e87-0eb4-4eeb-91fb-e32821ff21eb
# ╠═d926301d-2182-4f3c-9c6b-5fd263da4606
# ╠═bb185a25-30a5-4f22-9ff4-ed4636e61f30
# ╠═8ee748d2-5e86-450b-a941-1ef85a0ad820
# ╠═0a52e188-5653-478b-8edc-4ef7f4ff5914
# ╠═2297866e-4681-4ff5-8d10-0d909e4b3a18
# ╠═c70ae8c4-3958-4593-a261-c407034c9903
# ╠═ff57c6a9-8e3c-4030-9099-21a0ab4b4736
# ╠═34cc5f84-0f7e-41e2-a1d5-f5def64b2578
# ╠═4236845d-0abf-4927-bfb3-09e691dbdcc9
# ╠═61e2b6f9-efeb-46e6-9426-7f2154c575b7
# ╠═3480579f-fc30-4fa6-9769-275383a033e3
# ╟─ee265157-3900-4215-9937-bd66de5eb2e7
# ╠═beb66898-a474-11ec-3dbb-41f087ae87c7
# ╠═3bc5994e-27a8-4b62-942b-dd1add954e42
# ╠═956151fd-d3be-40d3-97bd-b1c6a556d853
# ╠═d376571e-997f-444c-9038-498ba614624e
# ╠═315e7622-4659-4073-80f5-5bfb9fec2989
# ╠═add0543d-31ab-42c1-bd21-d896f20b4422
# ╠═58ea6ecf-d819-4b4e-a028-a3ed1ef4e3c4
