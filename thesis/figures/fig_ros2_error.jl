### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ 0a0bdf35-d54d-44ab-97a1-73550d330162
using DrWatson

# ╔═╡ 2b573699-e746-427b-928d-34bd3a40aa2f
@quickactivate

# ╔═╡ 3e3e15c0-c1ed-45df-8864-9e0126b7f308
using DifferentialRiccatiEquations

# ╔═╡ 4c3a03a6-2e72-4f39-a820-e63aa867f152
using LinearAlgebra, SparseArrays

# ╔═╡ b507b89f-1676-4223-9e49-5d1d0815f7c5
using MAT, UnPack

# ╔═╡ 7d192450-db4e-4c2d-aabb-98d09214d592
using CairoMakie

# ╔═╡ ef240f90-9efb-11ec-10ee-530b22c0c820
md"""
# Low-Rank Ros(2)
"""

# ╔═╡ 71a022ca-a8bf-440a-afd5-def7308a3b64
let
	P = matread(datadir("Rail371.mat"))
	global E, A, B, C
	@unpack E, A, B, C = P
end;

# ╔═╡ 9154efc0-b80e-4f2e-81b1-0c12473ab05c
q = size(C, 1)

# ╔═╡ b265c3c3-abca-49e1-9ef2-0839dfbd0f12
X₀ = LDLᵀ(E\(C'), sparse(I(q)/100))

# ╔═╡ b296e1f4-388f-4a46-a562-578392fd0d1d
Δt = 180
#Δt = prod(2:5)

# ╔═╡ efdf19d3-f8f8-4c5c-9f81-991ab4c8de48
tspan = (4500., 4500. - Δt)

# ╔═╡ 632c8864-c990-448a-ad6f-aeae2badc8c5
τ = [15, 12, 9, 6, 3]
#τ = [10, 8, 6, 5, 4, 3, 2]
#τ = Δt .÷ [1,2,3,6]

# ╔═╡ b4bfd914-d925-4c78-825a-a44d45bab358
prob = GDREProblem(E, A, B, C, X₀, tspan);

# ╔═╡ 8bd3d1ae-bf33-48a6-b34d-9cf3f9f83139
sol = map(τ) do dt
	solve(prob, Ros2(); dt=-dt)
end

# ╔═╡ 9e64ab71-537b-48ed-a009-9ab22e62ac65
# reverse colors to match natural rainbow, as smaller τs lead to smaller errors ;-)
colormap = reverse(to_colormap(:rainbow, length(τ)))

# ╔═╡ 5c52e6a2-a182-49e3-b449-3eaf9de71aeb
xticks = collect(4500:-50:4350) ∪ [4500-Δt]
#xticks = 4500-Δt:30:4500

# ╔═╡ 372d9a95-d017-49be-b13c-e2736351bf13
k(s) = [K[1, 71] for K in s.K]

# ╔═╡ 526f1959-80cb-4ab5-a25e-c724b6a62dcf
err(r, s) = norm(r-s) / norm(r)

# ╔═╡ 945c70d4-00c3-4054-8f7f-7de5e8b756cb
md"""
### Numerical Convergence Order LRSIF vs Dense

Of which order is the error between dense and low-rank solutions for the same step size $\tau$?
"""

# ╔═╡ 5e0ff842-23f0-42a6-af8a-f4c24ecf6cd1
order((η1, η2), (h1, h2)) = (log(η1) - log(η2)) / (log(h1) - log(h2))

# ╔═╡ 053804c2-e685-4ab9-b423-fd5d618bb7d0
md"""
This is odd. Hypotheses:

1. The error for $\tau \leq 1$ is due to numerical issues.
2. The error for $\tau > 1$ is due to an inconsistent initial value $E^{-T}C^TCE^{-1}$.
"""

# ╔═╡ 5f279843-6343-4936-98c0-e20b708e9903
md"""
### Numerical Convergence Order LRSIF vs Reference

Is the low-rank algorithm still of order 2?
"""

# ╔═╡ 848d3d47-8c00-42ba-854b-074dcbfdc3bf
#REF_lowrank = solve(prob, Ros2(); dt=-0.1);

# ╔═╡ 45da4e00-1b41-4dab-b95c-0a9ecc31f92b
md"""
## Dense Reference Solution

1. `ref`: same step size
2. `REF`: smallest step size
"""

# ╔═╡ 767e960e-fea0-4686-bd10-850a52882688
dX₀ = Matrix(X₀);

# ╔═╡ 3d4a2703-c64d-4ad6-8a54-d69c276015e0
dprob = GDREProblem(E, A, B, C, dX₀, tspan);

# ╔═╡ f8a6b16b-9750-49d7-94e4-fb27c8935c12
ref = map(τ) do dt
	solve(dprob, Ros2(); dt=-dt)
end

# ╔═╡ 68256a7a-7860-4277-9460-9de0f6b55449
err_same_τ = [err.(r.K, s.K) for (r, s) in zip(ref, sol)]

# ╔═╡ 9f3e7d01-0c4b-43d0-baa1-ed628fa8a9f2
mean_err_same_τ = @. sum(err_same_τ) / length(err_same_τ)

# ╔═╡ 7f4a7f7c-36da-432b-93f3-7f517265d33e
err_k_same_τ = map(ref, sol) do r, s
	kr = r.K[end]
	ks = s.K[end]
	err(kr, ks)
end

# ╔═╡ 925e19e8-2f30-45c1-bc0f-478af13d1c07
[order(err_k_same_τ[i:i+1], τ[i:i+1]) for i in 1:length(τ)-1]

# ╔═╡ 6a2505d6-f5cd-4bb7-aee7-e4c679808cd9
begin
	@assert gcd(τ) > 1 # accuracy should be strictly greater
	REF_dense = solve(dprob, Ros2(); dt=-1)
	#REF_dense = solve(dprob, Ros2(); dt=-gcd(τ)/2)
end

# ╔═╡ 4de32e34-f950-4e63-adc1-48a4b62eb0a8
REF = REF_dense
#REF = REF_lowrank

# ╔═╡ ade622d5-3bf8-4492-9371-4635f8a19c73
err_k_REF = map(sol) do s
	kr = REF.K[end]
	ks = s.K[end]
	err(kr, ks)
end

# ╔═╡ 2100737c-c9e2-469d-9067-d07cab8b6d81
[order(err_k_REF[i:i+1], τ[i:i+1]) for i in 1:length(τ)-1]

# ╔═╡ db323cd2-8f66-48e3-9bea-fc77ffc004be
md"Embedding of coarser solutions into `REF`:"

# ╔═╡ d273bd46-a9e0-4d51-9fb0-a3e162b2d668
ids = [findall(in(r.t), REF.t) for r in ref]

# ╔═╡ e174b510-d339-4b34-802f-60800f71a2cc
err_REF = [err.(REF.K[ids], s.K) for (ids, s) in zip(ids, sol)]

# ╔═╡ f3123299-653c-4360-8615-7efb0c6dd367
mean_err_REF = @. sum(err_REF) / length(err_REF)

# ╔═╡ 11093c5e-8531-4623-ad64-f62dc4da0cf8
err_REF_dense = [err.(REF.K[ids], r.K) for (ids, r) in zip(ids, ref)]

# ╔═╡ ba49b7c7-7227-4142-826b-48cf0d3b1635
mean_err_REF_dense = @. sum(err_REF_dense) / length(err_REF_dense)

# ╔═╡ 09603357-a80a-4565-95b5-3a8373766612
md"## Internal Stuff"

# ╔═╡ 5d1c0ff9-7c29-482e-b07a-b3c19c5552dd
utopia_regular = "/usr/local/texlive/2018/texmf-dist/fonts/type1/adobe/utopia/putr8a.pfb"

# ╔═╡ 4415a31c-5f7e-4360-9ba7-825ec428d538
fig_trajectory = let
	fig = Figure(font=utopia_regular)
	ax = Axis(
		fig[1,1],
		xlabel="Time",
		xticks = xticks,
		xtickformat = ticks -> map(t -> string(t/100, 's'), ticks),
	)

	for (i, (r, s)) in enumerate(zip(ref, sol))
		c = colormap[i]
		lines!(
			ax, r.t, k(r);
			color = c,
			linestyle = :dash,
		)
		lines!(
			ax, s.t, k(s);
			color = c,
			linestyle = :solid,
		)
	end

	elements = [
		[LineElement(linestyle=:solid), LineElement(linestyle=:dash)],
		[LineElement(color=c) for c in colormap],
	]
	descriptions = [
		["LRSIF", "Dense"],
		["$(10dt)ms" for dt in τ],
	]
	titles = [
		"Storage",
		"Step Size",
	]
	#=
	Legend(
		fig[1, 2],
		elements,
		descriptions,
		titles;
	)
	=#
	grid = fig[1,2] = GridLayout()
	Legend(
		grid[1,1],
		elements[1],
		descriptions[1],
		titles[1];
		width=Relative(1),
		#tellwidth = true,
	)
	Legend(
		grid[2,1],
		elements[2],
		descriptions[2],
		titles[2];
		#orientation = :horizontal,
		#nbanks = 2,
		labelhalign = :right,
		#tellwidth = true,
	)

	fig
end

# ╔═╡ 5543e59c-214c-4383-a57a-e15b2b9003d7
save(projectdir("thesis", "figures", "fig_ros2_K171.pdf"), fig_trajectory)

# ╔═╡ 90d09f69-a73b-4a36-a067-d7b0aa5fdb5f
fig_err_lowrank_v_ref = let
	fig = Figure(font=utopia_regular)

	es = 3:0.2:3.8
	ax = Axis(
		fig[1, 1],
		#title = L"Error in $K$"
		title = "Relative Error LRSIF vs Reference",
		xlabel = "Time",
		xticks = xticks,
		xtickformat = ticks -> map(t -> string(t/100, 's'), ticks),
		yscale=log10,
		#yticks = ([10^-e for e in es], ["1e-$e" for e in es]),
		#ytickformat=ticks -> map(t -> "1e$(log10(t))", ticks),
	)
	#ylims!(ax, 1e-4, 10^-2.8)

	for (i, (r, e, τ)) in enumerate(zip(ref, err_REF, τ))
		scatterlines!(
			ax,
			# skip zero at t=4500
			r.t[2:end],
			e[2:end];
			label="$(10τ)ms",
			color=colormap[i],
			markercolor=colormap[i], # for scatterlines
		)
	end

	Legend(
		fig[1, 2],
		ax,
		"Step Size";
		labelhalign=:right,
	)

	fig
end

# ╔═╡ 744c7efc-d316-4d98-b626-08bbaa017d10
save(
	projectdir("thesis", "figures", "fig_ros2_error_lorwank_v_ref.pdf"),
	fig_err_lowrank_v_ref
)

# ╔═╡ 66805547-9e29-470d-b2fd-72cd2c8f1ef4
fig_err_lowrank_v_dense = let
	fig = Figure(font=utopia_regular)

	es = 3:0.2:3.8
	ax = Axis(
		fig[1, 1],
		title = "Relative Error LRSIF vs Dense",
		xlabel = "Time",
		xticks = xticks,
		xtickformat = ticks -> map(t -> string(t/100, 's'), ticks),
		yscale=log10,
	)

	for (i, (r, e, τ)) in enumerate(zip(ref, err_same_τ, τ))
		scatterlines!(
			ax,
			# skip zero at t=4500
			r.t[2:end],
			e[2:end];
			label="$(10τ)ms",
			color=colormap[i],
			markercolor=colormap[i], # for scatterlines
		)
	end

	Legend(
		fig[1, 2],
		ax,
		"Step Size";
		labelhalign=:right,
	)

	fig
end

# ╔═╡ c24baf3f-a0c5-4dc2-9beb-564b7b543525
save(
	projectdir("thesis", "figures", "fig_ros2_error_lorwank_v_dense.pdf"),
	fig_err_lowrank_v_dense
)

# ╔═╡ dbca83fe-cc62-44ab-8bdc-72f560d083cc
fig_mean_err = let
	fig = Figure(font=utopia_regular)
	ax_REF = Axis(
		fig[1, 1],
		title = "Mean Relative Error",
		xticks = 3:3:15,
		yscale = log10,
	)
	ax_same_τ = Axis(
		fig[2, 1],
		xlabel = "Step Size",
		xticks = 3:3:15,
		xtickformat = ticks -> map(t -> "$(Int(10t))ms", ticks),
		yscale = log10,
	)
	hidexdecorations!(ax_REF, grid=false)
	linkxaxes!(ax_REF, ax_same_τ)
	
	scatter!(ax_REF, τ, mean_err_REF, label="LRSIF vs Refence")
	scatter!(ax_REF, τ, mean_err_REF_dense, label="Dense vs Refence")
	Legend(fig[1, 2], ax_REF)
	
	scatter!(ax_same_τ, τ, mean_err_same_τ, label="LRSIF vs Dense")
	Legend(fig[2, 2], ax_same_τ)

	fig
end

# ╔═╡ 400d2994-82f9-484e-b2a8-13d9761387c6
save(
	projectdir("thesis", "figures", "fig_ros2_mean_error.pdf"),
	fig_mean_err
)

# ╔═╡ 60b647dc-2335-4e64-944a-0ddd1285301b
fig_single_err = let
	fig = Figure(font=utopia_regular)
	ax = Axis(
		fig[1, 1],
		title = "Relative Error LRSIF vs Dense at $(tspan[2]/100)s",
		xlabel = "Step Size",
		xticks = 3:3:15,
		xtickformat = ticks -> map(t -> "$(Int(10t))ms", ticks),
		yscale = log10,
	)
	scatter!(τ, err_k_same_τ)
	fig
end

# ╔═╡ 6b36bbc4-1cb6-419d-b818-d5aa7e77905a
save(
	projectdir("thesis", "figures", "fig_ros2_single_error.pdf"),
	fig_single_err
)

# ╔═╡ Cell order:
# ╟─ef240f90-9efb-11ec-10ee-530b22c0c820
# ╠═71a022ca-a8bf-440a-afd5-def7308a3b64
# ╠═9154efc0-b80e-4f2e-81b1-0c12473ab05c
# ╠═b265c3c3-abca-49e1-9ef2-0839dfbd0f12
# ╠═b296e1f4-388f-4a46-a562-578392fd0d1d
# ╠═efdf19d3-f8f8-4c5c-9f81-991ab4c8de48
# ╠═632c8864-c990-448a-ad6f-aeae2badc8c5
# ╠═b4bfd914-d925-4c78-825a-a44d45bab358
# ╠═8bd3d1ae-bf33-48a6-b34d-9cf3f9f83139
# ╠═9e64ab71-537b-48ed-a009-9ab22e62ac65
# ╠═5c52e6a2-a182-49e3-b449-3eaf9de71aeb
# ╠═4415a31c-5f7e-4360-9ba7-825ec428d538
# ╠═5543e59c-214c-4383-a57a-e15b2b9003d7
# ╠═372d9a95-d017-49be-b13c-e2736351bf13
# ╠═90d09f69-a73b-4a36-a067-d7b0aa5fdb5f
# ╠═744c7efc-d316-4d98-b626-08bbaa017d10
# ╠═66805547-9e29-470d-b2fd-72cd2c8f1ef4
# ╠═c24baf3f-a0c5-4dc2-9beb-564b7b543525
# ╠═526f1959-80cb-4ab5-a25e-c724b6a62dcf
# ╠═e174b510-d339-4b34-802f-60800f71a2cc
# ╠═11093c5e-8531-4623-ad64-f62dc4da0cf8
# ╠═68256a7a-7860-4277-9460-9de0f6b55449
# ╠═dbca83fe-cc62-44ab-8bdc-72f560d083cc
# ╠═400d2994-82f9-484e-b2a8-13d9761387c6
# ╠═f3123299-653c-4360-8615-7efb0c6dd367
# ╠═ba49b7c7-7227-4142-826b-48cf0d3b1635
# ╠═9f3e7d01-0c4b-43d0-baa1-ed628fa8a9f2
# ╟─945c70d4-00c3-4054-8f7f-7de5e8b756cb
# ╠═60b647dc-2335-4e64-944a-0ddd1285301b
# ╠═6b36bbc4-1cb6-419d-b818-d5aa7e77905a
# ╠═7f4a7f7c-36da-432b-93f3-7f517265d33e
# ╠═5e0ff842-23f0-42a6-af8a-f4c24ecf6cd1
# ╠═925e19e8-2f30-45c1-bc0f-478af13d1c07
# ╟─053804c2-e685-4ab9-b423-fd5d618bb7d0
# ╟─5f279843-6343-4936-98c0-e20b708e9903
# ╠═848d3d47-8c00-42ba-854b-074dcbfdc3bf
# ╠═ade622d5-3bf8-4492-9371-4635f8a19c73
# ╠═2100737c-c9e2-469d-9067-d07cab8b6d81
# ╟─45da4e00-1b41-4dab-b95c-0a9ecc31f92b
# ╠═767e960e-fea0-4686-bd10-850a52882688
# ╠═3d4a2703-c64d-4ad6-8a54-d69c276015e0
# ╠═f8a6b16b-9750-49d7-94e4-fb27c8935c12
# ╠═6a2505d6-f5cd-4bb7-aee7-e4c679808cd9
# ╠═4de32e34-f950-4e63-adc1-48a4b62eb0a8
# ╟─db323cd2-8f66-48e3-9bea-fc77ffc004be
# ╠═d273bd46-a9e0-4d51-9fb0-a3e162b2d668
# ╠═09603357-a80a-4565-95b5-3a8373766612
# ╠═0a0bdf35-d54d-44ab-97a1-73550d330162
# ╠═2b573699-e746-427b-928d-34bd3a40aa2f
# ╠═3e3e15c0-c1ed-45df-8864-9e0126b7f308
# ╠═4c3a03a6-2e72-4f39-a820-e63aa867f152
# ╠═b507b89f-1676-4223-9e49-5d1d0815f7c5
# ╠═7d192450-db4e-4c2d-aabb-98d09214d592
# ╠═5d1c0ff9-7c29-482e-b07a-b3c19c5552dd
