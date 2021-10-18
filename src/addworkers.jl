"""
    @addworkers([n::Int])

Add workers and set them up to use `n` BLAS threads.
"""
macro addworkers()
    n = something(
        readenv("SLURM_CPUS_PER_TASK"),
        readenv("OMP_NUM_THREADS"),
        1,
    )
    return :(@addworkers($n))
end

macro addworkers(n::Int)
    if nprocs() != 1
        @warn "Workers already present; won't spawn any new ones."
        ws = workers()
    elseif !haskey(ENV, "SLURM_JOBID") && !haskey(ENV, "SLURM_JOB_ID")
        @info "Adding workers locally"
        ws = addprocs()
    else
        @info "Adding workers inside Slurm allocation"
        ws = addprocs(SlurmManager())
    end
    quote
        @everywhere $ws begin
            using LinearAlgebra
            BLAS.set_num_threads($n)
            @info "Hello world!" myid() gethostname() BLAS.get_num_threads() Base.active_project()
        end
    end
end
