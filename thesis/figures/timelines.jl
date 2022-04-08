### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ f88dc24c-b0df-11ec-2834-933f2c2069a9
using DrWatson

# ╔═╡ 4deba663-a8ee-403c-8a68-c7253a875524
@quickactivate

# ╔═╡ 870fcb93-8c6b-4963-8cb3-22c75e80ddb2
using PlutoUI

# ╔═╡ 742e1292-033b-4724-b59f-d6bc429e55b2
using CairoMakie

# ╔═╡ 20d5eff9-a9e1-4867-92f9-ca9c2e84fe7c
using Stuff

# ╔═╡ 44d4bc13-1647-44e6-852c-5f21f81e0bce
using Stuff: xwalltime

# ╔═╡ df75a7bf-d95b-40fc-986f-cbaf8e7dc035
using LoggingFormats: LogFmt

# ╔═╡ b059cb02-b199-4702-868b-8d74bec5d9d9
using DataFrames

# ╔═╡ 82232285-9bd5-465e-8f5c-1cf0b60bf48e
md"# Single Timeline"

# ╔═╡ 5075284e-e7fa-4f1e-b924-2b2f5faa9af9
jobid = 351_236

# ╔═╡ c9d96ceb-59c7-4474-929e-af5c89a22f63
md"# Reference Timeline"

# ╔═╡ 5a751c1c-daf6-45e3-abe8-7054e5fb34a1
ref_id = 351_270

# ╔═╡ feaacfef-9380-4349-9f1c-f29084e9aafb
md"# Other Timelines"

# ╔═╡ 173e8afd-d9dc-47ed-a5c8-65707612cb89
jobids = [
	351_236 351_235 351_290
	351_158 351_167 351_160
]

# ╔═╡ a6db2893-7e1c-4fad-9eb1-ee0b6a56fd62
md"""
## Load Eventlog
"""

# ╔═╡ af4f9756-0944-4d14-adc4-66e0664d5d20
dirs = let
	dirs = readdir(logdir())
	filter!(startswith("rail"), dirs)
	filter!(!endswith(".gz"), dirs)
	[only(filter(contains("jobid=$j"), dirs)) for j in jobids]
end

# ╔═╡ efec8801-e353-4560-a4b5-3a32cc106dd1
long = @. load_eventlog(LogFmt(), logdir(dirs))

# ╔═╡ 6ac03aec-6e66-46c6-aa8d-1bbec0c173c2
md"""
## Colormap and Legend

The colormap should be the same on all timeline diagrams,
no matter which events are actually shown or not.
"""

# ╔═╡ 8787385a-eae1-4a06-a6fe-96ff21e76bbd
_colors = to_colormap(:sun, 4)

# ╔═╡ f7c79dd4-4b23-4c65-bf81-9f2f66bd2bcb
tags = [
	:WarmingUpC,
	#:WarmingUpF,
	:ComputingC,
	:ComputingF,
	:WaitingRecv,
]

# ╔═╡ 015523ff-ede8-4704-890c-3c84065d8351
tags_nowait = filter(!=(:WaitingRecv), tags)

# ╔═╡ b0299795-293c-4035-92f0-a64970c57693
colormap = Dict(
	:WarmingUpC => _colors[1],
	#:WarmingUpF => _colors[2],
	:ComputingC => _colors[3],
	:ComputingF => _colors[4],
	:WaitingRecv => :gray90,
)

# ╔═╡ 308f2958-c8de-4e77-b0a8-4b47a9a1aecf
desc = Dict(
	:WarmingUpC => "Warm up coarse solver",
	:WarmingUpF => "Warm up fine solver",
	:ComputingC => "Coarse solver",
	:ComputingF => "Fine solver",
	:WaitingRecv => "Wait for input",
)

# ╔═╡ 4d573cc1-b520-4a14-954a-d1bdc5cb0b36
md"""
## Utopia Font
"""

# ╔═╡ abd02897-65a2-4bf3-9160-dbc11b198e33
utopia_regular = "/usr/local/texlive/2018/texmf-dist/fonts/type1/adobe/utopia/putr8a.pfb"

# ╔═╡ e4bfb138-239b-468b-b0b4-1eb7761031b0
@assert isfile(utopia_regular)

# ╔═╡ 59cab0eb-d0db-4ae6-927d-bc1460e6d95d
md"# Internal"

# ╔═╡ a1a9c4a6-5d67-455e-b4de-688f18300430
ARGS

# ╔═╡ b6aa3963-54fe-4948-836a-629762d7b069
TableOfContents()

# ╔═╡ a03491fc-785a-4dac-8c2e-9049173370d2
all_dirs = let
	dirs = readdir(logdir())
	filter!(startswith("rail"), dirs)
	filter!(!endswith(".gz"), dirs)
end

# ╔═╡ 322a2eac-8487-44a3-85a7-bc0f2f2f0225
find_jobid(id) = only(filter(contains("jobid=$id"), all_dirs))

# ╔═╡ 203913b7-9ebb-426e-a070-b1cd06675865
ref_dir = find_jobid(ref_id)

# ╔═╡ 0636f5f0-7402-4fa7-9599-a036ec4379bd
ref_long = load_eventlog(LogFmt(), logdir(ref_dir));

# ╔═╡ b23a6ad8-bfc5-498f-a37a-a7f5c8edf57f
function transform2wide(long; tags=tags_nowait)
	wide = unstack(long, :type, :time; allowduplicates=true)
	dropmissing!(wide, [:start, :stop])
	filter!(:tag => in(tags), wide)
	wide
end

# ╔═╡ 7cc8986d-67e0-4570-8e2c-107c5c114b0d
ref_wide = transform2wide(ref_long; tags=tags);

# ╔═╡ 8c517b04-ec6d-45f9-8bca-51c63722eede
fig_ref = let
	wide = ref_wide
	
	fig = Figure(
		figure_padding = 1,
		resolution = (800, 800),
		font = utopia_regular,
	)
	ax_all = Axis(fig[1,1]; title="Dense 4/4")
	ax_fst = Axis(fig[2,1]; xwalltime..., xlabel="")
	linkxaxes!(ax_all, ax_fst)
	hidexdecorations!(ax_all, grid=false)

	# Global timeline
	color = [colormap[t] for t in wide.tag]
	timeline!(ax_all, wide, color)

	# Zoom to first stages
	fst = filter(:n => in(0:20), wide)
	color = [colormap[t] for t in fst.tag]
	timeline!(ax_fst, fst, color)

	#rowsize!(fig.layout, 1, Relative(2/3))
	Label(fig[3,1], "Wallclock Time", tellwidth=false)
	Label(fig[1:2,0], "Parareal Stage", rotation=pi/2)

	# Legend
	elements = [PolyElement(polycolor=colormap[t]) for t in tags]
	labels = [desc[t] for t in tags]
	Legend(
		fig[4, 2],
		elements,
		labels,
		nothing;
		orientation = :horizontal,
		#nbanks = 2,
	)
	
	fig
end

# ╔═╡ a71c556e-7e01-4421-870e-5115735591a4
save(projectdir("thesis", "figures", "fig_timeline_ref.pdf"), fig_ref)

# ╔═╡ 45adc778-cc7e-4ae9-92ad-e6e5fdf39edc
wide = map(transform2wide, long)

# ╔═╡ beb84196-f94b-4c18-a181-698d135ac63d
fig = let
	fig = Figure(
		#resolution = (800, 1000),
		figure_padding = 1,
		font = utopia_regular,
	)
	axs = [
		Axis(
			fig[r,c];
			xwalltime...,
			xlabel="",
			xticks=0:1500:4500,
		) for r in 1:2, c in 1:3
	]
	for c in 1:3
		linkxaxes!(axs[:,c]...)
		hidexdecorations!(axs[1,c], grid=false)
	end
	linkyaxes!(axs[1,:]...)
	linkyaxes!(axs[2,:]...)
	hideydecorations!.(axs[:,2], grid=false)
	hideydecorations!.(axs[:,3], grid=false, label=false)
	# titles
	axs[1,1].title = "Order 1/1"
	axs[1,2].title = "Order 1/2"
	axs[1,3].title = "Order 2/2"
	# right labels
	axs[1,3].ylabel = "Dense"
	axs[2,3].ylabel = "LRSIF"
	axs[1,3].yaxisposition = :right
	axs[2,3].yaxisposition = :right
	# bottom label
	Label(fig[3, 1:3], "Wallclock Time")

	# Legend
	elements = [PolyElement(polycolor=colormap[t]) for t in tags_nowait]
	labels = [desc[t] for t in tags_nowait]
	Legend(
		fig[4, 1:3],
		elements,
		labels,
		nothing;
		orientation = :horizontal,
		#nbanks = 2,
	)

	# left label
	Label(fig[1:2,0], "Parareal Stage", rotation=pi/2)

	for (ax, wide) in zip(axs, wide)
		color = [colormap[t] for t in wide.tag]
		timeline!(ax, wide, color)
	end
	fig
end

# ╔═╡ be1aa85e-9584-4e2f-98c7-89db0817623e
save(projectdir("thesis", "figures", "fig_timeline_all.pdf"), fig)

# ╔═╡ Cell order:
# ╟─82232285-9bd5-465e-8f5c-1cf0b60bf48e
# ╠═5075284e-e7fa-4f1e-b924-2b2f5faa9af9
# ╟─c9d96ceb-59c7-4474-929e-af5c89a22f63
# ╠═5a751c1c-daf6-45e3-abe8-7054e5fb34a1
# ╠═8c517b04-ec6d-45f9-8bca-51c63722eede
# ╠═203913b7-9ebb-426e-a070-b1cd06675865
# ╠═0636f5f0-7402-4fa7-9599-a036ec4379bd
# ╠═7cc8986d-67e0-4570-8e2c-107c5c114b0d
# ╠═a71c556e-7e01-4421-870e-5115735591a4
# ╟─feaacfef-9380-4349-9f1c-f29084e9aafb
# ╠═173e8afd-d9dc-47ed-a5c8-65707612cb89
# ╠═beb84196-f94b-4c18-a181-698d135ac63d
# ╠═be1aa85e-9584-4e2f-98c7-89db0817623e
# ╟─a6db2893-7e1c-4fad-9eb1-ee0b6a56fd62
# ╠═015523ff-ede8-4704-890c-3c84065d8351
# ╠═af4f9756-0944-4d14-adc4-66e0664d5d20
# ╠═efec8801-e353-4560-a4b5-3a32cc106dd1
# ╠═45adc778-cc7e-4ae9-92ad-e6e5fdf39edc
# ╟─6ac03aec-6e66-46c6-aa8d-1bbec0c173c2
# ╠═8787385a-eae1-4a06-a6fe-96ff21e76bbd
# ╠═f7c79dd4-4b23-4c65-bf81-9f2f66bd2bcb
# ╠═b0299795-293c-4035-92f0-a64970c57693
# ╠═308f2958-c8de-4e77-b0a8-4b47a9a1aecf
# ╟─4d573cc1-b520-4a14-954a-d1bdc5cb0b36
# ╠═abd02897-65a2-4bf3-9160-dbc11b198e33
# ╠═e4bfb138-239b-468b-b0b4-1eb7761031b0
# ╟─59cab0eb-d0db-4ae6-927d-bc1460e6d95d
# ╠═a1a9c4a6-5d67-455e-b4de-688f18300430
# ╠═f88dc24c-b0df-11ec-2834-933f2c2069a9
# ╠═4deba663-a8ee-403c-8a68-c7253a875524
# ╠═870fcb93-8c6b-4963-8cb3-22c75e80ddb2
# ╠═b6aa3963-54fe-4948-836a-629762d7b069
# ╠═742e1292-033b-4724-b59f-d6bc429e55b2
# ╠═20d5eff9-a9e1-4867-92f9-ca9c2e84fe7c
# ╠═44d4bc13-1647-44e6-852c-5f21f81e0bce
# ╠═df75a7bf-d95b-40fc-986f-cbaf8e7dc035
# ╠═b059cb02-b199-4702-868b-8d74bec5d9d9
# ╠═a03491fc-785a-4dac-8c2e-9049173370d2
# ╠═322a2eac-8487-44a3-85a7-bc0f2f2f0225
# ╠═b23a6ad8-bfc5-498f-a37a-a7f5c8edf57f
