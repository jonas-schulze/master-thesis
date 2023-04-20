# Note on `merge_results.jl` and `merge_results.job`

Because of COVID-19, like many, I had to work from home. All my big data sets
were stored on the Max Planck Institute's network share, which I had no
convenient access to. Every access to the data had to be performed via SSH, and
every "long" operation scheduled via Slurm. The `merge_results.*` scripts are
an artifact of this fact. They were always work-in-progress and have only been
added to [git] long after the master defense for completeness' sake.

The only purpose of `merge_results.*` was to call `Stuff.merge_data` on the
most recent output `*.dir`. This function merges the individual HDF5 containers
(one per parareal stage or worker process) into one.

[git]: https://git-scm.com/

