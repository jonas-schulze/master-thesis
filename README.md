# Master Thesis

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7843198)][Zenodo]

This repository has been used to

* play around with [ParaReal.jl] and [DifferentialRiccatiEquations.jl], and
* share data with [Mechthild].

Download the thesis and slides from [Zenodo],
or build them as follows.

```
cd thesis
make all
```

All necessary images are included in this repository.
Use `thesis/figures/*.jl` to recreate them, if needed.
Most of these scripts as well as `notebooks/*.jl` are [Pluto.jl] notebooks.

[ParaReal.jl]: https://github.com/mpimd-csc/ParaReal.jl
[DifferentialRiccatiEquations.jl]: https://github.com/mpimd-csc/DifferentialRiccatiEquations.jl
[Pluto.jl]: https://github.com/fonsp/Pluto.jl
[Zenodo]: https://doi.org/10.5281/zenodo.7843198
[Mechthild]: https://www.mpi-magdeburg.mpg.de/cluster/mechthild

## Rail Benchmark

All computations have been conducted using the [Steel Profile][MOR Wiki] benchmark problem:

* configuration `n=371` already included in `data/Rail371.mat` (see [License](#section) section below)
* download bigger configurations from [MOR Wiki], unzip and store them inside `data/`,
  e.g. `data/SteelProfile-dim1e3-rail_1357/rail_1357_c60.?`

## Usage

The main working scripts are

* `scripts/compute_seq.jl` to solve a DRE sequentially, and
* `scripts/compute_par.jl` to solve a DRE using parareal.

If you are working inside a [Slurm] environment,
these scripts may be launched using `scripts/seq.job` and `scripts/par.job`, respectively.
Refer to the slides of the defense for some specific usage examples.

> **Note**
> The parareal solvers will create one [HDF5] container containing the DRE solution trajectories per process.
> You may use `scripts/merge_results.jl` (must be adapted) to merge these into one.
> See `scripts/README.md`.

[HDF5]: https://en.wikipedia.org/wiki/Hierarchical_Data_Format
[Slurm]: https://slurm.schedmd.com/

Most scripts are configured using environment variables:

* `MY_RAIL`: size/configuration of Rail Benchmark (default `371`)
* `MY_KIND`: `dense` or `lowrank` (mandatory, i.e. no default)
* `MY_X`: `true`/`1` or `false`/`0` (default `false`).
  Whether to store the `X`/state trajectories.
  Note that values at `t0` and `tf` are always stored,
  hence for pararealcompute scripts all interface `X` values are stored in any case.

Special to `scripts/compute_seq.jl` and `scripts/seq.job`:

* `MY_N`: number of Rosenbrock steps along time span (default `1`)
* `MY_O`: order of Rosenbrock method (default `1`)

Special to `scripts/compute_par.jl` and `scripts/par.job`:

* `MY_OC`/`MY_OF`: order of coarse/fine solver (default `1`/`1`)
* `MY_NC`/`MY_NF`: number of Rosenbrock steps for coarse/fine solver (default `1`/`10`)
* `MY_WC`/`MY_WF`: whether to warm up coarse/fine solver beforehand (default `true`/`false`)
* `MY_ROUNDROBIN`: how many parareal stages to assign to every worker process (default `1`)

## Features used from [DrWatson.jl]

* `projectdir` and `datadir` (check out their MATLAB/Octave ports in `src/m`)
* `savename`
* `recursively_clear_path`
* `gitdescribe`

## MATLAB/Octave Setup

Update the load path before starting MATLAB:

```bash
export MATLABPATH=$MATLABPATH:$(git rev-parse --show-toplevel)/src/m
```

Alternatively, modify your MATLAB/Octave configuration permanently:

```m
[~, toplevel] = system('git rev-parse --show-toplevel')
dirs = {strtrim(toplevel), 'src', 'm'}
addpath(strjoin(dirs, filesep))
savepath
```

The latter needs to be done only once. 🤞

[DrWatson.jl]: https://juliadynamics.github.io/DrWatson.jl/stable/

# License

This work is licensed under a [Creative Commons Attribution 4.0 International License][CC-BY-4.0 orig].

![CC-BY-4.0 image](https://i.creativecommons.org/l/by/4.0/88x31.png)

The following files/directories are merely redistributed under their own licenses:

* `data/Rail371.mat`: The data stems from [BennerSaak2005] and is licensed under [CC-BY-4.0].
  See [MOR Wiki] for further information.

  > **Warning**
  > The output matrix `C` of the included configuration differs from all the other configurations hosted at [MOR Wiki] by a factor of 10.
* `src/DifferentialRiccatiEquations.jl`: [MIT]
* `src/ParaReal.jl`: [MIT]

[BennerSaak2005]: http://nbn-resolving.de/urn:nbn:de:swb:ch1-200601597
[CC-BY-4.0]: https://spdx.org/licenses/CC-BY-4.0.html
[CC-BY-4.0 orig]: https://creativecommons.org/licenses/by/4.0/
[MIT]: https://spdx.org/licenses/MIT.html
[MOR Wiki]: http://modelreduction.org/index.php/Steel_Profile
