# Playground

* playing with ParaReal and DifferentialRiccatiEquations
* sharing data with Mechthild

## Rail Benchmark

* modelreduction.org/index.php/Steel_Profile
* configuration `n=371` already included in `data/Rail371.mat`
* download bigger configurations from above URL, unzip and store them inside `data/`,
  e.g. `data/SteelProfile-dim1e3-rail_1357/rail_1357_c60.?`

## Environment Variables

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
