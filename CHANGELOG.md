# v1.2

- Add ORCiD and date of defense to title page of thesis
- Fix minor wording and type-setting issues within thesis
- Fix page references within Glossary
- Fix inconsistent subscript `k` within Algorithm 5.1
- Build thesis and slides in CI
- Add missing `merge_results.*` scripts

Technical/internal:
- Rename default git branch to `main`
- Update git submodule paths to point to GitHub

# v1.1

- Add slide deck for defense (!17)

# v1.0

- Get low-rank solvers running (#3 and #4)
- Print version of thesis

# v0.2

- Get dense solvers running in parareal (#2)
- Ensure small relative error compared to sequential solution (!6)

# v0.1

- Port Norman's MATLAB codes to Julia (dense Rosenbrock order 1-4)
- Store K and X traces in HDF5 container
- Ensure small relative error (#1)
