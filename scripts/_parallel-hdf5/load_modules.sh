set -eu

module load compiler/gcc/6.4
module load mpi/openmpi/4.1
module load libraries/hdf5-mpi/1.10.5
module load apps/julia/1.6

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}
export JULIA_MPI_BINARY=system
export JULIA_HDF5_PATH=/mechthild/software/libraries/hdf5-mpi-1.10.5/gcc-6.4/openmpi-4.1/
export JULIA_PROJECT=@.

julia -e 'using Pkg; Pkg.build(verbose=true)'
julia -e 'using MPI; using HDF5; @assert HDF5.has_parallel()'
#mpiexec julia mpi-v0.jl
