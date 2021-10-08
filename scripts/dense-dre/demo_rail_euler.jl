using DifferentialRiccatiEquations
using MAT, UnPack, HDF5
using DrWatson

using LinearAlgebra: BLAS
@show BLAS.get_num_threads()

## Setup
!@isdefined(dt) && (dt = parse(Int, get(ENV, "MY_DT", "1500")))
!@isdefined(order) && (order = parse(Int, get(ENV, "MY_ORDER", "1")))

if order == 1
    alg = Ros1()
elseif order == 2
    alg = Ros2()
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
container = datadir(savename("julia", (; dt, order), "h5"))
h5open(container, "w") do h5
    h5["gitcommit"] = gitdescribe()
    h5["script"] = @__FILE__
    for (i, _t) in enumerate(sol.t)
        t = Int(_t)
        K = sol.K[i]
        X = sol.X[i]
        h5["K/t=$t"] = K
        h5["X/t=$t"] = X
    end
end
