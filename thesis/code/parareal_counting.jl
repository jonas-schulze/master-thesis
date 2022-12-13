using ParaReal
using Distributed: addprocs, @everywhere

addprocs(3)
@everywhere using ParaReal

# Define problem type:
#== problem ==#
@everywhere begin
    struct SomeProblem
        v
        tspan
    end
    ParaReal.initial_value(p::SomeProblem) = p.v
    ParaReal.remake_prob(::SomeProblem, v, tspan) = SomeProblem(v, tspan)
end
#== end ==#

# Define solution type:
#== solution ==#
@everywhere begin
    struct Counters
        F::Int
        G::Int
    end
    ParaReal.value(c::Counters) = c #* \label{line:impl:parareal_counting:value}
    # Needed by default parareal update implementation:
    Base.:(+)(c1::Counters, c2::Counters) = Counters(c1.F + c2.F, c1.G + c2.G)
    Base.:(-)(c::Counters) = c
end
#== end ==#

# Instantiate solvers, problem, and compute solution:
#== solve ==#
inc_F = (p::SomeProblem) -> Counters(p.v.F + 1, p.v.G)
inc_G = (p::SomeProblem) -> Counters(p.v.F, p.v.G + 1)
tspan = (0., 42.) # does not matter here
prob = SomeProblem(Counters(0, 0), tspan)
sol = solve(
    ParaReal.Problem(prob),
    ParaReal.Algorithm(inc_G, inc_F);
    maxiters=2,
    # disable convergence checks, which call norm(::Counters)
    nconverged=typemax(Int),
    # do not evaluate default rtol, which calls size(::Counters, 1)
    rtol=0.0,
)
#== end ==#

#== result ==#
ParaReal.value(sol.stages[1])
ParaReal.value(sol.stages[2])
ParaReal.value(sol.stages[3])
#== end ==#

using Test
using ParaReal: value

@test value(sol.stages[1]) == Counters(1, 0)
@test value(sol.stages[2]) == Counters(2, 0)
@test value(sol.stages[3]) == Counters(7, 10)
