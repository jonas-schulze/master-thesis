function _load_rail(n::Int)
    dir = filter(readdir(datadir())) do f
        startswith(f, "SteelProfile-dim") && endswith(f, "-rail_$(n)")
    end |> only
    map((:E, :A, :B, :C)) do M
        mtx = datadir(dir, "rail_$(n)_c60.$(M)")
        MatrixMarket.mmread(mtx)
    end
end

function load_rail(::Config{:dense,371})
    P = matread(datadir("Rail371.mat"))
    @unpack E, A, B, C, X0 = P
    tspan = (4500., 0.) # backwards in time
    GDREProblem(E, A, B, C, X0, tspan)
end

function load_rail(::Config{:lowrank,371})
    P = matread(datadir("Rail371.mat"))
    @unpack E, A, B, C = P
    tspan = (4500., 0.) # backwards in time
    L = E \ C'
    D = spdiagm(fill(0.01, size(L, 2)))
    X0 = LDLᵀ(L, D)
    GDREProblem(E, A, B, C, X0, tspan)
end

# download data from modelreduction.org/index.php/Steel_Profile
function load_rail(::Config{:lowrank,N}) where {N}
    E, A, B, C = _load_rail(N)
    tspan = (4500., 0.) # backwards in time #FIXME
    L = E \ collect(C')
    D = spdiagm(fill(0.01, size(L, 2)))
    X0 = LDLᵀ(L, D)
    GDREProblem(E, A, B, C, X0, tspan)
end

function _alg(order)
    order == 1 && return Ros1()
    order == 2 && return Ros2()
    order == 3 && return Ros3()
    order == 4 && return Ros4()
    error("unknown order: ", order)
end

algorithms(c::SequentialConfig) = _alg(c.order)
algorithms(c::ParallelConfig) = _alg(c.oc), _alg(c.of)

function Δt(prob, nsteps)
    t0, tf = prob.tspan
    (tf - t0) / nsteps
end
