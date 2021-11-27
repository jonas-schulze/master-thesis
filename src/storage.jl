_copyto(h5, key, val) = (h5[key] = val; nothing)
_copyto(h5, key, val::HDF5.Dataset) = (h5[key] = read(val); nothing)

function _copyto(h5, key, val::Union{Dict{String}, HDF5.File, HDF5.Group})
    haskey(h5, key) || create_group(h5, key)
    h6 = h5[key]
    for (key′, val′) in pairs(val)
        haskey(h6, key′) && continue
        _copyto(h6, key′, val′)
    end
end

function mergedata(dir, out)
    isdir(dir) || error("input '$dir' is not a directory")
    ispath(out) && error("output '$out' already exists")
    # Take metadata as a canvas:
    metadata = joinpath(dir, "METADATA.h5")
    isfile(metadata) && cp(metadata, out)
    h5open(out, "cw") do o
        # Copy the event log:
        eventlog = joinpath(dir, "EVENTLOG.h5")
        if isfile(eventlog)
            h5open(eventlog) do l
                _copyto(o, "eventlog", l)
            end
        end
        # Copy solution data:
        for K in readdir(joinpath(dir, "K"); join=true)
            h5open(K) do k
                _copyto(o, "K", k)
            end
        end
        for X in readdir(joinpath(dir, "X"); join=true)
            h5open(X) do x
                _copyto(o, "X", x)
            end
        end
    end
end

function storemeta(dir, data::Dict{String})
    mkpath(dir)
    h5open(joinpath(dir, "METADATA.h5"), "w") do h5
        _copyto(h5, "/", data)
    end
end

function DrWatson._wsave(dir, sol::ParaReal.GlobalSolution)
    @sync for rr in sol.sols
        @async remotecall_wait(rr.where) do
            s = fetch(rr)
            DrWatson._wsave(dir, s.sol)
        end
    end
end

function DrWatson._wsave(dir, sol::DRESolution)
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
    isfile(dir) && return h5read(dir, "$mat/t=$t")
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
