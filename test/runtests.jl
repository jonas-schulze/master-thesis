using DrWatson, Test
using DifferentialRiccatiEquations: DRESolution
using Distributed

include(srcdir("storage.jl"))

@testset "Playground" begin
    @testset "metadata" begin
        data = Dict{String,Any}()
        @tag!(data)
        data["foo"] = rand(3, 3)
        data["bar"] = Dict("baz" => rand(3, 3))
        mktempdir() do dir
            storemeta(dir, data)
            fname = joinpath(dir, "METADATA.h5")
            @test isfile(fname)
            @test h5read(fname, "foo") == data["foo"]
            @test h5read(fname, "bar/baz") == data["bar"]["baz"]
        end
    end

    @testset "$(forward ? "storage" : reverse("storage"))" for forward in (true, false)
        @testset "$(dense ? "dense DRE" : "sparse DRE")" for dense in (true, false)
            t = 1:9
            forward || (t = reverse(t))
            K = rand(9)
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

        @testset "ParaReal" begin
            n = 3
            t = 1:3n
            forward || (t = reverse(t))
            ts = partition(t, n)
            ws = addprocs(n)
            @everywhere ws begin
                using DrWatson, ParaReal
                using DifferentialRiccatiEquations: DRESolution
                include(srcdir("storage.jl"))
            end
            sols::Vector{Future} = asyncmap(ws, ts) do w, t
                remotecall_wait(w, t) do t
                    K = [[10.0x] for x in t]
                    X = [[first(t)], [last(t)]]
                    s = DRESolution(X, K, t)
                    return ParaReal.LocalSolution{DRESolution}(0, 0, s, :Success)
                end
            end
            sol = ParaReal.GlobalSolution(sols, ParaReal.Event[])
            mktempdir() do dir
                store(dir, sol)
                # Individual solutions should still not be fetched locally:
                @test sol.sols === sols
                @test all(isready, sols)
                @test all(rr -> rr.v === nothing, sols)
                # All local solutions should be stored:
                files = map(ts) do t
                    tmin, tmax = extrema(t)
                    "t=$tmin:$tmax.h5"
                end
                sort!(files)
                @test readdir(dir) == ["K", "X"]
                @test readdir(joinpath(dir, "K")) == files
                @test readdir(joinpath(dir, "X")) == files
                # Read data:
                @test readdata(dir, "K", 2n) == [20.0n]
                @test readdata(dir, "X", 1) == [1.0]
            end
            rmprocs(ws)
        end
    end
end
