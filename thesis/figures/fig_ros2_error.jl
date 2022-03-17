### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ 0a0bdf35-d54d-44ab-97a1-73550d330162
using DrWatson

# ╔═╡ 2b573699-e746-427b-928d-34bd3a40aa2f
@quickactivate

# ╔═╡ 0c20c810-0880-46ed-ad94-65378bf72144
using Stuff: xstepsize

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
# Numerical Issues of Low-Rank Ros(2)
"""

# ╔═╡ 71a022ca-a8bf-440a-afd5-def7308a3b64
let
	P = matread(datadir("Rail371.mat"))
	global E, A, B, C
	@unpack E, A, B, C = P
end;

# ╔═╡ 46cdcaa0-bb8f-4d77-b7cf-3b8004bcf8c3
md"## Error After One Step"

# ╔═╡ 9154efc0-b80e-4f2e-81b1-0c12473ab05c
q = size(C, 1)

# ╔═╡ b265c3c3-abca-49e1-9ef2-0839dfbd0f12
X₀ = LDLᵀ(E\(C'), sparse(I(q)/100))

# ╔═╡ 767e960e-fea0-4686-bd10-850a52882688
dX₀ = Matrix(X₀);

# ╔═╡ 632c8864-c990-448a-ad6f-aeae2badc8c5
τ = 10.0 .^ (-1:0.1:1)

# ╔═╡ a7fc81d5-1f67-48d3-9cec-f7393cb09503
prob = map(τ) do Δt
	tspan = (4500., 4500-Δt)
	GDREProblem(E, A, B, C, X₀, tspan)
end;

# ╔═╡ 3d4a2703-c64d-4ad6-8a54-d69c276015e0
dprob = map(τ) do Δt
	tspan = (4500., 4500-Δt)
	GDREProblem(E, A, B, C, dX₀, tspan)
end;

# ╔═╡ 8bd3d1ae-bf33-48a6-b34d-9cf3f9f83139
sol = map(prob, τ) do p, dt
	solve(p, Ros2(); dt=-dt)
end

# ╔═╡ f8a6b16b-9750-49d7-94e4-fb27c8935c12
ref = map(dprob, τ) do p, dt
	solve(p, Ros2(); dt=-dt)
end

# ╔═╡ 3cd7a706-c08f-4588-b374-d3b5e9eed48c
K = [s.K[end] for s in sol]

# ╔═╡ 4e328b5b-941f-449d-af4e-21f15c6f8d19
dK = [s.K[end] for s in ref]

# ╔═╡ 526f1959-80cb-4ab5-a25e-c724b6a62dcf
err = @. norm(K - dK) / norm(dK)

# ╔═╡ bee52558-f437-48fc-9fd9-05ecf13bf583
md"""
## TODO/Ideas

* error after 1, 10, 100 steps
* error over time, e.g. [44,45] seconds
"""

# ╔═╡ f4f802ac-9cb1-4d27-8251-10d5d7c49426
nsteps = 5

# ╔═╡ b1ae5a56-9d9c-4f79-aa63-5a5a4011d3e1
function solve_n_steps(X0, n, Δt)
	tspan = (4500., 4500. - n*Δt)
	prob = GDREProblem(E, A, B, C, X0, tspan)
	solve(prob, Ros2(); dt=-Δt)
end

# ╔═╡ ec674e57-978f-4496-b351-3fbed28a0c74
sol2 = [solve_n_steps(X₀, nsteps, Δt) for Δt in τ];

# ╔═╡ f1d758ad-f137-464d-b33a-d4bfaaf5efd5
ref2 = [solve_n_steps(dX₀, nsteps, Δt) for Δt in τ];

# ╔═╡ 846372e8-d9b1-4e3f-8ce0-39a9b248c56b
K2 = [s.K for s in sol2];

# ╔═╡ bf2a7213-dd5d-42de-9d42-919fcd11c57b
dK2 = [s.K for s in ref2];

# ╔═╡ 8438b99c-51c8-4ad2-8876-8072a80108eb
e(r, s) = norm(r-s) / norm(r)

# ╔═╡ 87fc72a5-6cb7-43d7-81c7-72c34024e97d
err2 = [e(Kτ[1+n], dKτ[1+n]) for (Kτ, dKτ) in zip(K2, dK2), n in 1:nsteps]

# ╔═╡ 042bb5b4-c37b-49b4-b664-5ffa7e4b8dcf
colormap = reverse(to_colormap(:rainbow, nsteps))

# ╔═╡ 09603357-a80a-4565-95b5-3a8373766612
md"## Internal Stuff"

# ╔═╡ 5d1c0ff9-7c29-482e-b07a-b3c19c5552dd
utopia_regular = "/usr/local/texlive/2018/texmf-dist/fonts/type1/adobe/utopia/putr8a.pfb"

# ╔═╡ 66805547-9e29-470d-b2fd-72cd2c8f1ef4
fig_err1step = let
	fig = Figure(font=utopia_regular)

	ax = Axis(
		fig[1, 1];
		title = "Relative Error LRSIF vs Dense",
		xstepsize...,
		xticks = [0.1, 1, 10],
		xminorticks = (0.1:0.1:1) ∪ (2:10),
		xminorgridvisible = true,
		yscale=log10,
		xscale=log10,
	)

	scatter!(ax, τ, err)

	fig
end

# ╔═╡ c24baf3f-a0c5-4dc2-9beb-564b7b543525
save(
	projectdir("thesis", "figures", "fig_ros2_error1step.pdf"),
	fig_err1step
)

# ╔═╡ c577e971-5014-4ce1-9f95-a2d041a8a7f6
fig_err2 = let
	fig = Figure(font=utopia_regular)

	ax = Axis(
		fig[1, 1];
		title = "Relative Error LRSIF vs Dense",
		xstepsize...,
		#ytickformat = ticks -> map(t -> "1e$(log10(t))", ticks),
		xticks = [0.1, 1, 10],
		#xminorticks = (0.1:0.1:1) ∪ (2:10),
		#xminorgridvisible = true,
		yscale=log10,
		xscale=log10,
	)

	for n in 1:nsteps
		scatterlines!(
			ax, τ, err2[:,n];
			label="$n",
			color=colormap[n],
			markercolor=colormap[n],
		)
	end

	Legend(
		fig[2,1],
		ax,
		"Number of Steps";
		tellwidth=false,
		tellheight=true,
		orientation=:horizontal,
	)

	fig
end

# ╔═╡ 7d03fdfa-fb3b-47b4-b85e-126bd24e61f2
save(
	projectdir("thesis", "figures", "fig_ros2_error2.pdf"),
	fig_err2
)

# ╔═╡ 5e0ff842-23f0-42a6-af8a-f4c24ecf6cd1
order((η1, η2), (h1, h2)) = (log(η1) - log(η2)) / (log(h1) - log(h2))

# ╔═╡ Cell order:
# ╟─ef240f90-9efb-11ec-10ee-530b22c0c820
# ╠═71a022ca-a8bf-440a-afd5-def7308a3b64
# ╟─46cdcaa0-bb8f-4d77-b7cf-3b8004bcf8c3
# ╠═9154efc0-b80e-4f2e-81b1-0c12473ab05c
# ╠═b265c3c3-abca-49e1-9ef2-0839dfbd0f12
# ╠═767e960e-fea0-4686-bd10-850a52882688
# ╠═632c8864-c990-448a-ad6f-aeae2badc8c5
# ╠═a7fc81d5-1f67-48d3-9cec-f7393cb09503
# ╠═3d4a2703-c64d-4ad6-8a54-d69c276015e0
# ╠═8bd3d1ae-bf33-48a6-b34d-9cf3f9f83139
# ╠═f8a6b16b-9750-49d7-94e4-fb27c8935c12
# ╠═66805547-9e29-470d-b2fd-72cd2c8f1ef4
# ╠═c24baf3f-a0c5-4dc2-9beb-564b7b543525
# ╠═3cd7a706-c08f-4588-b374-d3b5e9eed48c
# ╠═4e328b5b-941f-449d-af4e-21f15c6f8d19
# ╠═526f1959-80cb-4ab5-a25e-c724b6a62dcf
# ╟─bee52558-f437-48fc-9fd9-05ecf13bf583
# ╠═f4f802ac-9cb1-4d27-8251-10d5d7c49426
# ╠═b1ae5a56-9d9c-4f79-aa63-5a5a4011d3e1
# ╠═ec674e57-978f-4496-b351-3fbed28a0c74
# ╠═f1d758ad-f137-464d-b33a-d4bfaaf5efd5
# ╠═846372e8-d9b1-4e3f-8ce0-39a9b248c56b
# ╠═bf2a7213-dd5d-42de-9d42-919fcd11c57b
# ╠═8438b99c-51c8-4ad2-8876-8072a80108eb
# ╠═87fc72a5-6cb7-43d7-81c7-72c34024e97d
# ╠═c577e971-5014-4ce1-9f95-a2d041a8a7f6
# ╠═7d03fdfa-fb3b-47b4-b85e-126bd24e61f2
# ╠═042bb5b4-c37b-49b4-b664-5ffa7e4b8dcf
# ╠═09603357-a80a-4565-95b5-3a8373766612
# ╠═0a0bdf35-d54d-44ab-97a1-73550d330162
# ╠═2b573699-e746-427b-928d-34bd3a40aa2f
# ╠═0c20c810-0880-46ed-ad94-65378bf72144
# ╠═3e3e15c0-c1ed-45df-8864-9e0126b7f308
# ╠═4c3a03a6-2e72-4f39-a820-e63aa867f152
# ╠═b507b89f-1676-4223-9e49-5d1d0815f7c5
# ╠═7d192450-db4e-4c2d-aabb-98d09214d592
# ╠═5d1c0ff9-7c29-482e-b07a-b3c19c5552dd
# ╠═5e0ff842-23f0-42a6-af8a-f4c24ecf6cd1
