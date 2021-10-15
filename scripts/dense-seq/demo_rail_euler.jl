using DifferentialRiccatiEquations
using MAT, UnPack, HDF5
using DrWatson
using DrWatson: recursively_clear_path

using LinearAlgebra: BLAS
@show BLAS.get_num_threads()

## Setup
!@isdefined(dt) && (dt = parse(Int, get(ENV, "MY_DT", "1500")))
!@isdefined(order) && (order = parse(Int, get(ENV, "MY_ORDER", "1")))

if order == 1
    alg = Ros1()
elseif order == 2
    alg = Ros2()
elseif order == 3
    alg = Ros3()
elseif order == 4
    alg = Ros4()
else
    error("unknown order: ", order)
    exit(1)
end

P = matread(datadir("Rail371.mat"))
@unpack E, A, B, C, X0 = P
Ed = collect(E) # d=dense
tspan = (4500., 0.) # backwards in time
prob = GDREProblem(Ed, A, B, C, X0, tspan)

## Solve
dt = abs(dt)
sol = solve(prob, alg; dt=-dt, save_state=true)

## Store
mkpath(datadir("dense-seq"))
container = datadir("dense-seq", savename("rail371", (; dt, order), "h5"))
recursively_clear_path(container)
h5open(container, "w") do h5
    h5["gitcommit"] = gitdescribe()
    h5["script"] = @__FILE__
    h5["SLURM_JOB_ID"] = get(ENV, "SLURM_JOB_ID", "")

    for (i, _t) in enumerate(sol.t)
        t = Int(_t)
        K = sol.K[i]
        X = sol.X[i]
        h5["K/t=$t"] = K
        h5["X/t=$t"] = X
    end
end
