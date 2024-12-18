### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 11d8e234-287c-4fd1-b30d-f73fc728a4a8
begin
	# Pkg needs to be used to force Pluto to use the current project instead of making an environment for each notebook
	using Pkg
	# this is redundant if you run it through start.jl, but to make sure...
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using PlutoUI
	PlutoUI.TableOfContents()
end

# ╔═╡ 7ac29850-1aba-11ef-30b0-43ca55fd1bc9
html"""
 <! -- this adapts the width of the cells to display its being used on -->
<style>
	main {
		margin: 0 auto;
		max-width: 2000px;
    	padding-left: max(160px, 10%);
    	padding-right: max(160px, 10%);
	}
</style>
"""

# ╔═╡ 26c5b7b8-c71b-4836-a0cf-68b6e3fbe326
md"""
# Introduction
## Who are we?

* Lecturer: Cdt Bart De Clerck / D30.20 / [bart.declerck@mil.be]()
* Assistant: Lt Thijs Verhaeghe / D30.20 / [thijs.verhaeghe@mil.be]()

## Why Modelling and Simulation

- What is modelling?

- What is simulation?

Reality is often too complex to calculate ..

## Documentation

All notebooks can be found on [GitHub](https://github.com/B4rtDC/ES313).

## Schedule (TBC)


### Theory

- 02/09: Introduction, Cellular Automaton + Game of Life
- 03/09: Physical Modelling
- 10/09: Physical Modelling (cont.) + Self-Organization
- 11/09: Optimisation Techniques
- 24/09: Linear Programming I
- 25/10: Linear Programming II
- 02/10: Applications of Linear Programming
- 22/10: Introduction to Discrete Event Simulation
- 23/10: Process Driven DES: SimJulia I
- 29/10: Process Driven DES II + Applications I
- 30/10: Applications with SimJulia II

### Practice

- 17/09: Julia refresher + visualisations
- 18/09: Cellular Automaton + Game of Life
- 01/10: Physical Modelling + Self-Organization
- 09/10: Optimisation Techniques I
- 15/10: Linear Programming
- 05/11: Discrete Event Simulation
- 06/11: Process Driven DES: broader scope
- 12/11: DES Applications
- 13/11: Performance

### Project

- 12/11: List of projects available
- we are available during contact hours
- 03/12: mandatory meeting: understanding of the problem
- 17/12: mandatory meeting: progress

## Evaluation

* Test: Oct - 2Hr (date TBC)
  - Cellular Automaton + Game of Life
  - Physical Modelling + Self-Organization
* Exam: Project with Oral Defense
  - Individual
  - Complete analysis: abstraction, model, comparison and/or optimisation, visualisation

## Julia setup
The `readme.md` of the `setup` folder has instructions on how to configure your laptop and how to run the notebooks for the course. 
"""

# ╔═╡ Cell order:
# ╟─11d8e234-287c-4fd1-b30d-f73fc728a4a8
# ╟─7ac29850-1aba-11ef-30b0-43ca55fd1bc9
# ╟─26c5b7b8-c71b-4836-a0cf-68b6e3fbe326
