#
# Copyright (c) 2021 Tobias Thummerer, Lars Mikelsons, Josef Kircher
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

# The deprecated functions only forward to their replacements, so every one is checked for
# (1) logging a deprecation warning that names the replacement and
# (2) returning the same result as the replacement.

using OrdinaryDiffEqTsit5: Tsit5
using Logging: SimpleLogger, with_logger

deprecation(old, new) =
    (:warn, Regex("`$(nameof(old))` is deprecated, use `$(nameof(new))`"))

# FMIZoo models (name, tool, tool version, FMI version)
model2 = ("SpringPendulum1D", "Dymola", "2023x", "2.0")
model3 = ("BouncingBall", "ModelicaReferenceFMUs", "0.0.30", "3.0")

@testset "Warning limit per function" begin
    io = IOBuffer()
    with_logger(SimpleLogger(io)) do
        for _ = 1:5
            FMI.warnDeprecated("oldA", "newA")
            FMI.warnDeprecated("oldB", "newB")
        end
    end
    log = String(take!(io))
    @test count("`oldA` is deprecated", log) == 3
    @test count("`oldB` is deprecated", log) == 3
end

@testset "Load, info and unload" begin
    fmus = (
        (fmiLoad, fmiInfo, fmiUnload, model2, FMU2),
        (fmi2Load, fmi2Info, fmi2Unload, model2, FMU2),
        (fmi3Load, fmi3Info, fmi3Unload, model3, FMU3),
    )

    for (load, info_, unload, args, T) in fmus
        fmu = @test_logs deprecation(load, loadFMU) match_mode = :any load(args...)
        @test fmu isa T
        @test getModelName(fmu) == args[1]

        @test_logs deprecation(info_, info) match_mode = :any info_(fmu)
        @test_logs deprecation(unload, unloadFMU) match_mode = :any unload(fmu)
    end
end

@testset "Simulate" begin
    tspan = (0.0, 1.0)
    recordValues = ["mass.s", "mass.v"]

    fmuCS = loadFMU(model2...; type = :CS)
    fmuME = loadFMU(model2...; type = :ME)

    kwargsCS = (; tspan, recordValues, dt = 1e-2, showProgress = false)
    kwargsME = (;
        tspan,
        recordValues,
        saveat = 0.0:0.1:1.0,
        solver = Tsit5(),
        showProgress = false,
    )

    # (deprecated, replacement, FMU, keyword arguments)
    cases = (
        (fmiSimulate, simulate, fmuCS, kwargsCS),
        (fmi2Simulate, simulate, fmuME, kwargsME),
        (fmiSimulateCS, simulateCS, fmuCS, kwargsCS),
        (fmi2SimulateCS, simulateCS, fmuCS, kwargsCS),
        (fmiSimulateME, simulateME, fmuME, kwargsME),
        (fmi2SimulateME, simulateME, fmuME, kwargsME),
    )

    for (old, new, fmu, kwargs) in cases
        solution = @test_logs deprecation(old, new) match_mode = :any old(fmu; kwargs...)
        @test solution.success
        @test solution.values.saveval == new(fmu; kwargs...).values.saveval
    end

    unloadFMU(fmuCS)
    unloadFMU(fmuME)
end
