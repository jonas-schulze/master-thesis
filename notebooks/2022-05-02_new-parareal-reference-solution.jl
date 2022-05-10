### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ 1a57a1e1-b72a-4228-a894-f3531e546015
using DrWatson

# ╔═╡ bb2b54c0-066f-4674-bc45-e50ccfa8006c
using Revise

# ╔═╡ c885f51d-87c7-48c6-84cc-d18f85e5dc11
using StatsBase

# ╔═╡ e2fa291c-8ee2-44d9-abfc-c3316a587967
using Stuff

# ╔═╡ a672d1dd-09dd-442e-82e8-00a98594d9df
@quickactivate

# ╔═╡ 369bd842-4419-4119-93e4-d9f29ff166db
using PlutoUI

# ╔═╡ 488409d0-b24f-45ba-920d-2036985a3afc
using CairoMakie

# ╔═╡ f4a4852e-ca18-11ec-1924-c95dd07b09b8
md"""
# New Parareal Reference Solution

Figure 7.7 in the thesis used a dense order 4/4 parareal reference solution.
This was lazy.
In order to actually evaluate the effectiveness of the parareal implementation,
the reference solution should have been a sequentially computed one.
"""

# ╔═╡ 90615025-0bbb-4be8-8bd0-f454cbb27f4e
md"""
Apparently, the difference is negligible.
"""

# ╔═╡ 5adf9a54-bb09-4bbc-b215-21aaf40f2520
md"""
## Error Plot

A line plot contains a lot of high-frequency information,
which isn't really visable to the human eye anyways.
Unfortunately, though, a band plot of rolling maximum/minimum does not show the zero-error for $t>43.9 s$.
"""

# ╔═╡ bfcca0a0-36da-4561-b63c-96c6b2d74adc
window = 100

# ╔═╡ 367e9814-3c4f-4b2c-8c13-e53bbdd9b44e
#save("err_band.pdf", fig_band)

# ╔═╡ ada2e247-e8fa-412a-b854-5843f605a44c
#save("err_lines.pdf", fig_lines)

# ╔═╡ b994bfef-3203-47c4-8454-af9e808e16d5
Δt = 0.1

# ╔═╡ 5df91b7b-fa44-42b9-acb1-6b071487f6dc
#t = 0:Δt:4500-1100Δt
t = 0:Δt:4500

# ╔═╡ 400312db-e61f-4174-b1a8-da9b17f914af
function rolling(f, x, n)
	len = length(x)
	y = similar(x)
	for i in 1:n
		y[i] = f(@view x[1:i+n])
		y[end-i+1] = f(@view x[end-i+1-n:end])
	end
	for i in n+1:len-n
		y[i] = f(@view x[i-n:i+n])
	end
	y
end

# ╔═╡ 69655ae5-d897-47a4-a4b8-500aba1c81f6
md"""
## Find Datasets

To perform the following analysis locally,
I copied the new reference solution without the state/`X` trajectory.
Hence the `.nox` suffix.
"""

# ╔═╡ 69b9d117-148c-4806-93f0-e4294fc2c3e1
fname_new = datadir(
	"dense-seq",
	savename("rail371-dense", (ncpus=1, nsteps=45000, order=4), "h5.nox")
)

# ╔═╡ f8145a0b-0632-4f5f-bbc9-415895f455c0
fname_old = datadir(
	"dense-par",
	savename(
		"rail371-dense",
		(
			jobid=351270,
			ncpus=1,
			nstages=450,
			nc=1, nf=100,
			of=4, oc=4,
			wc=true, wf=false
		),
		"h5.nox"
	)
)

# ╔═╡ ff9d154b-1595-4ba9-9927-3e4c850f5bbb
err = δ(fname_old, fname_new, "K")

# ╔═╡ 8156f352-8e3d-4a9a-8625-d9d1c323835f
findmax(err)

# ╔═╡ d89aa3f1-c4d0-403d-ba4b-d961af0c6989
maximum(err) / eps()

# ╔═╡ 7c79b92e-91f4-4dd2-9187-916be74e196b
e = [err["t=$t"] for t in t]

# ╔═╡ 6d9eb94f-5455-49b4-97a6-b6107d10ba0e
fig_band = let
	fig_band = band(
		t,
		rolling(minimum, e, window),
		rolling(maximum, e, window),
		axis = (; xtime...),
		#color=:blue,
	)
	fig_band
end

# ╔═╡ 734f0b08-0409-4904-bb71-41ff3e71834c
rolling(mean, e, window)

# ╔═╡ 979c6262-a21b-4936-b275-1dd84b5b7135
fig_lines = let
	fig = Figure(resolution=(500,300))
	ax = Axis(
		fig[1,1];
		#title="Relative Error",
		xtime...,
	)
	lines!(ax, t, e)
	#hlines!(ax, eps())
	fig
end

# ╔═╡ bd1581ff-dc7e-44bf-9174-d94d52751a9c
save(projectdir("thesis", "figures", "slides-seq-parareal-ref.pdf"), fig_lines)

# ╔═╡ 27c2c441-3bb2-4456-be08-363eb31a6e1e
@assert isfile(fname_new)

# ╔═╡ d93fcfda-eb10-410b-a79a-fdb5d1ee591c
@assert isfile(fname_old)

# ╔═╡ 35f1f3bd-b84d-41c0-83db-40c42f8f68ee
md"# Internal"

# ╔═╡ 150fd89f-0443-401a-b49d-ffccee076177
TableOfContents()

# ╔═╡ Cell order:
# ╟─f4a4852e-ca18-11ec-1924-c95dd07b09b8
# ╠═ff9d154b-1595-4ba9-9927-3e4c850f5bbb
# ╠═8156f352-8e3d-4a9a-8625-d9d1c323835f
# ╠═d89aa3f1-c4d0-403d-ba4b-d961af0c6989
# ╟─90615025-0bbb-4be8-8bd0-f454cbb27f4e
# ╟─5adf9a54-bb09-4bbc-b215-21aaf40f2520
# ╠═bfcca0a0-36da-4561-b63c-96c6b2d74adc
# ╠═6d9eb94f-5455-49b4-97a6-b6107d10ba0e
# ╠═734f0b08-0409-4904-bb71-41ff3e71834c
# ╠═367e9814-3c4f-4b2c-8c13-e53bbdd9b44e
# ╠═979c6262-a21b-4936-b275-1dd84b5b7135
# ╠═ada2e247-e8fa-412a-b854-5843f605a44c
# ╠═bd1581ff-dc7e-44bf-9174-d94d52751a9c
# ╠═b994bfef-3203-47c4-8454-af9e808e16d5
# ╠═5df91b7b-fa44-42b9-acb1-6b071487f6dc
# ╠═7c79b92e-91f4-4dd2-9187-916be74e196b
# ╠═c885f51d-87c7-48c6-84cc-d18f85e5dc11
# ╠═400312db-e61f-4174-b1a8-da9b17f914af
# ╟─69655ae5-d897-47a4-a4b8-500aba1c81f6
# ╠═69b9d117-148c-4806-93f0-e4294fc2c3e1
# ╠═f8145a0b-0632-4f5f-bbc9-415895f455c0
# ╠═27c2c441-3bb2-4456-be08-363eb31a6e1e
# ╠═d93fcfda-eb10-410b-a79a-fdb5d1ee591c
# ╟─35f1f3bd-b84d-41c0-83db-40c42f8f68ee
# ╠═1a57a1e1-b72a-4228-a894-f3531e546015
# ╠═bb2b54c0-066f-4674-bc45-e50ccfa8006c
# ╠═a672d1dd-09dd-442e-82e8-00a98594d9df
# ╠═e2fa291c-8ee2-44d9-abfc-c3316a587967
# ╠═369bd842-4419-4119-93e4-d9f29ff166db
# ╠═150fd89f-0443-401a-b49d-ffccee076177
# ╠═488409d0-b24f-45ba-920d-2036985a3afc
