# FMI Compatibility Information

!!! note
    This page is provided and maintained by the developers of *FMI.jl* ([JuliaFMI](https://github.com/JuliaFMI)). It is not provided by the Modelica Association or the FMI Project.

*FMI.jl* imports FMUs with [*FMIImport.jl*](https://github.com/JuliaFMI/FMIImport.jl) and creates FMUs with [*FMIExport.jl*](https://github.com/JuliaFMI/FMIExport.jl).
This page summarizes how the FMI support of these packages is validated.
All checks listed below run automatically in GitHub Actions on Windows (`win64`) and Linux (`linux64`), with the latest Julia release and the Julia LTS release.

## FMU Import

### FMI Cross-Check (FMI 2.0, ME and CS)

The [cross-check workflow](https://github.com/JuliaFMI/FMI.jl/actions/workflows/CrossChecks.yml) imports and simulates the FMI 2.0 FMUs of the [FMI Cross-Check repository](https://github.com/modelica/fmi-cross-check) with *FMI.jl* and compares the results to the reference results provided by the exporting tools.
An FMU passes if the mean normalized root-mean-square error (NRMSE) over all recorded variables is below the threshold set in [`cross_check_config.jl`](https://github.com/JuliaFMI/FMI.jl/blob/main/cross_checks/cross_check_config.jl).

The table shows the number of FMUs that passed in the run of *FMI.jl* v1.0.1 with the latest Julia release (18 November 2026), per exporting tool, interface type and platform:

| Exporting tool | Tool version | ME `win64` | CS `win64` | ME `linux64` | CS `linux64` |
| :--- | :--- | ---: | ---: | ---: | ---: |
| 20sim | 4.6.4.8004 | – | 1 | – | 1 |
| ASim | 2019FD01 | – | 2 | – | – |
| CATIA | R2015x | 1 | 3 | – | – |
| CATIA | R2016x | 4 | 5 | – | – |
| Dymola | 2015FD01 | 2 | 4 | – | – |
| Dymola | 2016 | 4 | 5 | – | – |
| Dymola | 2016FD01 | 4 | 5 | – | – |
| Dymola | 2017 | 5 | 6 | – | – |
| Dymola | 2019FD01 | 7 | 8 | – | – |
| Easy5 | 2017.1 | – | 1 | – | – |
| FMIToolbox MATLAB | 2.1 | – | 5 | – | – |
| FMIToolbox MATLAB | 2.3 | 4 | 4 | – | – |
| FMUSDK | 2.0.3 | 4 | 4 | – | – |
| FMUSDK | 2.0.4 | 4 | 4 | – | – |
| MapleSim | 7.01 | – | 1 | – | 1 |
| MapleSim | 2015.1 | – | 2 | – | 2 |
| MapleSim | 2015.2 | – | 2 | – | 2 |
| MapleSim | 2016.1 | – | 2 | – | 2 |
| MapleSim | 2016.2 | 1 | 2 | 1 | 2 |
| MapleSim | 2018 | 2 | 3 | 2 | 3 |
| MapleSim | 2019 | 2 | 3 | 2 | 3 |
| MapleSim | 2021.1 | 3 | 3 | 3 | 3 |
| MapleSim | 2021.2 | 3 | 3 | 3 | 3 |
| MWorks | 2021 | 6 | 5 | – | – |
| solidThinking Activate | 2020 | – | 4 | – | 4 |
| YAKINDU Statechart Tools | 4.0.4 | – | – | – | 2 |

The detailed results (one folder per FMU, as defined by the FMI Cross-Check) are stored in [JuliaFMI/fmi-cross-check](https://github.com/JuliaFMI/fmi-cross-check), with one branch per Julia version and platform:
[latest Julia, Windows](https://github.com/JuliaFMI/fmi-cross-check/tree/fmi.jl_check_1_windows-latest/results/2.0),
[latest Julia, Linux](https://github.com/JuliaFMI/fmi-cross-check/tree/fmi.jl_check_1_ubuntu-latest/results/2.0),
[Julia LTS, Windows](https://github.com/JuliaFMI/fmi-cross-check/tree/fmi.jl_check_lts_windows-latest/results/2.0) and
[Julia LTS, Linux](https://github.com/JuliaFMI/fmi-cross-check/tree/fmi.jl_check_lts_ubuntu-latest/results/2.0).
FMUs from *AMESim*, *SimulationX* and *Silver* as well as the *Test-FMUs* are currently excluded from the automated run (see `EXCLUDED_SYSTEMS` in [`cross_check_config.jl`](https://github.com/JuliaFMI/FMI.jl/blob/main/cross_checks/cross_check_config.jl)).

### FMIImport.jl Test Suite (FMI 2.0 and FMI 3.0)

The [test suite of *FMIImport.jl*](https://github.com/JuliaFMI/FMIImport.jl/tree/main/test) covers the import functionality of *FMI.jl* with the following FMUs:

| Exporting tool | Tool version | FMI version | FMUs | Tested functionality |
| :--- | :--- | :--- | :--- | :--- |
| Dymola ([FMUs](https://github.com/JuliaFMI/FMIZoo.jl/tree/main/models/bin/Dymola/2023x)) | 2023x | 2.0, 3.0 | `IO`, `SpringFrictionPendulum1D`, `SpringPendulum1D`, `SpringPendulumExtForce1D`, `SpringTimeFrictionPendulum1D` | ME and CS simulation including state and time events (FMI 2.0 and 3.0); getters/setters, FMU state handling, model description parsing and logging (FMI 2.0) |
| [Reference FMUs](https://github.com/modelica/Reference-FMUs) | 0.0.30, 0.0.36 | 2.0, 3.0 | `BouncingBall`, `Dahlquist`, `Feedthrough` | ME simulation with state events and model description parsing (FMI 2.0 and 3.0); getters/setters, FMU state handling and logging (FMI 3.0) |
| [LS-SA Reference FMUs](https://github.com/JuliaFMI/FMIZoo.jl/tree/main/models/bin/LSSAReferenceFMUs) | 0.1.0 | 3.0 | `NBouncingBalls_1` | Import of FMUs implementing the FMI-LS-SA layered standard (Windows) |

### Examples

The [examples](examples/overview.md) of this documentation are executed by the [examples workflow](https://github.com/JuliaFMI/FMI.jl/actions/workflows/Example.yml) (Windows, Julia 1.10) with FMI 2.0 FMUs exported by Dymola 2022x ([FMUs](https://github.com/JuliaFMI/FMIZoo.jl/tree/main/models/bin/Dymola/2022x)): `BouncingBall1D`, `IO`, `SpringFrictionPendulum1D`, `SpringPendulum1D` and `SpringPendulumExtForce1D`.

## FMU Export

The [test suite of *FMIExport.jl*](https://github.com/JuliaFMI/FMIExport.jl/tree/main/test) exports the [*FMIExport.jl* examples](https://github.com/JuliaFMI/FMIExport.jl/tree/main/examples) as FMI 2.0 and FMI 3.0 FMUs, then imports and simulates them with the following tool:

| Importing tool | Tool version | FMI version | Exported FMUs | Interface types | Checked results |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [FMPy](https://github.com/CATIA-Systems/FMPy) | 0.3.32 | 2.0, 3.0 | `BouncingBall` | ME, CS | compared to a reference solution computed with Dymola 2024x |
| [FMPy](https://github.com/CATIA-Systems/FMPy) | 0.3.32 | 2.0, 3.0 | `Manipulation`, `NeuralFMU` | ME | compared to expected results |

The test suite installs the latest FMPy release from PyPI (0.3.32 at the time of writing).

## Reproducing the Results

- **FMI Cross-Check:** see the [cross-check README](https://github.com/JuliaFMI/FMI.jl/blob/main/cross_checks/README.md), e.g., run `julia --project=cross_checks cross_checks/cross_check.jl --os windows-latest` from the root of the *FMI.jl* repository.
- **Test suites:** run `using Pkg; Pkg.test("FMIImport")` or `Pkg.test("FMIExport")` in the Julia REPL. The FMUs are downloaded automatically via [*FMIZoo.jl*](https://github.com/JuliaFMI/FMIZoo.jl).
