# Master Thesis

* playing with ParaReal and DifferentialRiccatiEquations
* sharing data with Mechthild

## Rail Benchmark

* [MOR Wiki]
* configuration `n=371` already included in `data/Rail371.mat` (see [License](#section) section below)
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
  See [MOR WIKI] for further information.

  > **Warning**
  > The output matrix `C` of the included configuration differs from all the other configurations hosted at [MOR WIKI] by a factor of 10.
* `src/DifferentialRiccatiEquations.jl`: [MIT]
* `src/ParaReal.jl`: [MIT]

[BennerSaak2005]: http://nbn-resolving.de/urn:nbn:de:swb:ch1-200601597
[CC-BY-4.0]: https://spdx.org/licenses/CC-BY-4.0.html
[CC-BY-4.0 orig]: https://creativecommons.org/licenses/by/4.0/
[MIT]: https://spdx.org/licenses/MIT.html
[MOR Wiki]: http://modelreduction.org/index.php/Steel_Profile
