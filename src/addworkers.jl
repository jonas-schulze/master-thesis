insideslurm() = haskey(ENV, "SLURM_JOBID") || haskey(ENV, "SLURM_JOB_ID")

function addworkers(::SequentialConfig)
    @warn "Did not spawn worker processes."
end

function addworkers(c::ParallelConfig)
    if nprocs() != 1
        @warn "Workers already present; won't spawn any new ones."
        return workers()
    elseif insideslurm()
        @info "Adding workers inside Slurm allocation"
        return addprocs(SlurmManager())
    else
        @info "Adding workers locally"
        # TODO: make this less ugly ...
        rr = something(readenv("MY_ROUNDROBIN", 1))
        return addprocs(c.nstages ÷ rr)
    end
end

function set_num_threads(n=1)
    n1 = readenv("SLURM_CPUS_PER_TASK")
    n2 = readenv("OMP_NUM_THREADS")
    nt = something(n1, n2, n)
    BLAS.set_num_threads(nt)
end

# Querying worker info is not trivial:
# https://discourse.julialang.org/t/making-code-available-to-workers/
function log_worker_info()
    ws = workers()
    query(f) = asyncmap(w -> remotecall_fetch(f, w), ws)
    local hn, ap, bt
    @sync begin
        @async hn = query(gethostname)
        @async ap = query(Base.active_project)
        @async bt = query(BLAS.get_num_threads)
    end
    groupby(col, groups) = Dict(g => col[findall(==(g), groups)] for g in unique(groups))
    @info "Worker info" hostname=groupby(ws, hn) active_project=groupby(ws, ap) blas_threads=groupby(ws, bt)
end
