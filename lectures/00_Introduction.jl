### A Pluto.jl notebook ###
# v0.20.13

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

* Lecturer: Prof Bart De Clerck / D30.20 / [bart.declerck@mil.be]()
* Assistant: Capt Thijs Verhaeghe / D30.20 / [thijs.verhaeghe@mil.be]()

## Why Modeling and Simulation
Reality is often too complex, costly, time-consuming, dangerous, or simply unavailable for direct experimentation or complete analytical calculation.

!!! info "Modeling"
	The process of creating a simplified or abstract representation (a model) of a real-world system, phenomenon, or process. The goal is to capture the essential features, variables, relationships, and dynamics relevant to a specific question or objective, while deliberately omitting non-essential details to make the system easier to understand, analyze, or manipulate. Models can be conceptual, physical, mathematical, or computational.

``\rightarrow `` this provides the blueprint of a system.

!!! info "Simulation"
	The process of implementing and running a model of a real-world system or process over time. It involves executing the model's rules, equations, or logic, often computationally, to observe its dynamic behavior, study its evolution under different conditions, predict future outcomes, or generate data for analysis. 

``\rightarrow `` this allows us to use the blueprint in a practical and controlled way, overcoming the limitations of direct real-world interaction or purely analytical methods.

A typical workflow is shown in the illustration below: 
"""

# ╔═╡ fda5bb2a-3f5b-46a2-80c5-293e80c08a57
LocalResource("./lectures/img/MS_process.png", :width=>400)

# ╔═╡ f8beb30b-a3ba-4fa5-b397-64d72175dc4d
begin
	# Problem definition
	problem_content = md"""!!! tip "Problem definition"
			* What is the system or process to be studied? 
			* What specific question(s) need to be answered?
			* What problem(s) need to be solved?

		!!! tip "Objective setting"
			What specific outcomes, metrics, or insights are desired from the M&S effort?
			
			E.g. predict throughput, minimize waiting time, compare strategies, understand sensitivity).
		"""
	problem = PlutoUI.details("Problem definition & objective setting", problem_content, open=false)

	system_analysis_content = md"""
		* Information gathering: data, expert knowledge, and existing theories about the system's components, behaviors, interactions, and environment.
		* Indentify key elements: determine the crucial entities, variables, parameters, relationships, and processes that influence the system's behavior relevant to the objectives.

		This study can lead to a "conceptual model": a high-level, often qualitative, representation of the system (schematic)
		!!! warning "Warning"
		    Always Explicitly list the assumptions made to simplify the model!
		"""
	system = PlutoUI.details("System analysis & conceptual modeling", system_analysis_content, open=false)
	
	formal_model_content = md"""
		This involves several steps and design choices:
		* data representation and requirements
		* modeling technique
		* translation of conceptual model into a formal, unambiguous representation
		* implementation of the formal representation into code

		!!! tip "Verification "
			*Did we build the model right?*

		    This can included testing with simple/known inputs where the output can be manually calculated or analytically derived. 

			``\Rightarrow`` this ensure the computer code accurately implements the formal model description.

		!!! tip "Validation "
			*Did we build the right model?*

		    This can included:
			* comparing model output against real-world data, against analytical models or results from other validated simulations
			* sensitivity analysis (does the model respond plausibly to parameter changes?), 
			* involving subject matter experts (SMEs) to review model behavior and outputs (aka "face validation").

			``\Rightarrow`` this assess whether the model's behavior and outputs are a reasonable representation of the real-world system for the intended purpose.
		
		"""
	formal_model = PlutoUI.details("Formal model development", formal_model_content, open=false)

	experiment_content = md"""
	* Define scenarios: determine the specific conditions, parameter sets, or configurations to be simulated.
	* Plan runs: determine the simulation length, warm-up period (if needed), number of replications (runs with different random seeds) to achieve statistical confidence.
	* Execute simulations: run the verified and validated model according to the experimental design, collecting the necessary output data.
	"""
	
	experiment = PlutoUI.details("Experiment design & simulation execution", experiment_content, open=false)

	output_content = md"""
		* Process the raw simulation output into actionable data
		* Statistical analysis
		* Visualizations
		* Sensitivity analysis 

		``\Rightarrow`` all of these contribute to an interpretation of the results in the context of the original problem and objectives.
		"""

	output = PlutoUI.details("Output analysis & interpretation", output_content, open=false)

	conclusion_content = md"""
		At the end of the cycle, you are likely to establish a final report including:
		* The problem definition, assumptions, conceptual and formal models, implementation details, verification and validation activities
		* Conclusions and recommendations
		* Limitations and/or room for improvement
		"""

	conclusion = PlutoUI.details("Documentation and reporting", conclusion_content, open=false)
	
	PlutoUI.details("M&S workflow", [problem,system,formal_model,experiment,output,conclusion], open=true)
end

# ╔═╡ d0e8fe4b-8b76-4d95-9872-ba16d09ad217
md"""
## Course overview
The following topics will be adressed during this course:
* Introduction
* Cellular automata
* Physical modeling & self-organization
* Networks (graphs) & Agent-based modeling
* Optimisation techniques
* Monte Carlo Methods
* Discrete Event Simulation (DES)
* Verification, validation & analysis
* Practical skills (visualisations, data manipulation, performance benchmarking)
* Project work (mid-November ``\rightarrow`` December)

## Evaluation
* Test in Otober, 2Hr, date TBD.
* Exam: Individual project with oral defense that illustrates the complete M&S pipeline
"""

# ╔═╡ 2efa8619-49fc-41de-af5e-b0b1e11e38db
md"""
!!! warning "Heads up!"
	For your project, you won't use or need everything covered in this course — that is a feature, and not a bug.  

	However, the combined content covered by all the projects typically goes beyond what the course includes, showing that students begin exploring relevant concepts on their own to help solve specific problems.
"""

# ╔═╡ 357eb999-404d-4c59-8c61-dea9ce4b2b1e
md"""
## Reference material

All notebooks can be found on [GitHub](https://github.com/B4rtDC/ES313). Additional suggested reading material includes the following books:
* [Modeling And Simulation - An application-oriented introduction](https://link.springer.com/book/10.1007/978-3-642-39524-6)
* [Simulation-Based Optimization - Parametric Optimization Techniques and Reinforcement Learning](https://link.springer.com/book/10.1007/978-1-4899-7491-4)
* [Stochastic Simulation and Monte Carlo Methods](https://link.springer.com/book/10.1007/978-3-642-39363-1)
* [Use Cases of Discrete Event Simulation](https://link.springer.com/book/10.1007/978-3-642-28777-0)
* [Fundamentals of queueing theory](https://onlinelibrary.wiley.com/doi/book/10.1002/9781119453765)
* [Convex Optimization](https://web.stanford.edu/~boyd/cvxbook/)
* [Discrete-Event Modeling and Simulation - A Practitioner's Approach](https://www.routledge.com/Discrete-Event-Modeling-and-Simulation-A-Practitioners-Approach/Wainer/p/book/9781420053364)
* [Think Complexity](https://greenteapress.com/wp/think-complexity-2e/)
"""

# ╔═╡ e89bee34-39b8-4558-b7d5-6e9872e9ded4
md"""
## Schedule (TBC)

### Theory
- 03 Sep
- 11 Sep
- 18 Sep
- 02 Oct
- 03 Oct => cancelled
- 17 Oct
- 24 Oct
- 31 Oct
- 06 Nov


### Practice
- 04 Sep
- 12 Sep
- 19 Sep
- 25 Sep
- 26 Sep
- 10 Oct
- 16 Oct
- 23 Oct
- 30 Oct
- 07 Nov
- 13 Nov
- 14 Nov


### Project timings

- early November: list of projects available
- no ex cathedra classes, but we are available during contact hours
- 04+05 Dec: mandatory meeting: understanding of the problem
- 18 + 19 Dec: mandatory meeting: progress
"""

# ╔═╡ cd6436f1-005a-495f-bc2b-fb519d0139dc
md"""
## Setup
The `readme.md` of the `setup` folder has instructions on how to configure your laptop and how to run the notebooks for the course. """

# ╔═╡ Cell order:
# ╟─11d8e234-287c-4fd1-b30d-f73fc728a4a8
# ╟─7ac29850-1aba-11ef-30b0-43ca55fd1bc9
# ╟─26c5b7b8-c71b-4836-a0cf-68b6e3fbe326
# ╟─fda5bb2a-3f5b-46a2-80c5-293e80c08a57
# ╟─f8beb30b-a3ba-4fa5-b397-64d72175dc4d
# ╟─d0e8fe4b-8b76-4d95-9872-ba16d09ad217
# ╟─2efa8619-49fc-41de-af5e-b0b1e11e38db
# ╟─357eb999-404d-4c59-8c61-dea9ce4b2b1e
# ╟─e89bee34-39b8-4558-b7d5-6e9872e9ded4
# ╟─cd6436f1-005a-495f-bc2b-fb519d0139dc
