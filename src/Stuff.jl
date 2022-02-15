module Stuff

using Reexport
@reexport using DrWatson
@reexport using Distributed, HDF5, UnPack
@reexport using LinearAlgebra
@reexport using LoggingFormats
@reexport using DifferentialRiccatiEquations, ParaReal

using DifferentialRiccatiEquations: DRESolution
using ParaReal: fetch_from_owner
using SlurmClusterManager
using MAT
using SparseArrays

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

function parareal_setup()
    # number of parareal steps:
    nstages = something(
        nprocs() > 1 ? nworkers() : nothing,
        readenv("SLURM_NTASKS"),
        Sys.CPU_THREADS ÷ 2,
    )
    # number of steps within stage:
    nc = something(readenv("MY_NC"), 1)
    nf = something(readenv("MY_NF"), 1)
    # order of solver:
    oc = something(readenv("MY_OC"), 1)
    of = something(readenv("MY_OF"), 1)
    # JIT warm-up:
    wc = something(readenv("MY_WC"), true)
    wf = something(readenv("MY_WF"), false)

    (; nstages, nc, nf, oc, of, wc, wf)
end

abstract type Config{X} end
struct SequentialConfig{X} <: Config{X}
end
struct ParallelConfig{X} <: Config{X}
    # number of parareal steps:
    nstages::Int
    # number of steps within stage:
    nc::Int
    nf::Int
    # order of solver:
    oc::Int
    of::Int
    # JIT warm-up:
    wc::Bool
    wf::Bool
    # other stuff:
    jobid::String

    function ParallelConfig(X::Symbol)
        X in (:dense, :lowrank) || throw(ArgumentError("type must be `:dense` or `:lowrank`; got $X"))

        nstages = something(
            nprocs() > 1 ? nworkers() : nothing,
            readenv("SLURM_NTASKS"),
            Sys.CPU_THREADS ÷ 2,
        )
        nc = something(readenv("MY_NC"), 1)
        nf = something(readenv("MY_NF"), 1)
        oc = something(readenv("MY_OC"), 1)
        of = something(readenv("MY_OF"), 1)
        wc = something(readenv("MY_WC"), true)
        wf = something(readenv("MY_WF"), false)
        jobid = get(ENV, "SLURM_JOBID", "0")

        new{X}(nstages, nc, nf, oc, of, wc, wf, jobid)
    end
end

DrWatson.default_prefix(c::Config{X}) where {X} = "rail371-$X"

include("addworkers.jl")
include("compare.jl")
include("logging.jl")
include("eventlog.jl")
include("storage.jl")
include("parareal_dre.jl")
include("problems.jl")

export ParallelConfig
export load_rail, algorithms, Δt

export readenv
export δ
export logdir, timeline, load_eventlog
export addworkers, set_num_threads, log_worker_info
export storemeta, readdata, mergedata

end
