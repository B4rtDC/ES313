# ES313
This repository contains the course support material for ES313 - Mathematical Modeling and Simulation. The course covers concepts such as cellular automata, diffusion processes, self-organization, and discrete event simulation. In addition to these concepts, several optimization techniques will also be introduced. You will learn to create abstract models of engineering problems, implement these models using computer simulations, and analyze the results to propose optimal solutions.

During the practical sessions, you will develop your skills by tackling small problems. A significant part of the course involves a project where you will apply the modeling and optimization methods to solve a real-world problem. By the end of the course, you should be able to apply these techniques to a broad range of problems typically encountered in engineering, make well-informed decisions, and effectively communicate your conclusions.

## Approach
All course material, both for lectures and practical sessions, is provided as Pluto notebooks. A self-contained project environment is provided, so in principle, you'll need to do the configuration only once, and then you can always work in the same way without any issues or missing dependencies. If you do not remember how environments work, please refer to the [manual](https://docs.julialang.org/en/v1/manual/code-loading/#Environments-1).

The course environment is pinned to Julia v1.10.x. On personal Windows, MacOS and Linux computers, install [Juliaup](https://github.com/JuliaLang/juliaup) first and then install the 1.10 channel with `juliaup add 1.10`. On the CDN Windows 11 Enterprise machine, use the installed Julia 1.10 executable at `C:\Program Files\Julia-1.10\bin\julia.exe`. The setup scripts will stop with an error when run with another Julia version.

## Getting started
Follow the [setup instructions](/setup/readme.md) (only required once).

Assuming the setup went well, you can start by running the `start.jl` script in the `setup` folder with `-t auto` so Julia uses as many threads as your hardware exposes. This will start a Pluto server, activate the course's environment, and open a new webpage.
