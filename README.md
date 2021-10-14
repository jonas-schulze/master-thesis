# Playground

* playing with ParaReal and DifferentialRiccatiEquations
* sharing data with Mechthild

## Features used from [DrWatson.jl]

* `projectdir` and `datadir` (check out their MATLAB/Octave ports in `src/m`)
* `savename`

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
