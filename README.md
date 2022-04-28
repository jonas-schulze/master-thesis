# Playground

* playing with ParaReal and DifferentialRiccatiEquations
* sharing data with Mechthild

## Rail Benchmark

* modelreduction.org/index.php/Steel_Profile
* configuration `n=371` already included in `data/Rail371.mat`
* download bigger configurations from above URL, unzip and store them inside `data/`,
  e.g. `data/SteelProfile-dim1e3-rail_1357/rail_1357_c60.?`

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
