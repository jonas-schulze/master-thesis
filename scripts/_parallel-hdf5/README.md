# Writing HDF5 in parallel

TL;DR: I wasn't able to get it working.

## v0: naive attempt

ParaReal utilizes Julia parallelism consisting of `Distributed.@spawn` and
friends.  The natural choice would be to have each worker (process) write to
the same HDF5 container in parallel.  I was expecting some hiccups, so even
creating the HDF5 datasets beforehand and only writing to them in parallel
would be ok, too.  This did not work.  While the container is "successfully"
written to, the data integrity checks fail:

```bash
$ sinteractive -n16
$ source load_modules.sh
    Building MPI ─→ `~/.julia/scratchspaces/44cfe95a-1eb2-52ea-b672-e2afdf69b78f/340d8dc89e1c85a846d3f38ee294bfdd1684055a/build.log`
[ Info: using system MPI                             ]  0/2
┌ Info: Using implementation
│   libmpi = "libmpi"
│   mpiexec_cmd = `mpiexec`
└   MPI_LIBRARY_VERSION_STRING = "Open MPI v4.1.1, package: Open MPI root@mechthild02.service Distribution, ident: 4.1.1, repo rev: v4.1.1, Apr 24, 2021\0"
┌ Info: MPI implementation detected
│   impl = OpenMPI::MPIImpl = 2
│   version = v"4.1.1"
└   abi = "OpenMPI"
    Building HDF5 → `~/.julia/scratchspaces/44cfe95a-1eb2-52ea-b672-e2afdf69b78f/3b6cc57d61104f2fad46a3cc3b67ee4c27312870/build.log`
[ Info: using system HDF5=======>                    ]  1/2
...
$ julia v0-default.jl
[ Info: Creating container
[ Info: PARTEY
[ Info: Testing
...
Test Summary:          | Pass  Fail  Total
test set               |    5    15     20
  data integrity id=1  |    1            1
  data integrity id=2  |          1      1
  data integrity id=3  |          1      1
  data integrity id=4  |    1            1
  data integrity id=5  |          1      1
  data integrity id=6  |          1      1
  data integrity id=7  |          1      1
  data integrity id=8  |          1      1
  data integrity id=9  |          1      1
  data integrity id=10 |          1      1
  data integrity id=11 |          1      1
  data integrity id=12 |          1      1
  data integrity id=13 |          1      1
  data integrity id=14 |          1      1
  data integrity id=15 |          1      1
  data integrity id=16 |          1      1
  data integrity id=17 |          1      1
```

In fact, almost all datasets contain the same data:

```bash
$ julia -e 'using DrWatson, HDF5; d=h5read(datadir("parallel.h5"), "data"); foreach(println, d)'
Pair{String, Any}("id=11", [4 7 10; 5 8 11; 6 9 12])
Pair{String, Any}("id=17", [4 7 10; 5 8 11; 6 9 12])
Pair{String, Any}("id=16", [4 7 10; 5 8 11; 6 9 12])
Pair{String, Any}("id=13", [4 7 10; 5 8 11; 6 9 12])
Pair{String, Any}("id=2", [4 7 10; 5 8 11; 6 9 12])
Pair{String, Any}("id=9", [4 7 10; 5 8 11; 6 9 12])
Pair{String, Any}("id=8", [4 7 10; 5 8 11; 6 9 12])
Pair{String, Any}("id=10", [4 7 10; 5 8 11; 6 9 12])
Pair{String, Any}("id=14", [4 7 10; 5 8 11; 6 9 12])
Pair{String, Any}("id=15", [4 7 10; 5 8 11; 6 9 12])
Pair{String, Any}("id=6", [4 7 10; 5 8 11; 6 9 12])
Pair{String, Any}("id=1", [1 4 7; 2 5 8; 3 6 9])
Pair{String, Any}("id=4", [4 7 10; 5 8 11; 6 9 12])
Pair{String, Any}("id=12", [4 7 10; 5 8 11; 6 9 12])
Pair{String, Any}("id=5", [4 7 10; 5 8 11; 6 9 12])
Pair{String, Any}("id=7", [4 7 10; 5 8 11; 6 9 12])
Pair{String, Any}("id=3", [4 7 10; 5 8 11; 6 9 12])
```

## v1: piggybacking MPI

HDF5 requires MPI parallelism, IIUC. 
So I tried to piggyback MPI on the naive solution, hoping that the library would resolve the individual (and distinct) writes.
This did not work either: 

```bash
$ julia v1-default-with-mpi.jl
[ Info: Creating container
[ Info: PARTEY
srun: error: PMK_KVS_Barrier duplicate request from task 0
srun: error: PMK_KVS_Barrier duplicate request from task 0
srun: error: PMK_KVS_Barrier duplicate request from task 0
srun: error: PMK_KVS_Barrier duplicate request from task 0
srun: error: PMK_KVS_Barrier duplicate request from task 0
srun: error: PMK_KVS_Barrier duplicate request from task 0
srun: error: PMK_KVS_Barrier duplicate request from task 0
srun: error: PMK_KVS_Barrier duplicate request from task 0
srun: error: PMK_KVS_Barrier duplicate request from task 0
srun: error: PMK_KVS_Barrier duplicate request from task 0
srun: error: PMK_KVS_Barrier duplicate request from task 0
srun: error: PMK_KVS_Barrier duplicate request from task 0
srun: error: PMK_KVS_Barrier duplicate request from task 0
srun: error: PMK_KVS_Barrier duplicate request from task 0
srun: error: PMK_KVS_Barrier duplicate request from task 0
srun: error: PMK_KVS_Barrier duplicate request from task 0
^C
```

## v2: MPI all the way

Even though I don't intent to rewrite ParaReal to use MPI, I was curious to get this working.
For some reason, I get a deadlock when closing the file handle, no matter whether I use independent or collective access.
The only difference is whether the `Writing...` logs occur semi-randomly or grouped:

```bash
$ mpiexec julia v2-mpi.jl
[ Info: Running on 16 processes
[ Info: Creating /mechthild/home/jschulze/playground/data/parallel.h5
[ Info: Writing 'exists' from 0
[ Info: Writing 'exists' from 4
[ Info: Writing 'exists' from 5
[ Info: Writing 'exists' from 11
[ Info: Writing 'exists' from 6
[ Info: Writing 'exists' from 9
[ Info: Writing 'exists' from 7
[ Info: Writing 'exists' from 10
[ Info: Writing 'exists' from 13
[ Info: Writing 'exists' from 12
[ Info: Writing 'exists' from 14
[ Info: Writing 'exists' from 15
[ Info: Writing 'exists' from 1
[ Info: Writing 'exists' from 3
[ Info: Writing 'exists' from 2
[ Info: Writing 'exists' from 8
[ Info: Writing 'hostname/id=15'
[ Info: Writing 'hostname/id=7'
[ Info: Writing 'hostname/id=5'
[ Info: Writing 'hostname/id=2'
[ Info: Writing 'hostname/id=14'
[ Info: Writing 'hostname/id=8'
[ Info: Writing 'hostname/id=9'
[ Info: Writing 'hostname/id=11'
[ Info: Writing 'hostname/id=10'
[ Info: Writing 'hostname/id=13'
[ Info: Writing 'hostname/id=12'
[ Info: Writing 'hostname/id=3'
[ Info: Writing 'hostname/id=1'
[ Info: Writing 'hostname/id=4'
[ Info: Writing 'hostname/id=0'
[ Info: Writing 'hostname/id=6'
[ Info: Writing 'data/id=14'
[ Info: Writing 'data/id=12'
[ Info: Writing 'data/id=4'
[ Info: Writing 'data/id=1'
[ Info: Writing 'data/id=15'
[ Info: Writing 'data/id=10'
[ Info: Writing 'data/id=11'
[ Info: Writing 'data/id=13'
[ Info: Writing 'data/id=7'
[ Info: Writing 'data/id=2'
[ Info: Writing 'data/id=6'
[ Info: Writing 'data/id=3'
[ Info: Writing 'data/id=8'
[ Info: Writing 'data/id=5'
[ Info: Writing 'data/id=0'
[ Info: Writing 'data/id=9'
^C
```

