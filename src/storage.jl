_copyto(h5, key, val) = (h5[key] = val; nothing)

# This method is hit by mergedata for overlapping K and X values.
# Therefore, only store the first value encountered.
function _copyto(h5, key, val::HDF5.Dataset)
    haskey(h5, key) && return
    h5[key] = read(val)
    nothing
end

function _copyto(h5, key, val::Union{Dict{String}, HDF5.File, HDF5.Group})
    haskey(h5, key) || create_group(h5, key)
    h6 = h5[key]
    for (key′, val′) in pairs(val)
        _copyto(h6, key′, val′)
    end
end

function _copyto(h5, key, X::LDLᵀ)
    haskey(h5, key) || create_group(h5, key)
    h6 = h5[key]
    L, D::Matrix = X
    _copyto(h6, "L", L)
    _copyto(h6, "D", D)
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
        for f in readdir(dir; join=true)
            h5open(f) do i
                _copyto(o, "/", i)
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

function DrWatson._wsave(dir, sol::ParaReal.Solution)
    mkpath(dir)
    @sync for rr in sol.stages
        @async fetch_from_owner(rr) do s::ParaReal.Stage
            sol = s.Fᵏ⁻¹
            tmin, tmax = extrema(sol.t)
            fname = "t=$tmin:$tmax.h5"
            out = joinpath(dir, fname)
            DrWatson.wsave(out, sol)
        end
    end
end

function DrWatson._wsave(fname, sol::DRESolution)
    @unpack t, K, X = sol
    h5open(fname, "w") do h5
        create_group(h5, "K")
        create_group(h5, "X")

        # Store K:
        gk = h5["K"]
        for (t, K) in zip(t, K)
            _copyto(gk, "t=$t", K)
        end

        # Store X:
        gx = h5["X"]
        if length(X) == 2
            t0 = first(t)
            X0 = first(X)
            _copyto(gx, "t=$t0", X0)
            tf = last(t)
            Xf = last(X)
            _copyto(gx, "t=$tf", Xf)
        else
            for (t, X) in zip(t, X)
                _copyto(gx, "t=$t", X)
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
    for x in readdir(dir)
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
    h5read(joinpath(dir, fname), "$mat/t=$t")
end
