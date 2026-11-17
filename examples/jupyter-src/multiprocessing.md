# Multiprocessing
Tutorial by Jonas Wilfert, Tobias Thummerer

🚧 This tutorial is under revision and will be replaced by an up-to-date version soon 🚧

## License


```julia
# Copyright (c) 2021 Tobias Thummerer, Lars Mikelsons, Josef Kircher, Johannes Stoljar, Jonas Wilfert
# Licensed under the MIT license. 
# See LICENSE (https://github.com/JuliaFMI/FMI.jl/blob/main/LICENSE) file in the project root for details.
```

## Motivation
This Julia Package *FMI.jl* is motivated by the use of simulation models in Julia. Here the FMI specification is implemented. FMI (*Functional Mock-up Interface*) is a free standard ([fmi-standard.org](https://fmi-standard.org/)) that defines a container and an interface to exchange dynamic models using a combination of XML files, binaries and C code zipped into a single file. The user can thus use simulation models in the form of an FMU (*Functional Mock-up Unit*). Besides loading the FMU, the user can also set values for parameters and states and simulate the FMU both as co-simulation and model exchange simulation.

## Introduction to the example
This example shows how to parallelize the computation of an FMU in FMI.jl. We can compute a batch of FMU-evaluations in parallel with different initial settings.
Parallelization can be achieved using multithreading or using multiprocessing. This example shows **multiprocessing**, check `multithreading.ipynb` for multithreading.
Advantage of multithreading is a lower communication overhead as well as lower RAM usage.
However in some cases multiprocessing can be faster as the garbage collector is not shared.


The model used is a one-dimensional spring pendulum with friction. The object-orientated structure of the *SpringFrictionPendulum1D* can be seen in the following graphic.

![svg](https://github.com/JuliaFMI/FMI.jl/blob/main/docs/src/examples/pics/SpringFrictionPendulum1D.svg?raw=true)  


## Target group
The example is primarily intended for users who work in the field of simulations. The example wants to show how simple it is to use FMUs in Julia.


## Other formats
Besides, this [Jupyter Notebook](https://github.com/JuliaFMI/FMI.jl/blob/examples/examples/jupyter-src/multiprocessing.ipynb) there is also a [Julia file](https://github.com/JuliaFMI/FMI.jl/blob/examples/examples/jupyter-src/multiprocessing.jl) with the same name, which contains only the code cells and for the documentation there is a [Markdown file](https://github.com/JuliaFMI/FMI.jl/blob/examples/examples/jupyter-src/multiprocessing.md) corresponding to the notebook.  


## Getting started

### Installation prerequisites
|     | Description                       | Command                   | Alternative                                    |   
|:----|:----------------------------------|:--------------------------|:-----------------------------------------------|
| 1.  | Enter Package Manager via         | ]                         |                                                |
| 2.  | Install FMI via                   | add FMI                   | add " https://github.com/JuliaFMI/FMI.jl "     |
| 3.  | Install FMIZoo via                | add FMIZoo                | add " https://github.com/JuliaFMI/FMIZoo.jl "  |
| 4.  | Install FMICore via               | add FMICore               | add " https://github.com/JuliaFMI/FMICore.jl " |
| 5.  | Install BenchmarkTools via        | add BenchmarkTools        |                                                |

## Code section



Adding your desired amount of processes:


```julia
using Distributed
n_procs = 2
addprocs(n_procs; exeflags=`--project=$(Base.active_project()) --threads=auto`, restrict=false)
```




    2-element Vector{Int64}:
     2
     3



To run the example, the previously installed packages must be included. 


```julia
# imports
@everywhere using FMI
@everywhere using FMIZoo
@everywhere using DifferentialEquations
@everywhere using BenchmarkTools
```

Checking that we workers have been correctly initialized:


```julia
workers()

@everywhere println("Hello World!")

# The following lines can be uncommented for more advanced information about the subprocesses
# @everywhere println(pwd())
# @everywhere println(Base.active_project())
# @everywhere println(gethostname())
# @everywhere println(VERSION)
# @everywhere println(Threads.nthreads())
```

    Hello World!
          From worker 2:	Hello World!
          From worker 3:	Hello World!
    

### Simulation setup

Next, the batch size and input values are defined.


```julia

# Best if batchSize is a multiple of the threads/cores
batchSize = 16

# Define an array of arrays randomly
input_values = collect(collect.(eachrow(rand(batchSize,2))))
```




    16-element Vector{Vector{Float64}}:
     [0.31370753616565106, 0.5677033995043232]
     [0.9119680863224477, 0.6102019951019838]
     [0.4565789742285421, 0.9974367458290544]
     [0.029014037532767545, 0.882800755047848]
     [0.16476101122511055, 0.34335101561949843]
     [0.6998922006413412, 0.16704404286692554]
     [0.536947449917662, 0.8278811071569171]
     [0.284765888683821, 0.8239957646977913]
     [0.61617241735091, 0.7167992574240977]
     [0.6753056379233328, 0.0989598482863614]
     [0.22574974115635682, 0.805710744435462]
     [0.05407307367761871, 0.23348557884833931]
     [0.38298705415076517, 0.4024862377041738]
     [0.4589791004123366, 0.5641124624714056]
     [0.19591637691940544, 0.31633072193683054]
     [0.7708480353785765, 0.8710739891319083]



### Shared Module
For Distributed we need to embed the FMU into its own `module`. This prevents Distributed from trying to serialize and send the FMU over the network, as this can cause issues. This module needs to be made available on all processes using `@everywhere`.


```julia
@everywhere module SharedModule
    using FMIZoo
    using FMI

    t_start = 0.0
    t_step = 0.1
    t_stop = 10.0
    tspan = (t_start, t_stop)
    tData = collect(t_start:t_step:t_stop)

    model_fmu = loadFMU("SpringPendulum1D", "Dymola", "2022x"; type=:ME)
end
```

We define a helper function to calculate the FMU and combine it into a matrix.


```julia
@everywhere function runCalcFormatted(fmu, x0, recordValues=["mass.s", "mass.v"])
    data = simulateME(fmu, SharedModule.tspan; recordValues=recordValues, saveat=SharedModule.tData, x0=x0, showProgress=false, dtmax=1e-4)
    return reduce(hcat, data.states.u)
end
```

Running a single evaluation is pretty quick, therefore the speed can be better tested with BenchmarkTools.


```julia
@benchmark data = runCalcFormatted(SharedModule.model_fmu, rand(2))
```




    BenchmarkTools.Trial: 3 samples with 1 evaluation per sample.
     Range (min … max):  1.883 s …  1.893 s  ┊ GC (min … max): 0.35% … 0.05%
     Time  (median):     1.891 s             ┊ GC (median):    0.35%
     Time  (mean ± σ):   1.889 s ± 4.927 ms  ┊ GC (mean ± σ):  0.27% ± 0.19%
    
      █                                          █           █  
      █▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁█ ▁
      1.88 s        Histogram: frequency by time        1.89 s <
    
     Memory estimate: 64.21 MiB, allocs estimate: 4201025.



### Single Threaded Batch Execution
To compute a batch we can collect multiple evaluations. In a single threaded context we can use the same FMU for every call.


```julia
println("Single Threaded")
@benchmark collect(runCalcFormatted(SharedModule.model_fmu, i) for i in input_values)
```

    Single Threaded
    




    BenchmarkTools.Trial: 1 sample with 1 evaluation per sample.
     Single result which took 30.483 s (0.08% GC) to evaluate,
     with a memory estimate of 1.00 GiB, over 67216388 allocations.



### Multithreaded Batch Execution
In a multithreaded context we have to provide each thread its own FMU, as they are not thread safe.
To spread the execution of a function to multiple processes, the function `pmap` can be used.


```julia
println("Multi Threaded")
@benchmark pmap(i -> runCalcFormatted(SharedModule.model_fmu, i), input_values)
```

    Multi Threaded

    
    




    BenchmarkTools.Trial: 1 sample with 1 evaluation per sample.
     Single result which took 15.997 s (0.00% GC) to evaluate,
     with a memory estimate of 124.58 KiB, over 2363 allocations.



As you can see, there is a significant speed-up in the median execution time. But: The speed-up is often much smaller than `n_procs` (or the number of physical cores of your CPU), this has different reasons. For a rule of thumb, the speed-up should be around `n/2` on a `n`-core-processor with `n` Julia processes.

### Unload FMU

After calculating the data, the FMU is unloaded and all unpacked data on disc is removed.


```julia
@everywhere unloadFMU(SharedModule.model_fmu)
```

### Summary

In this tutorial it is shown how multiprocessing with `Distributed.jl` can be used to improve the performance for calculating a batch of FMUs.
