### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ 8140be06-5025-40a7-b626-a0d20c3af885
begin
	import Pkg
	Pkg.activate("..")
	Base.active_project()
end

# ╔═╡ 58dd3682-ac09-48d5-99a9-030f2ac707f0
using DrWatson, MAT, UnPack, SparseArrays

# ╔═╡ 4e1f02c2-7137-476a-bfc4-f9cf324b2b31
md"""
# Sparse matrix products

Multiplying a sparse and a dense matrix produces a dense matrix by default:
"""

# ╔═╡ d2010ddd-11fb-4908-81bb-307ebc9a4975
begin
	P = matread(datadir("Rail371.mat"))
	@unpack E, A, B, C, X0 = P
	X = X0
end;

# ╔═╡ 719d35ad-b8e4-4a6d-9ae6-742cb0366c0e
typeof(B)

# ╔═╡ 4df61e3d-e093-44d9-823e-53cec16c4efe
typeof(X)

# ╔═╡ 9ec548f3-4c6e-4917-bc5d-cd2b22ac8048
BᵀX = B'X

# ╔═╡ 2013cc03-f326-40e2-9e2e-8051e058544d
K = BᵀX*E

# ╔═╡ 6284c4be-c568-4120-8938-0fd72786e5cf
BK = B*K

# ╔═╡ ce218bab-eb1d-4f5e-ba99-7a78ce75a211
md"""
For the Lyapunov solvers, the latter should preferably be sparse.
What is the best way to achieve this?
"""

# ╔═╡ dd91f74b-2d71-4128-b601-99ec0f6841c6
md"""
## Fill

Let's have a look at the sparsity of those matrices.
"""

# ╔═╡ cba6d56e-b15a-4b1f-82ca-eff0c6b52f20
s(M, eps=1e-20) = sparse([abs(m) > eps ? m : zero(m) for m in M])

# ╔═╡ fc537e3c-1f5d-4311-b421-2dff3ade3611
begin
	sfill(M::AbstractSparseMatrix) = nnz(M) / length(M)
	sfill(M::Matrix) = sfill(s(M))
end

# ╔═╡ fcbfbba7-a768-47eb-b7bc-9c301545e3a0
sfill(BK)

# ╔═╡ b6fc7565-3527-43dc-855c-00c4da70c879
sfill(K)

# ╔═╡ bb8cbc01-db5f-4a95-84a8-467d3b047c16
md"""
What happens if we convert select matrices to sparse storage before multiplying them?
"""

# ╔═╡ 9739b605-4132-4001-bd99-873560b42545
K1 = s(BᵀX)*E; K2 = s(K);

# ╔═╡ 3b23ff2a-bd76-44e6-a03f-d7fa2a118d56
sfill(B*K1) # bad

# ╔═╡ 1ade41d0-8194-4466-9ddb-ab99f812be7b
sfill(B*K2) # ok

# ╔═╡ 4eec96c9-ef92-42c7-98fa-650a8e3f94bd
md"""
This suggests that converting to sparse storage as late as possible is the better option.
Both matrices, `BᵀX` and `K`, have the same size $(size(K)).
"""

# ╔═╡ a40be74b-d8b1-4e12-a3a9-4a0daeadb4ae
B*K

# ╔═╡ 58342ede-c5a6-418e-b997-e08f7ee67a8c
md"""
## Answers from Martin

* Storing `K` in a dense format is not a problem,
  even though it becomes more and more sparse the bigger it is.
* Never ever fully assemble the matrices `C'C`, `B*K`, etc.
  Instead, reformulate the equations/solvers by means of the effects of the matrices involved.

  Maybe [`LinearMaps.jl`](https://github.com/Jutho/LinearMaps.jl)
  or [`LinearOperators.jl`](https://github.com/JuliaSmoothOptimizers/LinearOperators.jl)
  can help here.
"""

# ╔═╡ ca78e556-e166-4d34-9b04-98dd843dbe60
md"## Internal Stuff"

# ╔═╡ Cell order:
# ╟─4e1f02c2-7137-476a-bfc4-f9cf324b2b31
# ╠═d2010ddd-11fb-4908-81bb-307ebc9a4975
# ╠═719d35ad-b8e4-4a6d-9ae6-742cb0366c0e
# ╠═4df61e3d-e093-44d9-823e-53cec16c4efe
# ╠═9ec548f3-4c6e-4917-bc5d-cd2b22ac8048
# ╠═2013cc03-f326-40e2-9e2e-8051e058544d
# ╠═6284c4be-c568-4120-8938-0fd72786e5cf
# ╟─ce218bab-eb1d-4f5e-ba99-7a78ce75a211
# ╟─dd91f74b-2d71-4128-b601-99ec0f6841c6
# ╠═cba6d56e-b15a-4b1f-82ca-eff0c6b52f20
# ╠═fc537e3c-1f5d-4311-b421-2dff3ade3611
# ╠═fcbfbba7-a768-47eb-b7bc-9c301545e3a0
# ╠═b6fc7565-3527-43dc-855c-00c4da70c879
# ╟─bb8cbc01-db5f-4a95-84a8-467d3b047c16
# ╠═9739b605-4132-4001-bd99-873560b42545
# ╠═3b23ff2a-bd76-44e6-a03f-d7fa2a118d56
# ╠═1ade41d0-8194-4466-9ddb-ab99f812be7b
# ╟─4eec96c9-ef92-42c7-98fa-650a8e3f94bd
# ╠═a40be74b-d8b1-4e12-a3a9-4a0daeadb4ae
# ╟─58342ede-c5a6-418e-b997-e08f7ee67a8c
# ╟─ca78e556-e166-4d34-9b04-98dd843dbe60
# ╠═8140be06-5025-40a7-b626-a0d20c3af885
# ╠═58dd3682-ac09-48d5-99a9-030f2ac707f0
