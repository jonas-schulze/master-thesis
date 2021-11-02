using DrWatson, Test
using DifferentialRiccatiEquations: DRESolution

include(srcdir("storage.jl"))

@testset "Playground" begin
    @testset "$(forward ? "storage" : reverse("storage"))" for forward in (true, false)
        t = 1:1:9
        K = rand(9)
        forward || (t = reverse(t))
        @testset "$(dense ? "dense DRE" : "sparse DRE")" for dense in (true, false)
            X = dense ? similar(K) : rand(2)
            sol = DRESolution(X, K, t)
            mktempdir() do dir
                store(dir, sol)
                # Don't create spurious files:
                @test readdir(dir) == ["K", "X"]
                Kmat = joinpath(dir, "K", "t=1:9.h5")
                Xmat = joinpath(dir, "X", "t=1:9.h5")
                @test readdir(joinpath(dir, "K"), join=true) == [Kmat]
                @test readdir(joinpath(dir, "X"), join=true) == [Xmat]
                # Data integrity of K:
                @test isfile(Kmat)
                tstops = ["t=$t" for t in t]
                h5open(Kmat) do f
                    @test sort(keys(f)) == sort(tstops)
                    @test [read(f, key) for key in tstops] == K
                end
                # Data integrity of X:
                @test isfile(Xmat)
                if !dense
                    tstops = ["t=1", "t=9"]
                    forward || reverse!(tstops)
                end
                h5open(Xmat) do f
                    @test sort(keys(f)) == sort(tstops)
                    @test [read(f, key) for key in tstops] == X
                end
                # Read data:
                K′ = readdata.(dir, "K", 1:9)
                forward || reverse!(K′)
                @test K′ == K
            end
        end
    end
end
