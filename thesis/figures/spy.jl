### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ 45054a6a-9fb9-11ec-04e6-15d416beda65
using DrWatson

# ╔═╡ 4493fc49-e030-4eb6-a7ac-b4b120fdedf0
@quickactivate

# ╔═╡ 91ce0a38-0465-4c12-bc1a-50f27ffd03fc
using MAT

# ╔═╡ e60cd084-57df-4d2f-9b00-4a4b9146668e
using CairoMakie

# ╔═╡ 3c25547f-741c-4a65-95be-654d451d8c87
using SparseArrays

# ╔═╡ f2b40253-bea0-4d64-8193-4fbd927dc3ab
md"""
# Sparcity Pattern of Steel Profile
## E
"""

# ╔═╡ 3cb4d99f-e248-490c-a158-6e9d0a0fdbb3
md"## A"

# ╔═╡ 8bb9c1af-1d1c-44f3-9bc5-a09f5236d9ec
md"## B"

# ╔═╡ 9f47d364-8619-453c-997b-5fd8f1fb7181
md"## Internal Stuff"

# ╔═╡ 4c2995d8-c6c8-4a5e-a733-8a36f4b0afd0
utopia_italics = "/usr/local/texlive/2018/texmf-dist/fonts/type1/adobe/utopia/putri8a.pfb"

# ╔═╡ 75e0fcf2-3b1a-49f9-9d5d-c0669ff14811
begin
	P = matread(datadir("Rail371.mat"))
	@unpack E, A, B, C = P
end;

# ╔═╡ d8d1d74b-1998-428b-a588-cc22b413f5dc
size(B)

# ╔═╡ f0a4b85c-9963-4bdf-9ccf-d0a5ce3a4134
findall(!iszero, A) ⊆ findall(!iszero, E)

# ╔═╡ 4f9b5b7e-e43e-4ab5-952e-e0fc496a8faa
nnz(E) - nnz(A)

# ╔═╡ 28f98086-b8a3-4144-8328-857e8a0e6bc7
function spy(X)
	m, n = size(X)
	fig = Figure(
		figure_padding = 0,
		resolution = (n+1, m+1),
	)

	ax = Axis(
		fig[1,1],
		#yreversed = true,
		aspect = DataAspect(),
	)
	hidedecorations!(ax)
	hidespines!(ax)
	xlims!(ax, 0, n+1)
	ylims!(ax, m+1, 0)

	lines!(
		Rect2f((0.5,0.5), (n, m));
		color = :lightgray,
		linewidth = 1,
	)

	I, J, _ = findnz(X)
	scatter!(ax, J, I;
		color=:black,
		markersize=1,
	)

	fig
end

# ╔═╡ 2940bec3-6873-48a9-a717-7d9935145489
spy_E = spy(E)

# ╔═╡ ca788728-d7a2-4e86-a463-5b69f8e15898
save(projectdir("thesis", "figures", "spy_E.pdf"), spy_E)

# ╔═╡ 0614fdc9-beb0-4799-b729-8c2b160182b2
spy_A = spy(A)

# ╔═╡ f47a8f40-0610-4a15-a9ed-87fa885e6018
save(projectdir("thesis", "figures", "spy_A.pdf"), spy_A)

# ╔═╡ ce1d4f96-11e9-4d60-a1aa-6d14dd579896
#spy_B = spy(sparse(C))
spy_B = spy(B)

# ╔═╡ 41171928-cd87-40a3-af56-77888280829b
save(projectdir("thesis", "figures", "spy_B.pdf"), spy_B)

# ╔═╡ fba537c7-781d-4a26-9a50-7b8a2bf54e81
function spy!(ax, X)
	m, n = size(X)
	#ax.aspect = DataAspect()
	hidedecorations!(ax)
	hidespines!(ax)
	xlims!(ax, 0, n+1)
	ylims!(ax, m+1, 0)

	lines!(
		ax,
		Rect2f((0.5,0.5), (n, m));
		color = :lightgray,
		linewidth = 1,
	)

	I, J, _ = findnz(X)
	scatter!(ax, J, I;
		color=:black,
		markersize=1,
	)

	return
end

# ╔═╡ 0d52e800-ab33-4445-9974-44d28cbb1868
function resize_to_layout!(fig::Figure)
    bbox = Makie.GridLayoutBase.tight_bbox(fig.layout)
    new_size = (widths(bbox)...,)
    resize!(fig.scene, widths(bbox)...)
    new_size
end

# ╔═╡ f943e03f-5a21-451f-ab76-a6e43bde72a6
let
	fig = Figure(
		font = utopia_italics,
		figure_padding = 0,
		#background_color = :transparent,
	)
	axs = [
		Axis(fig[1,1], height=371, width=371),
		Axis(fig[2,1], height=size(C, 1), width=371),
		Axis(fig[1,2], height=371, width=size(B, 2)),
	]
	spy!(axs[1], A)
	spy!(axs[2], sparse(C))
	spy!(axs[3], B)
	linkxaxes!(axs[1], axs[2])
	linkyaxes!(axs[1], axs[3])

    resize_to_layout!(fig)
	
	save(projectdir("thesis", "figures", "spy_ABC.pdf"), fig)
	fig
end

# ╔═╡ Cell order:
# ╟─f2b40253-bea0-4d64-8193-4fbd927dc3ab
# ╠═2940bec3-6873-48a9-a717-7d9935145489
# ╠═ca788728-d7a2-4e86-a463-5b69f8e15898
# ╟─3cb4d99f-e248-490c-a158-6e9d0a0fdbb3
# ╠═0614fdc9-beb0-4799-b729-8c2b160182b2
# ╠═f47a8f40-0610-4a15-a9ed-87fa885e6018
# ╠═8bb9c1af-1d1c-44f3-9bc5-a09f5236d9ec
# ╠═ce1d4f96-11e9-4d60-a1aa-6d14dd579896
# ╠═41171928-cd87-40a3-af56-77888280829b
# ╠═d8d1d74b-1998-428b-a588-cc22b413f5dc
# ╠═f943e03f-5a21-451f-ab76-a6e43bde72a6
# ╠═f0a4b85c-9963-4bdf-9ccf-d0a5ce3a4134
# ╠═4f9b5b7e-e43e-4ab5-952e-e0fc496a8faa
# ╟─9f47d364-8619-453c-997b-5fd8f1fb7181
# ╠═45054a6a-9fb9-11ec-04e6-15d416beda65
# ╠═4493fc49-e030-4eb6-a7ac-b4b120fdedf0
# ╠═4c2995d8-c6c8-4a5e-a733-8a36f4b0afd0
# ╠═91ce0a38-0465-4c12-bc1a-50f27ffd03fc
# ╠═75e0fcf2-3b1a-49f9-9d5d-c0669ff14811
# ╠═e60cd084-57df-4d2f-9b00-4a4b9146668e
# ╠═3c25547f-741c-4a65-95be-654d451d8c87
# ╠═28f98086-b8a3-4144-8328-857e8a0e6bc7
# ╠═fba537c7-781d-4a26-9a50-7b8a2bf54e81
# ╠═0d52e800-ab33-4445-9974-44d28cbb1868
