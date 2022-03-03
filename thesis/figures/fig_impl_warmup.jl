### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ f854e8d8-9243-11ec-011f-77239716f41a
begin
	import Pkg
	Pkg.activate("../..")
end

# ╔═╡ f0a2c191-312a-4f9d-b125-21e715965bdf
using PlutoUI, Stuff, DataFrames, StatsBase

# ╔═╡ e483c292-95bb-4f34-b445-ac2d2a3f8fcd
using CairoMakie

# ╔═╡ 31e753cb-26a2-4948-9df1-9893b5b3e0d3
using LoggingFormats: LogFmt

# ╔═╡ b6638371-3db3-4c70-8be8-bf22c6876dbd
md"""
# Effect of JIT Warm-Up
"""

# ╔═╡ acdff91c-7ecb-4b40-a9f9-00747c252201
tags = [
	:WarmingUpC,
	:WarmingUpF,
	:ComputingC,
	:ComputingF,
]

# ╔═╡ ec719c08-ee95-4e20-af48-cd22274f1f0f
desc = Dict(
	:WarmingUpC => "Warm up coarse solver",
	:WarmingUpF => "Warm up fine solver",
	:ComputingC => "Coarse solver",
	:ComputingF => "Fine solver",
)

# ╔═╡ 330fee10-3012-48d8-9126-8a67162a546b
# This is broken, as MathTeXEngine.jl only supports Computer Modern.
desc2 = Dict(
	:WarmingUpC => L"Warming up $G$",
	:WarmingUpF => L"Warming up $F$",
	:ComputingC => L"Computing $G(U_{n-1}^k)$",
	:ComputingF => L"Computing $F(U_{n-1}^k)$",
	:ComputingU => L"Computing $U_n^k$",
)

# ╔═╡ 70e4adc9-3d87-4d98-a38c-029595945094
md"## Saving Tools"

# ╔═╡ 5d40ca96-2862-4900-9de4-1d7dd7eb0785
CairoMakie.activate!(type="svg")

# ╔═╡ 60f58305-f6ea-41ce-b911-7a3daa13e07e
md"## Load Thesis Font"

# ╔═╡ cd1f7582-6a70-4da7-aa0a-a5d89bafe04c
utopia_regular = "/usr/local/texlive/2018/texmf-dist/fonts/type1/adobe/utopia/putr8a.pfb"

# ╔═╡ 920265f1-ffc6-4c06-81c6-3fecbf4e8f0d
function fig_impl_warmup(cols...)
	fig = Figure(font=utopia_regular)

	# Color events by tag:
	colors = to_colormap(:sun, length(tags))
	colormap = Dict(t => colors[i] for (i, t) in enumerate(tags))

	# Add timeline plots:
	grid = fig[1, 1] = GridLayout()
	ncols = length(cols)
	nrows = length(first(cols))
	ax = [
		Axis(grid[r,c], yticks=[4,8], xtickformat="{:d}s")
		for r in 1:nrows, c in 1:ncols
	]
	for (c, col) in enumerate(cols)
		for (r, df) in enumerate(col)
			colorcol = [colormap[t] for t in df.tag]
			timeline!(ax[r,c], df, colorcol)
		end
	end
	for c in 1:ncols
		linkxaxes!(ax[:, c]...)
		hidexdecorations!.(ax[1:end-1, c], grid=false)
	end
	for r in 1:nrows
		linkyaxes!(ax[r, :]...)
		hideydecorations!.(ax[r, 2:end], grid=false)
	end
		

	# Add x label:
	Label(
		fig[2, 1],
		"Wallclock Time",
		tellwidth=false,
	)

	# Add legend:
	elements = [PolyElement(polycolor=colormap[t]) for t in tags]
	labels = [desc[t] for t in tags]
	Legend(
		fig[3, 1],
		elements,
		labels,
		nothing;
		orientation = :horizontal,
		nbanks = 2,
	)

	# Add y label:
	Label(
		fig[1, 0],
		"Parareal Stage",
		tellheight=false,
		rotation=pi/2,
	)

	fig
end

# ╔═╡ 0ea872ff-0f47-4d72-b589-9de911dae763
@assert isfile(utopia_regular)

# ╔═╡ b09c929c-2ccc-4a84-8984-e69cf8405731
md"""
## Select Logfiles
"""

# ╔═╡ 4c1f290d-db79-410b-88a7-b7a37baefa62
jobid = 349137

# ╔═╡ 6645e47b-9cb8-4ea1-b983-e9ef2ccc94e1
mechthild_dir = filter(contains(string(jobid)), readdir(logdir()))

# ╔═╡ 57d76bda-1308-4854-b938-655846aaa732
laptop_dir = [
	savename(ParallelConfig{:dense}(; nf=10, jobid="0", nstages=4, ncpus=1, wc, wf))
	for (wc, wf) in [(false, false), (true, false), (true, true)]
]

# ╔═╡ 261266a7-1465-4746-94b4-688c533bb678
@assert all(isdir ∘ logdir, laptop_dir)

# ╔═╡ e90cddce-900d-4412-81e3-12ddc6cf0c3d
@assert all(isdir ∘ logdir, laptop_dir)

# ╔═╡ da080a89-4511-4bc3-8ac8-c322067f8919
readdir(logdir())

# ╔═╡ ab72a2d8-017d-4b19-8aa7-43d78148b995
md"## Load Event Logs"

# ╔═╡ ce4c5e88-d457-47b8-879a-5198d02a5c2e
mechthild_long = @. load_eventlog(LogFmt(), logdir(mechthild_dir))

# ╔═╡ 030d5893-39ef-452c-a496-35f63cfcda3f
laptop_long = @. load_eventlog(LogFmt(), logdir(laptop_dir))

# ╔═╡ 25f6d795-4dd4-44a8-8cf1-bb6ec2413aed
function prep_eventlog(long, tags)
	wide = unstack(long, :type, :time; allowduplicates=true)
	dropmissing!(wide, [:start, :stop])
	filter!(:tag => in(tags), wide)
	wide[!, :duration] = wide.stop - wide.start
	wide
end

# ╔═╡ 2e3e46c3-ca07-4e7f-affa-636382d26d75
mechthild_wide = prep_eventlog.(mechthild_long, Ref(tags))

# ╔═╡ 75e2a1bd-ee3d-4c5f-b4b1-f31523426cb5
f1 = fig_impl_warmup(mechthild_wide)

# ╔═╡ 19b95dad-19f8-4dcc-8f40-bf2d9aa5e114
save(projectdir("thesis", "figures", "fig_impl_warmup1.pdf"), f1)

# ╔═╡ 31d3455e-8f54-42c7-bcf7-4adfcfa7eb37
laptop_wide = prep_eventlog.(laptop_long, Ref(tags))

# ╔═╡ 9755adcf-4c12-456b-9b13-9f46df9f27de
f2 = fig_impl_warmup(mechthild_wide, laptop_wide)

# ╔═╡ d1150f97-322d-475e-9900-33869d7cd803
save(projectdir("thesis", "figures", "fig_impl_warmup2.pdf"), f2)

# ╔═╡ 43af3c9f-bc72-42f9-bb85-d1544dbdd401
md"## Internal Stuff"

# ╔═╡ Cell order:
# ╟─b6638371-3db3-4c70-8be8-bf22c6876dbd
# ╠═75e2a1bd-ee3d-4c5f-b4b1-f31523426cb5
# ╠═9755adcf-4c12-456b-9b13-9f46df9f27de
# ╠═920265f1-ffc6-4c06-81c6-3fecbf4e8f0d
# ╠═acdff91c-7ecb-4b40-a9f9-00747c252201
# ╠═ec719c08-ee95-4e20-af48-cd22274f1f0f
# ╠═330fee10-3012-48d8-9126-8a67162a546b
# ╟─70e4adc9-3d87-4d98-a38c-029595945094
# ╠═5d40ca96-2862-4900-9de4-1d7dd7eb0785
# ╠═19b95dad-19f8-4dcc-8f40-bf2d9aa5e114
# ╠═d1150f97-322d-475e-9900-33869d7cd803
# ╟─60f58305-f6ea-41ce-b911-7a3daa13e07e
# ╠═cd1f7582-6a70-4da7-aa0a-a5d89bafe04c
# ╠═0ea872ff-0f47-4d72-b589-9de911dae763
# ╟─b09c929c-2ccc-4a84-8984-e69cf8405731
# ╠═4c1f290d-db79-410b-88a7-b7a37baefa62
# ╠═6645e47b-9cb8-4ea1-b983-e9ef2ccc94e1
# ╠═57d76bda-1308-4854-b938-655846aaa732
# ╠═261266a7-1465-4746-94b4-688c533bb678
# ╠═e90cddce-900d-4412-81e3-12ddc6cf0c3d
# ╠═da080a89-4511-4bc3-8ac8-c322067f8919
# ╟─ab72a2d8-017d-4b19-8aa7-43d78148b995
# ╠═ce4c5e88-d457-47b8-879a-5198d02a5c2e
# ╠═030d5893-39ef-452c-a496-35f63cfcda3f
# ╠═25f6d795-4dd4-44a8-8cf1-bb6ec2413aed
# ╠═2e3e46c3-ca07-4e7f-affa-636382d26d75
# ╠═31d3455e-8f54-42c7-bcf7-4adfcfa7eb37
# ╟─43af3c9f-bc72-42f9-bb85-d1544dbdd401
# ╠═f854e8d8-9243-11ec-011f-77239716f41a
# ╠═f0a2c191-312a-4f9d-b125-21e715965bdf
# ╠═e483c292-95bb-4f34-b445-ac2d2a3f8fcd
# ╠═31e753cb-26a2-4948-9df1-9893b5b3e0d3
