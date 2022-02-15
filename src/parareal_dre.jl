ParaReal.initial_value(p::GDREProblem) = p.X0
ParaReal.value(sol::DRESolution) = last(sol.X)

function ParaReal.remake_prob(p::GDREProblem, X0, tspan)
    GDREProblem(p.E, p.A, p.B, p.C, X0, tspan)
end
