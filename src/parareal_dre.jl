ParaReal.initialvalue(p::GDREProblem) = p.X0
ParaReal.nextvalue(sol::DRESolution) = last(sol.X)

function ParaReal.remake_prob!(p::GDREProblem, _alg, X0, tspan)
    GDREProblem(p.E, p.A, p.B, p.C, X0, tspan)
end
