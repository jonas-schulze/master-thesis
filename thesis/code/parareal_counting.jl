using ParaReal
using Distributed: addprocs, @everywhere

addprocs(3)
@everywhere using ParaReal

# Define problem type:
@everywhere begin
    struct SomeProblem
        v
        tspan
    end
    ParaReal.initial_value(p::SomeProblem) = p.v
    ParaReal.remake_prob(::SomeProblem, v, tspan) = SomeProblem(v, tspan)
end

# Define solution type:
@everywhere begin
    struct Counters
        F::Int
        G::Int
    end
    ParaReal.value(c::Counters) = c

    # Needed by default parareal update implementation:
    Base.:(+)(c1::Counters, c2::Counters) = Counters(c1.F + c2.F, c1.G + c2.G)
    Base.:(-)(c::Counters) = c
end

# Define solvers:
inc_F = (p::SomeProblem) -> Counters(p.v.F + 1, p.v.G)
inc_G = (p::SomeProblem) -> Counters(p.v.F, p.v.G + 1)

# Instantiate problem, solvers, and compute solution:
tspan = (0., 42.)
prob = ParaReal.Problem(SomeProblem(Counters(0, 0), tspan))
alg = ParaReal.Algorithm(inc_G, inc_F)
sol = solve(
    prob, alg;
    maxiters=2,
    nconverged=typemax(Int), # disable convergence checks, which call norm(::Counters)
    rtol=0.0, # don't evaluate default, which calls size(::Counters, 1)
)
