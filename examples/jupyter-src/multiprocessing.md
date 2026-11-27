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
     [0.08233871159745654, 0.12449227319747291]
     [0.22104442418672965, 0.8222053447060007]
     [0.7566449013514509, 0.694905241707605]
     [0.5531822092846187, 0.21527450990879304]
     [0.5012278737348452, 0.6817106884740023]
     [0.977490356513493, 0.8681508999794321]
     [0.3128835023342942, 0.24145171305920643]
     [0.05396808275882903, 0.22894107868283464]
     [0.6940779735513647, 0.14865807256031882]
     [0.3311318561674551, 0.49015440873801963]
     [0.07970593783965141, 0.2929713746632324]
     [0.3662767458701133, 0.7741557871304677]
     [0.33701640914538034, 0.7340390845175944]
     [0.18926895631270035, 0.1962609198826195]
     [0.7992080507285637, 0.5804588864231888]
     [0.4299364287254044, 0.8658070758256847]



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
     Range (min … max):  1.820 s …   1.849 s  ┊ GC (min … max): 0.06% … 0.40%
     Time  (median):     1.831 s              ┊ GC (median):    0.36%
     Time  (mean ± σ):   1.833 s ± 14.482 ms  ┊ GC (mean ± σ):  0.27% ± 0.19%
    
      █                    █                                  █  
      █▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█ ▁
      1.82 s         Histogram: frequency by time        1.85 s <
    
     Memory estimate: 64.21 MiB, allocs estimate: 4201025.



### Single Threaded Batch Execution
To compute a batch we can collect multiple evaluations. In a single threaded context we can use the same FMU for every call.


```julia
println("Single Threaded")
@benchmark collect(runCalcFormatted(SharedModule.model_fmu, i) for i in input_values)
```

    Single Threaded
    




    BenchmarkTools.Trial: 1 sample with 1 evaluation per sample.
     Single result which took 29.229 s (0.08% GC) to evaluate,
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
     Single result which took 15.838 s (0.00% GC) to evaluate,
     with a memory estimate of 124.14 KiB, over 2347 allocations.



As you can see, there is a significant speed-up in the median execution time. But: The speed-up is often much smaller than `n_procs` (or the number of physical cores of your CPU), this has different reasons. For a rule of thumb, the speed-up should be around `n/2` on a `n`-core-processor with `n` Julia processes.

### Unload FMU

After calculating the data, the FMU is unloaded and all unpacked data on disc is removed.


```julia
@everywhere unloadFMU(SharedModule.model_fmu)
```

### Summary

In this tutorial it is shown how multiprocessing with `Distributed.jl` can be used to improve the performance for calculating a batch of FMUs.
