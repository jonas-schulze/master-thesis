using MPI
using HDF5
using DrWatson

@assert HDF5.has_parallel()

MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
root = rank == 0

root && @info "Running on $(MPI.Comm_size(comm)) processes"

f = datadir("parallel.h5")
root && @info "Creating $f"
h5 = h5open(f, "w", comm)
@info "Writing 'exists' from $rank"
h5["exists", dxpl_mpio=HDF5.H5FD_MPIO_COLLECTIVE] = true
@info "Writing 'hostname/id=$rank'"
h5["hostname/id=$rank", dxpl_mpio=HDF5.H5FD_MPIO_COLLECTIVE] = gethostname()
@info "Writing 'data/id=$rank'"
h5["data/id=$rank", dxpl_mpio=HDF5.H5FD_MPIO_COLLECTIVE] = collect(reshape(rank:rank+8, 3, 3))

close(h5) # hangs indefinitely :-(
