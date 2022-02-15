using Stuff, Test
using Base.Iterators: partition
using DifferentialRiccatiEquations: DRESolution
using MAT
using ParaReal: fetch_from_owner

P = matread(datadir("Rail371.mat"))
@unpack E, A, B, C, X0 = P
Ed = collect(E) # d=dense

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
        tspan = forward ? (0., 4500.) : (4500., 0.)
        prob = GDREProblem(Ed, A, B, C, X0, tspan)

        @testset "DRE (save_state=$save_state)" for save_state in (true, false)
            dt = forward ? 1500.0 : -1500.0
            sol = solve(prob, Ros1(); dt=dt, save_state=save_state)
            mktempdir() do dir
                wsave(dir, sol)
                # Don't create spurious files:
                @test readdir(dir) == ["K", "X"]
                datafile = "t=0.0:4500.0.h5"
                @test readdir(joinpath(dir, "K")) == [datafile]
                @test readdir(joinpath(dir, "X")) == [datafile]
                # Data integrity of K:
                K = sol.K
                Kmat = joinpath(dir, "K", datafile)
                @test isfile(Kmat)
                tstops = ["t=$t" for t in 0.0:1500:4500.0]
                forward || reverse!(tstops)
                h5open(Kmat) do f
                    @test sort(keys(f)) == sort(tstops)
                    @test [read(f, key) for key in tstops] == K
                end
                # Data integrity of X:
                X = sol.X
                Xmat = joinpath(dir, "X", datafile)
                @test isfile(Xmat)
                if !save_state
                    tstops = ["t=0.0", "t=4500.0"]
                    forward || reverse!(tstops)
                end
                h5open(Xmat) do f
                    @test sort(keys(f)) == sort(tstops)
                    @test [read(f, key) for key in tstops] == X
                end
                # Read data:
                K′ = readdata.(dir, "K", 0.0:1500.0:4500.0)
                forward || reverse!(K′)
                @test K′ == K
            end
        end

        @testset "ParaReal" begin
            ws = if nworkers() >= 3 && isinteractive()
                @info "Reusing existing workers"
                workers()[1:3]
            else
                addprocs(3)
            end
            @everywhere [1; ws] begin
                using Stuff

                function _dt(prob, nsteps)
                    t0, tf = prob.tspan
                    (tf - t0) / nsteps
                end

                csolve(prob::GDREProblem) = solve(prob, Ros1(); dt=_dt(prob, 1))
                fsolve(prob::GDREProblem) = solve(prob, Ros1(); dt=_dt(prob, 3))
            end
            alg = ParaReal.Algorithm(csolve, fsolve)

            # Thanks to the authors of DeferredFutures.jl for this test strategy:
            GC.gc()
            size_before_solve = Base.summarysize(Distributed)

            sol = solve(ParaReal.Problem(prob), alg; schedule=ProcessesSchedule(ws))

            size_of_sol = Base.summarysize(sol)
            size_of_stages = sum(sol.stages) do sr
                fetch_from_owner(sr) do s::ParaReal.Stage
                    Base.summarysize(s)
                end
            end
            @test size_of_sol < size_of_stages

            # Individual solutions should not be fetched locally:
            @testset "no local data before save" begin
                GC.gc()
                size_after_solve = Base.summarysize(Distributed)
                @test size_after_solve < size_before_solve + size_of_stages
            end

            tspans = [(0., 1500.), (1500., 3000.), (3000., 4500.)]
            tstops = [t0:500:tf for (t0, tf) in tspans]
            if !forward
                tspans = map(reverse, tspans)
                tstops = map(reverse, tstops)
                reverse!(tspans)
                reverse!(tstops)
            end

            mktempdir() do dir
                wsave(dir, sol)
                # Individual solutions should still not be fetched locally:
                @testset "no local data after save" begin
                    GC.gc()
                    size_after_wsave = Base.summarysize(Distributed)
                    @test size_after_wsave < size_before_solve + size_of_stages
                end
                @testset "local solutions" begin
                    # All local solutions should be stored:
                    files = map(tspans) do tspan
                        tmin, tmax = extrema(tspan)
                        "t=$tmin:$tmax.h5"
                    end
                    @test readdir(dir) == ["K", "X"]
                    @test readdir(joinpath(dir, "K")) == sort(files)
                    @test readdir(joinpath(dir, "X")) == sort(files)
                    # Read data:
                    @testset "$file" for (file, tspan, ts) in zip(files, tspans, tstops)
                        k = joinpath(dir, "K", file)
                        x = joinpath(dir, "X", file)
                        h5open(k) do k5
                            @test sort(keys(k5)) == sort(["t=$t" for t in ts])
                        end
                        h5open(x) do x5
                            @test sort(keys(x5)) == sort(["t=$t" for t in tspan])
                        end
                    end
                    @testset "read data (n=$n)" for n in 1:3
                        s::DRESolution = sol.stages[n].Fᵏ⁻¹
                        ts = tstops[n]
                        t0, tf = tspans[n]
                        X0, Xf = s.X
                        @test readdata(dir, "X", t0) == s.X[1]
                        @test readdata(dir, "X", tf) == s.X[2]
                        @testset "t=$t" for (t, K) in zip(ts, s.K)
                            @test readdata(dir, "K", t) == K
                        end
                    end
                end
                storemeta(dir, Dict("hello" => "world"))
                @testset "merge decentral data" begin
                    out = joinpath(dir, "MERGED.h5")
                    mergedata(dir, out)
                    @test isfile(out)
                    h5open(out) do h5
                        @test ["K", "X"] ⊆ keys(h5)
                        @test sort(keys(h5["K"])) == sort(["t=$t" for t in 0.0:500.0:4500.0])
                        @test sort(keys(h5["X"])) == sort(["t=$t" for t in 0.0:1500.0:4500.0])
                    end
                    # Read data:
                    @testset "read data (n=$n)" for n in 1:3
                        s::DRESolution = sol.stages[n].Fᵏ⁻¹
                        ts = tstops[n]
                        t0, tf = tspans[n]
                        X0, Xf = s.X
                        @test readdata(out, "X", t0) == s.X[1]
                        @test readdata(out, "X", tf) == s.X[2]
                        @testset "t=$t" for (t, K) in zip(ts, s.K)
                            @test readdata(out, "K", t) == K
                        end
                    end
                end
            end
        end
    end

    @testset "relative error δ" begin
        include("compare_test.jl")
    end
end
