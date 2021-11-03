using HDF5, ParaReal, UnPack
using DifferentialRiccatiEquations: DRESolution

function store(dir, sol::ParaReal.GlobalSolution)
    @sync for rr in sol.sols
        @async remotecall_wait(rr.where) do
            s = fetch(rr)
            store(dir, s.sol)
        end
    end
end

function store(dir, sol::DRESolution)
    @unpack t, K, X = sol
    tmin, tmax = extrema(sol.t)
    fname = "t=$tmin:$tmax.h5"
    mkpath(joinpath(dir, "K"))
    h5open(joinpath(dir, "K", fname), "w") do h5
        for (t, K) in zip(t, K)
            h5["t=$t"] = K
        end
    end
    mkpath(joinpath(dir, "X"))
    h5open(joinpath(dir, "X", fname), "w") do h5
        if length(X) == 2
            t0 = first(t)
            X0 = first(X)
            h5["t=$t0"] = X0
            tf = last(t)
            Xf = last(X)
            h5["t=$tf"] = Xf
        else
            for (t, X) in zip(t, X)
                h5["t=$t"] = X
            end
        end
    end
    return nothing
end

function readdata(dir, mat, t)
    # Locate surrounding time span:
    fnames = String[]
    lo = Float64[]
    hi = Float64[]
    mdir = joinpath(dir, mat)
    for x in readdir(mdir)
        (startswith(x, "t=") && endswith(x, ".h5")) || continue
        push!(fnames, x)
        s = split(x[3:end-3], ':')
        t1 = parse(Float64, s[1])
        t2 = parse(Float64, s[2])
        push!(lo, t1)
        push!(hi, t2)
    end
    p = sortperm(lo)
    permute!(fnames, p)
    permute!(lo, p)
    permute!(hi, p)
    i = findlast(<=(t), lo)
    t <= hi[i] || error("$mat for t=$t not found")
    # Read data from corresponding file:
    fname = fnames[i]
    h5read(joinpath(mdir, fname), "t=$t")
end
