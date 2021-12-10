using Distributed
using Test

nprocs() == 1 && addprocs()

@everywhere using MPI, HDF5, DrWatson

@test HDF5.has_parallel()

@info "Creating container"
@everywhere f = datadir("parallel.h5")
h5open(f, "w") do h5
    h5["exists"] = true
    hn = gethostname()
    d = rand(Int, 3, 3)
    for w in procs()
        create_dataset(h5, "hostname/id=$w", hn)
        create_dataset(h5, "data/id=$w", d)
    end
end

@info "PARTEY"
@everywhere begin
    MPI.Init()
    id = myid()
    h5open(f, "r+", MPI.COMM_WORLD) do h5
        write(h5["hostname/id=$id"], gethostname())
        write(h5["data/id=$id"], collect(reshape(id:id+8, 3, 3)))
    end
end

@info "Testing"
@testset begin
    h5open(f) do h5
        @test read(h5["exists"])
        @test haskey(h5, "data")
        @test haskey(h5, "hostname")

        @testset "data integrity id=$p" for p in procs()
            M = read(h5, "data/id=$p")
            @test M == collect(reshape(p:p+8, 3, 3))
        end
    end
end
