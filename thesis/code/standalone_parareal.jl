using Distributed
using DrWatson, UnPack, MAT

addprocs() # or similar

@everywhere begin
    using DifferentialRiccatiEquations, ParaReal
    using DifferentialRiccatiEquations: DRESolution
    using LinearAlgebra, SparseArrays

    ParaReal.initial_value(p::GDREProblem) = p.X0
    ParaReal.value(sol::DRESolution) = last(sol.X)

    function ParaReal.remake_prob(p::GDREProblem, X0, tspan)
        GDREProblem(p.E, p.A, p.B, p.C, X0, tspan)
    end

    #...

    function Base.:(-)(X::LDLᵀ{TL,TD}) where {TL,TD}
        Ls = X.Ls
        Ds = map(-, X.Ds)
        LDLᵀ{TL,TD}(Ls, Ds)
    end

    function LinearAlgebra.norm(X::LDLᵀ)
        L, D = X
        norm((L'L)*D) # Frobenius
    end

    csolve(prob) = solve(prob, Ros1(); dt=prob.tspan[2] - prob.tspan[1])
    fsolve(prob) = solve(prob, Ros1(); dt=(prob.tspan[2] - prob.tspan[1])/100)
end

#...

P = matread(datadir("Rail371.mat"))
@unpack E, A, B, C = P
L = E \ collect(C')
D = spdiagm(fill(0.01, size(L, 2)))
X₀ = LDLᵀ(L, D)
tspan = (4500.0, 0.0)

prob = ParaReal.Problem(GDREProblem(E, A, B, C, X₀, tspan))
alg  = ParaReal.Algorithm(csolve, fsolve)
sol  = solve(prob, alg; rtol=1e-6, nconverged=2)
