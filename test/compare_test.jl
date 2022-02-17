using Stuff, Test
using MAT

P = matread(datadir("Rail371.mat"))
@unpack E, A, B, C, X0 = P
Ed = collect(E) # d=dense
tspan = (4500., 0.)
prob = GDREProblem(Ed, A, B, C, X0, tspan)
sol = solve(prob, Ros1(); dt=-500, save_state=false)

@testset "comparison to self" begin
    mktempdir() do dir
        out = joinpath(dir, "dre.h5")
        wsave(out, sol)
        h5open(out) do h5
            K = h5["K"]
            X = h5["X"]
            @test all(==(0), δ(K, K))
            @test all(==(0), δ(X, X))
        end
    end
end

csolve(prob) = solve(prob, Ros1(); dt=-1500)
fsolve(prob) = solve(prob, Ros1(); dt=-500)
psol = solve(
    ParaReal.Problem(prob),
    ParaReal.Algorithm(csolve, fsolve);
    schedule=ProcessesSchedule([1, 1, 1]),
)

@testset "accuracy of parareal" begin
    mktempdir() do dir
        sfile = joinpath(dir, "seq.h5")
        pdir = joinpath(dir, "par")
        wsave(sfile, sol)
        wsave(pdir, psol)

        pfile = "$pdir.h5"
        mergedata(pdir, pfile)

        errX = δ(sfile, pfile, "X")
        errK = δ(sfile, pfile, "K")
        @test maximum(errX) <= 1e-5
        @test maximum(errK) <= 1e-5
    end
end
