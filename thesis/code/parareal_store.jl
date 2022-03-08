using ParaReal: fetch_from_owner

# Assume solution to be given:
sol::ParaReal.Solution

# Ensure output directory exists:
mkpath(dir)

@sync for sref in sol.stages
    @async fetch_from_owner(sref) do s::ParaReal.Stage
        sol = ParaReal.solution(s)
        tmin, tmax = extrema(sol.t)
        fname = joinpath(dir, "t=$tmin:$tmax.h5")
        # Write `sol` to `fname`, e.g. via
        DrWatson.wsave(fname, sol)
    end
end
