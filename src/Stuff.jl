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
using MAT, MatrixMarket
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

abstract type Config{X,N} end
Base.@kwdef struct SequentialConfig{X,N} <: Config{X,N}
    ncpus::Int # slurm c
    nsteps::Int
    order::Int
end
Base.@kwdef struct ParallelConfig{X,N} <: Config{X,N}
    # number of parareal steps:
    nstages::Int # parareal N, slurm n
    ncpus::Int # slurm c
    # number of steps within stage:
    nc::Int=1
    nf::Int=10
    # order of solver:
    oc::Int=1
    of::Int=1
    # JIT warm-up:
    wc::Bool=true
    wf::Bool=false
    # other stuff:
    jobid::String="0"
end

kind(::Config{X,N}) where {X,N} = X

function ParallelConfig(X::Symbol)
    X in (:dense, :lowrank) || throw(ArgumentError("type must be `:dense` or `:lowrank`; got $X"))

    nstages = something(
        nprocs() > 1 ? nworkers() : nothing,
        readenv("SLURM_NTASKS"),
        Sys.CPU_THREADS ÷ 2,
    )
    nstages *= something(readenv("MY_ROUNDROBIN"), 1)
    ncpus = something(
        readenv("SLURM_CPUS_PER_TASK"),
        readenv("OMP_NUM_THREADS"),
        1,
    ) # must match Stuff.set_num_threads
    nc = something(readenv("MY_NC"), 1)
    nf = something(readenv("MY_NF"), 1)
    oc = something(readenv("MY_OC"), 1)
    of = something(readenv("MY_OF"), 1)
    wc = something(readenv("MY_WC"), true)
    wf = something(readenv("MY_WF"), false)
    jobid = get(ENV, "SLURM_JOBID", "0")

    N = something(readenv("MY_RAIL"), 371)
    ParallelConfig{X,N}(; nstages, ncpus, nc, nf, oc, of, wc, wf, jobid)
end

function SequentialConfig(X::Symbol)
    X in (:dense, :lowrank) || throw(ArgumentError("type must be `:dense` or `:lowrank`; got $X"))
    ncpus = something(
        readenv("SLURM_CPUS_PER_TASK"),
        readenv("OMP_NUM_THREADS"),
        1,
    )
    nsteps = something(readenv("MY_N"), 1)
    order = something(readenv("MY_O"), 1)

    N = something(readenv("MY_RAIL"), 371)
    SequentialConfig{X,N}(; ncpus, nsteps, order)
end

DrWatson.default_prefix(c::Config{X,N}) where {X,N} = "rail$N-$X"

include("addworkers.jl")
include("compare.jl")
include("logging.jl")
include("eventlog.jl")
include("storage.jl")
include("parareal_dre.jl")
include("problems.jl")

include("figures.jl")

export ParallelConfig, SequentialConfig, kind
export load_rail, algorithms, Δt

export readenv
export δ
export logdir, timeline, timeline!, load_eventlog
export addworkers, set_num_threads, log_worker_info
export storemeta, readdata, mergedata

end
