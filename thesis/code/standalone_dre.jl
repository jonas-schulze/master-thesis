using DifferentialRiccatiEquations
using DrWatson, UnPack, MAT
using SparseArrays

P = matread(datadir("Rail371.mat"))
@unpack E, A, B, C = P

# low-rank
L = E \ collect(C')
D = spdiagm(fill(0.01, size(L, 2)))
X₀ = LDLᵀ(L, D)

# dense
X₀ = Matrix(X₀)

tspan = (4500.0, 0.0)
prob = GDREProblem(E, A, B, C, X₀, tspan)
sol = solve(prob, Ros1(); dt=(tspan[2]-tspan[1])/100)
