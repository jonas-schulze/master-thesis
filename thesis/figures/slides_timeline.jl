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

# ╔═╡ 1e94b2e6-cc71-11ec-3960-03c2d41331ac
using DrWatson

# ╔═╡ 004fbc60-14e1-44b3-867e-8433bbf5d462
using PlutoUI, Stuff, DataFrames, StatsBase

# ╔═╡ 1f9824db-7d97-43ad-b786-0e88d2becd01
@quickactivate

# ╔═╡ fa7a72ba-1502-41ba-83c5-23051b883256
using CairoMakie

# ╔═╡ 7b64b2a0-fd02-4d1d-ad9a-6e6fea41ff8d
using LoggingFormats: LogFmt

# ╔═╡ 0c9dad30-35f1-4bb7-88ec-9112a1cc1b0f
using StatsBase: median

# ╔═╡ 5fb1a39b-589a-410d-b1d1-fd1e4025019b
md"# Timeline Diagram"

# ╔═╡ 2a3f7ac0-cf24-4258-a6ab-e9e94f0f97a3
jobid = !isempty(ARGS) ? only(ARGS) : 358690

# ╔═╡ 6b90ed77-bbd4-4b60-a221-577fa8c79d81
ldirs = filter(contains(string(jobid)), readdir(logdir()))

# ╔═╡ d7bdaef4-e36c-4df9-85a2-3784f8e99c35
@bind ldir Select(ldirs)

# ╔═╡ 32532b72-6886-45a1-bb2f-66075a89cd46
md"""
## Tags and Color Scheme
"""

# ╔═╡ ef34fc67-1cde-4b13-9bb3-20c38535ad44
tags = [
	:WarmingUpC,
	:WarmingUpF,
	:ComputingC,
	:ComputingF,
]

# ╔═╡ eae5c032-52ab-457b-95a8-f556bd81a5dd
desc = Dict(
	:WarmingUpC => "Warm up coarse solver",
	:WarmingUpF => "Warm up fine solver",
	:ComputingC => "Coarse solver",
	:ComputingF => "Fine solver",
)

# ╔═╡ 9073e7f7-212c-4f87-b67e-80dd41ffbe9f
function fig_timeline(
	df; 
	resolution = (800,300), 
	yticks,
	legend_horizontal::Bool = false,
	xlims = nothing,
	ylims = nothing,
	ylabel = "Parareal Stage",
)
	fig = Figure(;
		figure_padding = 1,
		resolution
	)
	ax = Axis(
		fig[1,1];
		yticks,
		ylabel,
		xwalltime...,
	)

	# Adjust y limits:
	if !isnothing(ylims)
		lo, hi = ylims
		Δ = 0.05*(hi - lo)
		ylims!(ax, lo-Δ, hi+Δ)
	end

	# Adjust x limits:
	if !isnothing(xlims)
		lo, hi = xlims
		Δ = 0.05*(hi - lo)
		xlims!(ax, lo-Δ, hi+Δ)
	end

	# Color events by tag:
	colors = to_colormap(:sun, length(tags))
	colormap = Dict(t => colors[i] for (i, t) in enumerate(tags))
	colorcol = [colormap[t] for t in df.tag]
	timeline!(ax, df, colorcol)

	# Legend:
	legend_ids = in.(tags, Ref(df.tag))
	elements = [PolyElement(polycolor=colormap[t]) for t in tags[legend_ids]]
	labels = [desc[t] for t in tags[legend_ids]]
	Legend(
		fig[ifelse(legend_horizontal, (2, 1), (1, 2))...],
		elements,
		labels,
		nothing;
		orientation=legend_horizontal ? :horizontal : :vertical
	)

	fig
end

# ╔═╡ c464eccd-43e4-403f-8e21-53e8ef0fb1b7
colors = to_colormap(:sun, length(tags))

# ╔═╡ 56a1dc76-345b-4419-a991-e03c51057b02
colormap = Dict(t => colors[i] for (i, t) in enumerate(tags))

# ╔═╡ 153e7c69-de0e-424b-ab98-ec06289f8a8c
md"""
## Load Event Log
"""

# ╔═╡ f2c751c4-db84-421f-aad9-2a5fe0c760d3
long = load_eventlog(LogFmt(), logdir(ldir))

# ╔═╡ fc62f27e-ccd4-4d29-91cb-2f7f0931cea0
function prep_eventlog(long, tags)
	wide = unstack(long, :type, :time; allowduplicates=true)
	dropmissing!(wide, [:start, :stop])
	filter!(:tag => in(tags), wide)
	wide[!, :duration] = wide.stop - wide.start
	wide
end

# ╔═╡ 52706b20-6b76-4d9a-be3e-a7849efe1af0
wide = prep_eventlog(long, tags)

# ╔═╡ 9ae72c69-c99a-4628-87c9-f69d56dccca5
fig = fig_timeline(
	wide; 
	yticks=0:100:400, 
	resolution=(800,600),
	legend_horizontal=false,
)

# ╔═╡ ca0398c4-0436-4a15-a6e7-f0eddc096d88
save(projectdir("thesis", "figures", "slides_timeline$jobid.pdf"), fig)

# ╔═╡ 548c0b82-cf44-4fe0-acf3-6f28e6e88523
md"""
# Special Timelines
## slides_timeline8.pdf

Plot the (left) middle timeline chart of the warm-up plot Figure 7.1 separately.
"""

# ╔═╡ a4c46d67-35df-497e-9aed-32a6f9b8480c
ldir8 = let
	_jobid = 349137
	ldirs = filter(contains(string(_jobid)), readdir(logdir()))
	ldirs[2]
end

# ╔═╡ d2f93a81-0b94-4e0c-a3ad-a8bb85ffed01
long8 = load_eventlog(LogFmt(), logdir(ldir8));

# ╔═╡ 159aee2c-e779-41a2-80d6-caf28ed296ef
wide8 = prep_eventlog(long8, tags);

# ╔═╡ 8bb90a53-abb8-4d92-965b-2e8d77eede28
fig8 = fig_timeline(wide8, yticks=[4,8], legend_horizontal=false)

# ╔═╡ a7693336-627d-4594-bbb8-113b2f878925
save(projectdir("thesis", "figures", "slides_timeline8.pdf"), fig8)

# ╔═╡ 4ef8a90d-07e9-46d8-a7b1-1592f4f024ce
md"""
## slides_timeline1357.pdf

Plot the timelines for the parareal method applied to Rail1357.
"""

# ╔═╡ 8cf9699b-b048-47bb-8eab-813995ae1c3f
kwargs1357 = (
	yticks=0:100:400,
	legend_horizontal=true,
	resolution=(600,500),
	ylims = (0, 450),
)

# ╔═╡ 93631538-e2c8-4e4a-be91-3825bfe9371b
ldir1357 = let
	_jobid = 358690
	ldirs = filter(contains(string(_jobid)), readdir(logdir()))
	only(ldirs)
end

# ╔═╡ 21d3a361-9685-4418-9cd3-d28ee02a9e39
long1357 = load_eventlog(LogFmt(), logdir(ldir1357));

# ╔═╡ a2bfdea4-1e3c-48e2-9189-9d6f7a4fb4f9
wide1357 = prep_eventlog(long1357, tags);

# ╔═╡ b4eb3098-ab67-435d-afb3-d758934157bc
fig1357_1 = fig_timeline(wide1357; kwargs1357...)

# ╔═╡ a7d9e106-48b2-4614-b3b8-0ace6553de46
save(projectdir("thesis", "figures", "slides_timeline1357_1.pdf"), fig1357_1)

# ╔═╡ 17d7e999-d224-4d20-bc8b-7a2e98fc012c
ntasks=225

# ╔═╡ daa88755-e449-40b9-9ae7-056e3d51238b
begin
	wide1357_rr = copy(wide1357)
	wide1357_rr.n = mod1.(wide1357.n, ntasks)
end;

# ╔═╡ 7a85975d-f4c3-4bc4-99fd-e31ecbaf1b29
fig1357_2 = fig_timeline(wide1357_rr; kwargs1357..., ylabel="Worker Process")

# ╔═╡ d30d494b-ca0d-4a0b-ad31-96709a5db3cd
save(projectdir("thesis", "figures", "slides_timeline1357_2.pdf"), fig1357_2)

# ╔═╡ 9dc3e51d-186c-4ed3-87bd-9577524906d8
fig1357_zoom = fig_timeline(
	wide1357; 
	kwargs1357...,
	xlims=(1600,3000),
	ylims=(380,450),
	yticks=380:10:450,
)

# ╔═╡ 9e65dd1d-e213-418e-85b9-ac3595b0f7d0
save(projectdir("thesis", "figures", "slides_timeline1357_zoom.pdf"), fig1357_zoom)

# ╔═╡ fc26e83e-937e-4e80-850c-8187a664d83d
md"# Internal Stuff"

# ╔═╡ 77c0e968-a4b2-4618-8d19-c2026aa322f7
TableOfContents()

# ╔═╡ Cell order:
# ╟─5fb1a39b-589a-410d-b1d1-fd1e4025019b
# ╠═2a3f7ac0-cf24-4258-a6ab-e9e94f0f97a3
# ╠═6b90ed77-bbd4-4b60-a221-577fa8c79d81
# ╠═d7bdaef4-e36c-4df9-85a2-3784f8e99c35
# ╠═9ae72c69-c99a-4628-87c9-f69d56dccca5
# ╠═ca0398c4-0436-4a15-a6e7-f0eddc096d88
# ╠═9073e7f7-212c-4f87-b67e-80dd41ffbe9f
# ╟─32532b72-6886-45a1-bb2f-66075a89cd46
# ╠═ef34fc67-1cde-4b13-9bb3-20c38535ad44
# ╠═eae5c032-52ab-457b-95a8-f556bd81a5dd
# ╠═c464eccd-43e4-403f-8e21-53e8ef0fb1b7
# ╠═56a1dc76-345b-4419-a991-e03c51057b02
# ╟─153e7c69-de0e-424b-ab98-ec06289f8a8c
# ╠═f2c751c4-db84-421f-aad9-2a5fe0c760d3
# ╠═52706b20-6b76-4d9a-be3e-a7849efe1af0
# ╠═fc62f27e-ccd4-4d29-91cb-2f7f0931cea0
# ╟─548c0b82-cf44-4fe0-acf3-6f28e6e88523
# ╠═a4c46d67-35df-497e-9aed-32a6f9b8480c
# ╠═d2f93a81-0b94-4e0c-a3ad-a8bb85ffed01
# ╠═159aee2c-e779-41a2-80d6-caf28ed296ef
# ╠═8bb90a53-abb8-4d92-965b-2e8d77eede28
# ╠═a7693336-627d-4594-bbb8-113b2f878925
# ╟─4ef8a90d-07e9-46d8-a7b1-1592f4f024ce
# ╠═8cf9699b-b048-47bb-8eab-813995ae1c3f
# ╠═93631538-e2c8-4e4a-be91-3825bfe9371b
# ╠═21d3a361-9685-4418-9cd3-d28ee02a9e39
# ╠═a2bfdea4-1e3c-48e2-9189-9d6f7a4fb4f9
# ╠═b4eb3098-ab67-435d-afb3-d758934157bc
# ╠═a7d9e106-48b2-4614-b3b8-0ace6553de46
# ╠═daa88755-e449-40b9-9ae7-056e3d51238b
# ╠═17d7e999-d224-4d20-bc8b-7a2e98fc012c
# ╠═7a85975d-f4c3-4bc4-99fd-e31ecbaf1b29
# ╠═d30d494b-ca0d-4a0b-ad31-96709a5db3cd
# ╠═9dc3e51d-186c-4ed3-87bd-9577524906d8
# ╠═9e65dd1d-e213-418e-85b9-ac3595b0f7d0
# ╠═fc26e83e-937e-4e80-850c-8187a664d83d
# ╠═1e94b2e6-cc71-11ec-3960-03c2d41331ac
# ╠═1f9824db-7d97-43ad-b786-0e88d2becd01
# ╠═004fbc60-14e1-44b3-867e-8433bbf5d462
# ╠═fa7a72ba-1502-41ba-83c5-23051b883256
# ╠═7b64b2a0-fd02-4d1d-ad9a-6e6fea41ff8d
# ╠═77c0e968-a4b2-4618-8d19-c2026aa322f7
# ╠═0c9dad30-35f1-4bb7-88ec-9112a1cc1b0f
