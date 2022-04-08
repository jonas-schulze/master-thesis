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

# ╔═╡ f44cfe1d-0b27-45d9-89b4-fdd82f883daf
using DrWatson

# ╔═╡ f55006d9-2d82-4d4c-9b22-b606d992d425
@quickactivate

# ╔═╡ 84fb4f59-26ae-47ed-b5d0-07fb5e22ab51
using PlutoUI

# ╔═╡ 9132a112-c7cf-452b-bbcf-038988c28aed
using DifferentialEquations

# ╔═╡ 23f6bcbe-e019-493b-84ea-48827ee9d623
using CairoMakie

# ╔═╡ 6268571e-cc52-4040-ad08-cb28baa86195
using ParaReal

# ╔═╡ a7ad3e6e-3de5-4830-85a5-a6b50812e9ec
using ParaReal: value, solution

# ╔═╡ 171296b3-3011-48bc-9258-dcde5c4b70cf
using Distributed: myid

# ╔═╡ 54d0a8ae-6eb7-4024-8544-56e1bb085325
md"""
# Golden Spiral

The points $(r,\theta)$ on a golden spiral are described by $r = \phi^{2\theta/\pi}$,
where $\phi$ denotes the golden ratio.
"""

# ╔═╡ f4723cd5-4590-40a6-8197-3acbe259b178
ϕ = (1+√5)/2

# ╔═╡ feabedcb-01e1-4d5d-a2ac-a22b4d2a46b1
md"""
Translated into cartesian coordinates:

```math
\begin{align}
x &= e^{k\theta} \cos\theta \\
y &= e^{k\theta} \sin\theta
\end{align}
```

where $k=\frac{2}{\pi} \log\phi$.
"""

# ╔═╡ 613a261f-bf37-4870-b2c2-973d80360af9
k = 2/π * log(ϕ)

# ╔═╡ 26a7b2a7-01c6-4cc9-81f1-b8adf84eb7b7
md"""
## ODE

Take the derivative of $x$ and $y$ w.r.t. $\theta$ to obtain
```math
\begin{align}
x' &= kx - y \\
y' &= ky + x
\end{align}
```
"""

# ╔═╡ 98e58fcb-684f-49ac-9597-12db872bb856
md"""
To get some nice-looking boundary values, let $x' = 0$,
i.e. $y = kx$.
"""

# ╔═╡ c9a22fcb-a767-4ae1-85b4-e21afead7995
function spiral!(du, u, p, t)
	k = p
	x, y = u
	du[1] = k*x - y
	du[2] = k*y + x
	nothing
end

# ╔═╡ b0fa6315-7a34-49b8-a0fb-35c5f4494bc1
u0 = [-1.0, -k]

# ╔═╡ 99935c22-9cdd-467d-b3bf-e20171c58967
tspan = (0., 2π)

# ╔═╡ 6ea41288-b1c1-4a3d-8670-b735d3e88d40
prob = ODEProblem(spiral!, u0, tspan, k)

# ╔═╡ bcbbdab8-4497-4a74-a2c4-5fc1593836da
ref = solve(prob);

# ╔═╡ e8f7eb3d-0f50-4cca-8214-d67717e124cd
let
	fig = Figure()

	ax = Axis(fig[1, 1])
	ax.aspect = DataAspect()
	# alternative: ax.autolimitaspect = 1

	ax.xticks = -6:2:3
	ax.yticks = -2:2:4

    ts = range(tspan...; length=100)
	points = [Point2f(ref(t)) for t in ts]
    lines!(ax, points)

	fig
end

# ╔═╡ 333c67ce-1f83-4209-b101-f4611505ec0b
md"""
## Parareal
"""

# ╔═╡ 661b806f-9d59-41bb-bd8a-91c69b515fba
N = 5

# ╔═╡ 18f7d37a-3feb-4833-b708-a8a1af4db1e7
Ks = 0:3

# ╔═╡ 81786ab5-2835-404c-942d-1394bfea557a
τ = tspan[2] / N

# ╔═╡ 139e8d08-e79f-4c4f-9b27-ffe5af44f850
csolve(prob) = solve(prob, ImplicitEuler(); dt=τ, adaptive=false)

# ╔═╡ fcd8bdae-755a-4340-8634-66699b2f4c1a
fsolve(prob) = solve(prob, ImplicitEuler(); dt=τ/100, adaptive=false)

# ╔═╡ d88ad751-b699-4298-a753-c55e4f228293
@bind _colormap Select([:rainbow, :sun, :viridis], default=:rainbow)

# ╔═╡ 40ae0661-ae75-4b9a-be97-4d6bbcf453c7
function plot_spiral!(ax, sol, colors)
	#ax.aspect = DataAspect()
	ax.autolimitaspect = 1
	ax.xticks = -8:2:4
	ax.yticks = -2:2:4

	# Reference Solution:
    ts = range(tspan...; length=100)
	points = [Point2f(ref(t)) for t in ts]
    lines!(ax, points, color=:gray, linestyle=:dash)

	for (n, stage) in enumerate(sol.stages)
		# Fine Solutions:
		s = solution(stage)
		points = Point2f.(s.u)
		lines!(ax, points, label="$n", color=colors[n])
		# Parareal Values:
		v = value(stage)
		scatter!(ax, Point2f(v), color=colors[n])
	end
end

# ╔═╡ b1819bde-fa19-4920-b785-1efc7c4d95fc
md"## Internal Stuff"

# ╔═╡ 5e04b985-c5d2-41b2-8866-1b0780e845eb
md"As Pluto is based on Distributed, use `myid` instead of `1` to identify the current process."

# ╔═╡ d868c793-8561-4447-9537-32ba92b42df0
schedule = ProcessesSchedule(fill(myid(), N))

# ╔═╡ 6f8c586f-903a-4753-beb8-e874b0e77d87
sol = [solve(
	ParaReal.Problem(prob),
	ParaReal.Algorithm(csolve, fsolve);
	schedule,
	maxiters=K,
) for K in Ks]

# ╔═╡ 738d5554-dd27-4df6-92aa-e436858fa9f8
Dict(K => [s.k for s in sol[1+K].stages] for K in Ks)

# ╔═╡ 0376e21c-eafa-40bd-a937-b64792942950
utopia_regular = "/usr/local/texlive/2018/texmf-dist/fonts/type1/adobe/utopia/putr8a.pfb"

# ╔═╡ beb3da79-0b27-432a-a457-f98db0536e58
colors = to_colormap(_colormap, N)

# ╔═╡ 9aba5153-1158-4e17-bdff-e100006e8d9d
fig = let
	fig = Figure(font=utopia_regular)
	grid = fig[1, 1] = GridLayout()
	ax = [Axis(grid[i, j]) for i in 1:2, j in 1:2]

	hidexdecorations!.(ax[1,:], grid=false)
	hideydecorations!.(ax[:,2], grid=false)

	for (k, K) in enumerate(Ks)
		ax[k].title = "Refinement $K"
		plot_spiral!(ax[k], sol[k], colors)
	end

	Legend(
		fig[2, 1],
		ax[1],
		"Parareal Stage"; # or nothing or "n"
		orientatio = :horizontal,
		nbanks = N,
		tellwidth=false,
		tellheight=true,
	)

	#resize_to_layout!(fig) # needs Makie v0.16
	fig
end

# ╔═╡ ddffb4f3-bfa9-4bea-8ce4-ed243306242e
save(projectdir("thesis", "figures", "fig_parareal_example.pdf"), fig)

# ╔═╡ Cell order:
# ╟─54d0a8ae-6eb7-4024-8544-56e1bb085325
# ╠═f4723cd5-4590-40a6-8197-3acbe259b178
# ╟─feabedcb-01e1-4d5d-a2ac-a22b4d2a46b1
# ╠═613a261f-bf37-4870-b2c2-973d80360af9
# ╟─26a7b2a7-01c6-4cc9-81f1-b8adf84eb7b7
# ╟─98e58fcb-684f-49ac-9597-12db872bb856
# ╠═c9a22fcb-a767-4ae1-85b4-e21afead7995
# ╠═b0fa6315-7a34-49b8-a0fb-35c5f4494bc1
# ╠═99935c22-9cdd-467d-b3bf-e20171c58967
# ╠═6ea41288-b1c1-4a3d-8670-b735d3e88d40
# ╠═bcbbdab8-4497-4a74-a2c4-5fc1593836da
# ╠═e8f7eb3d-0f50-4cca-8214-d67717e124cd
# ╠═333c67ce-1f83-4209-b101-f4611505ec0b
# ╠═661b806f-9d59-41bb-bd8a-91c69b515fba
# ╠═18f7d37a-3feb-4833-b708-a8a1af4db1e7
# ╠═81786ab5-2835-404c-942d-1394bfea557a
# ╠═139e8d08-e79f-4c4f-9b27-ffe5af44f850
# ╠═fcd8bdae-755a-4340-8634-66699b2f4c1a
# ╠═6f8c586f-903a-4753-beb8-e874b0e77d87
# ╠═738d5554-dd27-4df6-92aa-e436858fa9f8
# ╠═d88ad751-b699-4298-a753-c55e4f228293
# ╠═9aba5153-1158-4e17-bdff-e100006e8d9d
# ╠═ddffb4f3-bfa9-4bea-8ce4-ed243306242e
# ╠═40ae0661-ae75-4b9a-be97-4d6bbcf453c7
# ╠═b1819bde-fa19-4920-b785-1efc7c4d95fc
# ╠═f44cfe1d-0b27-45d9-89b4-fdd82f883daf
# ╠═f55006d9-2d82-4d4c-9b22-b606d992d425
# ╠═84fb4f59-26ae-47ed-b5d0-07fb5e22ab51
# ╠═9132a112-c7cf-452b-bbcf-038988c28aed
# ╠═23f6bcbe-e019-493b-84ea-48827ee9d623
# ╠═6268571e-cc52-4040-ad08-cb28baa86195
# ╠═a7ad3e6e-3de5-4830-85a5-a6b50812e9ec
# ╟─5e04b985-c5d2-41b2-8866-1b0780e845eb
# ╠═171296b3-3011-48bc-9258-dcde5c4b70cf
# ╠═d868c793-8561-4447-9537-32ba92b42df0
# ╠═0376e21c-eafa-40bd-a937-b64792942950
# ╠═beb3da79-0b27-432a-a457-f98db0536e58
