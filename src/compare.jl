using HDF5, Dictionaries, LinearAlgebra

"""
    δ(x1, x2)

Compute the relative error `norm(x1-x2) / norm(x2)` via Frobenius norm.
"""
function δ end

function δ(f1::String, f2::String, path::String="/")
    h5 = h5open(f1)
    h6 = h5open(f2)
    local rv
    try
        rv = δ(h5[path], h6[path])
    catch
        rethrow()
    finally
        @info "Closing file handles"
        close(h5)
        close(h6)
    end
    return rv
end

function δ(g1::HDF5.Group, g2::HDF5.Group)
    k1 = keys(g1)
    k2 = keys(g2)
    k1 == k2 || @warn "key sets do not match"
    ks = intersect(k1, k2)
    return dictionary(k => δ(g1[k], g2[k]) for k in ks)
end

function δ(d1::HDF5.Dataset, d2::HDF5.Dataset)
    x1 = read(d1)
    x2 = read(d2)
    return norm(x1-x2) / norm(x2)
end

