module Stuff

using Reexport
@reexport using DrWatson
@reexport using Distributed, HDF5, UnPack
@reexport using DifferentialRiccatiEquations, ParaReal

using DifferentialRiccatiEquations: DRESolution
using SlurmClusterManager

"""
    readenv(var::String)

Read the environment variable `var` and try to parse it as an `Int`, `Float64`
or `Bool`. If unsuccessful, return nothing.

Intended to be used with [`something`](@ref).
"""
function readenv(var::String) where {T}
    s = get(ENV, var, "")
    s != "" || return nothing
    return something(tryparse(Int, s), tryparse(Float64, s), tryparse(Bool, s), Some(nothing))
end

include("addworkers.jl")
include("storage.jl")
include("parareal.jl")

export readenv
export @addworkers
export storemeta, readdata

end
