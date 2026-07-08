### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 1d6260d4-f663-11ea-03da-efe9ed63f9bd
begin
	# Pkg needs to be used to force Pluto to use the current project instead of making an environment for each notebook
	using Pkg
	# this is redundant if you run it through start.jl, but to make sure...
	while !isfile("Project.toml") && !isdir("Project.toml")
        cd("..")
    end
    Pkg.activate(pwd())
	using PlutoUI
	PlutoUI.TableOfContents()
end

# ╔═╡ f231418d-4bbc-46a1-bb65-5b1d14141b31
# Dependencies
begin
using NativeSVG # SVG plotting library
using Plots    # for random related activities
using Printf   # for fancy text rendering
using Random   # reproducible random experiments
using Statistics
end

# ╔═╡ a62f8ca0-4680-4a73-8333-8c56b385839f
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

# ╔═╡ e6ff0e98-f662-11ea-03a7-e3d09e6272a6
md"""# Physical Modelling

Port of [Think Complexity chapter 7](http://greenteapress.com/complexity2/html/index.html) by Allen Downey.


!!! info "Physical modelling"
	The process of creating a representation or simulation of a physical system or phenomenon using mathematical equations, computational techniques, or tangible objects. 

``\Rightarrow`` this is a way to understand, predict, or analyze how something behaves in the real world by mimicking its properties and interactions.

Different physical processes can be modelled using cellular automata, especially those where local interactions lead to emergent behavior. For example: in 1952 Alan Turing published a paper called “The chemical basis of morphogenesis”, which describes the behavior of systems involving two chemicals that diffuse in space and react with each other. He showed that these systems produce a wide range of patterns, depending on the diffusion and reaction rates, and conjectured that systems like this might be an important mechanism in biological growth processes, particularly the development of animal coloration patterns. While Turing’s model is based on differential equations, it can also be implemented using a cellular automaton.

!!! info "Emergent behavior"
	When a system produces complex, often unexpected patterns or properties that arise from the interactions of its simpler parts: 
	
	*The whole is greater than the sum of its parts*

We will have a look at different applications where cellular automata are useful physical models.
"""

# ╔═╡ 737c3da8-15ce-4f05-8c6b-c1eae0998630
md"""## From Pattern to Model

The examples below are visually interesting, but the modelling question is always more precise:

| Model | State variable | Local mechanism | Observable |
|:---|:---|:---|:---|
| diffusion | concentration | flow from high to low concentration | total mass, roughness |
| reaction-diffusion | two concentrations | diffusion, reaction, feed, removal | pattern contrast, total amounts |
| percolation | open/closed and wet/dry cells | connectivity through local neighbors | percolation probability |
| sand pile | local slope | threshold toppling | avalanche size and duration |

This gives us a modelling cycle:

1. choose a state representation;
2. state the local update rule;
3. decide what is held fixed at the boundary;
4. simulate;
5. measure an observable and compare it across parameter values.
"""

# ╔═╡ 2abf49e0-f663-11ea-25f3-2f9229de732e
md"""## Diffusion

!!! tip "Single chemical diffusion model"
	A 2-dimensional CA that adheres to the following principles:
	* each cell holds a continuous quantity (usually between 0 and 1) that represents the concentration of the chemical.
	* the diffusion process is modelled by comparing each cell with the average of its neighbors. If the concentration of the center cell exceeds the neighborhood average, the chemical flows from the center to the neighbors. If the concentration of the center cell is lower, the chemical flows the other way.
	* a diffusion constant, ``r``, relates the difference in concentration to the rate of flow ``c``: ``\Delta = r \cdot c``

Example next state computation for the central cell in the grid:

$(LocalResource("./lectures/img/simple_diffusion.png", :width => 600))

We can implement this as follows:
"""

# ╔═╡ 40373f12-f663-11ea-256c-abd1458a8e85
"""
	applydiffusion(array::Array{Float64, 2}, r::Float64=0.1)

Apply simple diffusion process on an `array`, given the diffusion coefficient `r`
"""
function applydiffusion(array::Array{Float64, 2}, r::Float64=0.1)
	# input validation
    0. < r < 1 ? nothing : throw(ArgumentError("`r` should be between zero and one."))
	# actual work
	nr_y, nr_x = size(array)
    out = deepcopy(array)
    for y in 2:nr_y-1
        for x in 2:nr_x-1
            c = array[y-1, x] + array[y, x-1] + array[y, x+1] + array[y+1, x] - 4*array[y, x]
            out[y, x] += r*c
        end
    end
	
    return out
end

# ╔═╡ 52f4e280-f663-11ea-38a4-c52a7b06b564
md"""visualisation:"""

# ╔═╡ 61437b46-f663-11ea-12c6-2ff992812dca
"""
	visualizearray(array::Array{Float64, 2}, dim)

Make a graphical representation of the values in an `array`. `dim` is a scaling factor for the illustration. 

The plot uses grayscale varying between white (0) and black (1).
"""
function visualizearray(array::Array{Float64, 2}, dim)
    (nr_y, nr_x) = size(array)
    width = dim * (nr_x - 1)
    height = dim * (nr_y - 1)
    Drawing(width=width, height=height) do
		for (j, y) in enumerate(2:nr_y-1)
			for (i, x) in enumerate(2:nr_x-1)
				gray = 80*(1-array[y, x])+10
				fill = "rgb($gray%,$gray%,$gray%"
				rect(x=i*dim, y=j*dim, width=dim, height=dim, fill=fill)
			end
		end
	end
end

# ╔═╡ 358ac3e2-f666-11ea-2058-11eedeabff5f
"""
	Diffusion

A struct used to hold and instantiate a diffusion process. 
Initially, everything is set to zero except for a square of ones in the center.
"""
mutable struct Diffusion
	array::Array{Float64, 2}
	function Diffusion()
		diffusion = new(zeros(Float64, 11, 11))
		diffusion.array[5:7, 5:7] = ones(Float64, 3, 3)
		diffusion
	end
end

# ╔═╡ 863a3fa4-f664-11ea-2597-8f18f2a862ac
diffusion = Diffusion();

# ╔═╡ 966fc752-f666-11ea-1794-195433f4cce5
visualizearray(diffusion.array, 30)

# ╔═╡ b0148fb4-f664-11ea-2d64-976658b08661
@bind togglediffusion html"<input type=button value='Next'>"

# ╔═╡ b25969c4-f665-11ea-222b-df9786a710d2
if togglediffusion === "Next"
	diffusion.array = applydiffusion(diffusion.array)
	visualizearray(diffusion.array, 30)
end

# ╔═╡ 4c3d12f5-0606-4f7f-96f4-d687e7b59fa4
md"Situation after 1,000 iterations:"

# ╔═╡ 95dc78e8-f667-11ea-1c07-8f5cc11b011b
let
	diffusion2 = Diffusion();
	for _ in 1:1000
    	diffusion2.array = applydiffusion(diffusion2.array)
	end
	visualizearray(diffusion2.array, 30)
end

# ╔═╡ 98df4f0f-2b67-4e4d-b967-f8f151af4976
md"""### Measuring Diffusion

Diffusion is more than a smoothing animation. Two useful observables are:

- **mass**: the total amount of chemical in the grid;
- **roughness**: the variance of the concentration field.

In a closed system, diffusion conserves mass. In this implementation the boundary is fixed at zero, so it acts like an absorbing edge: chemical can effectively leave the modelled region. That boundary choice is part of the model.
"""

# ╔═╡ 03f96645-e314-46bb-bc12-28b1fb0b600e
"""
	diffusion_observables(; steps=60, r=0.1)

Run the diffusion model and return total mass and concentration variance over time.
"""
function diffusion_observables(; steps::Int=60, r::Float64=0.1)
	model = Diffusion()
	time = collect(0:steps)
	mass = Float64[]
	roughness = Float64[]
	for step in time
		interior = model.array[2:end-1, 2:end-1]
		push!(mass, sum(model.array))
		push!(roughness, var(vec(interior)))
		step == steps && break
		model.array = applydiffusion(model.array, r)
	end
	
	return (; time, mass, roughness)
end

# ╔═╡ 0768d49b-1e26-4cec-b370-4ffd8d44dba2
let
	stats = diffusion_observables(steps=80, r=0.1)
	p1 = plot(stats.time, stats.mass, xlabel="Step", ylabel="Total mass", label="", marker=:circle)
	p2 = plot(stats.time, stats.roughness, xlabel="Step", ylabel="Variance", label="", marker=:circle)
	plot(p1, p2, layout=(1, 2), size=(900, 320))
end

# ╔═╡ c03905f2-f667-11ea-3484-b111f7c14f60
md"""## Reaction-Diffusion
We now consider a more elaborate situation:


!!! tip "two-chemical reaction-diffusion model"
	A 2-dimensional CA, where we  have two chemicals: ``a`` and ``b``. This system is subject to the following principles:
	* we have ``a`` and ``b`` type cells. Each cell holds a continuous quantity (usually between 0 and 1) that represents the concentration of the specific chemical.
	* both are subject to a diffusion process, which is modelled by comparing each cell with the average of its neighbors (same as before), using a specific diffusion rate for each chemical: ``r_a`` and ``r_b``.
	* both interact through a chemical reaction process, where it is assumed that the reaction consumes ``a`` and produces ``b``, so this contribution will be negative for ``a`` and positive for ``b`` as follows: ``ab^2``
	* we add ``a`` to the system in such a way that the feed rate is maximal when the quantity of ``a`` is near zero: ``f  (1 - a)``
	* we remove ``b`` from the system in such a way that the removal rate is minimal when ``b`` is close to zero: ``(f + k) b`` 

	
As long as the rate parameters are not too high, the values of A and B usually stay between 0 and 1."""

# ╔═╡ cf7c1a2c-f667-11ea-358f-df431ec27476
"""
	applyreactiondiffusion(a::Array, b::Array, ra::Float64=0.5, rb::Float64=0.25, f::Float64=0.055, k::Float64=0.062)

Apply the reaction-diffusion model for a situation with two chemicals, of which the concentrations are stored in `a` and `b` respectively.

# Parameters:
- `ra`: The diffusion rate of ``a`` (analogous to `r` in the previous section).
- `rb`: The diffusion rate of ``b``. In most versions of this model, `rb` is about half of `ra`.
- `f`: The “feed” rate, which controls how quickly A is added to the system.
- `k`: The “kill” rate, which controls how quickly B is removed from the system.

*Note*: `ca` and `cb` are the result of applying a diffusion to ``a`` and ``b``. Multiplying by `ra` and `rb` yields the rate of diffusion into or out of each cell.
"""
function applyreactiondiffusion(
        a::Array{Float64, 2}, 
        b::Array{Float64, 2}, 
        ra::Float64=0.5, rb::Float64=0.25, 
        f::Float64=0.055, k::Float64=0.062)
    nr_y, nr_x = size(a)
    a_out = deepcopy(a)
    b_out = deepcopy(b)
    for y in 2:nr_y-1
        for x in 2:nr_x-1
            reaction = a[y, x] * b[y, x]^2
            ca = 0.25*(a[y-1, x] + a[y, x-1] + a[y, x+1] + a[y+1, x]) - a[y, x]
            cb = 0.25*(b[y-1, x] + b[y, x-1] + b[y, x+1] + b[y+1, x]) - b[y, x]
            a_out[y, x] += ra*ca - reaction + f * (1 - a[y, x])
            b_out[y, x] += rb*cb + reaction - (f+k) * b[y, x]
        end
    end
	
    return a_out, b_out
end

# ╔═╡ 23f98030-f668-11ea-389b-ff911adaadfd
"""
	ReactionDiffusion

A struct used to hold and instantiate a reaction-diffusion process. 
The initial state holds a maximum value of `a`, random values for `b` (between 0 and 0.1, except for the center, where the values are between 0.1 and 0.2).
"""
mutable struct ReactionDiffusion
	a::Array{Float64, 2}
    b::Array{Float64, 2}
	function ReactionDiffusion()
		reactiondiffusion = new(ones(Float64, 258, 258), rand(Float64, 258, 258)*0.1)
		reactiondiffusion.b[129-12:129+12, 129-12:129+12] += ones(Float64, 25, 25)*0.1
		reactiondiffusion
	end
end

# ╔═╡ 3c706f38-f669-11ea-2266-f743535073b5
reactiondiffusion = ReactionDiffusion();

# ╔═╡ 1b551fc2-f669-11ea-0d2f-ad0e089592d8
visualizearray(reactiondiffusion.b, 2)

# ╔═╡ e1988846-f668-11ea-1b26-8f7dca1bb4e7
@bind togglereactiondiffusion html"<input type=button value='Next (+ 500 iterations)'>"

# ╔═╡ dda066c0-f668-11ea-3096-bdea16f40db7
# You can consider different values for f and k.
# f = 0.035, 0.055, 0.039 k = 0.057, 0.062, 0.065
begin 
f = 0.039
k = 0.065
if togglereactiondiffusion === "Next (+ 500 iterations)"
	for _ in 1:500
		reactiondiffusion.a, reactiondiffusion.b = applyreactiondiffusion(reactiondiffusion.a, reactiondiffusion.b, 0.5, 0.25, f, k)
	end
	visualizearray(reactiondiffusion.b, 2)
end
end

# ╔═╡ 1734b35e-f66a-11ea-10b4-317d12008809
md"""Since 1952, observations and experiments have provided some support for Turing’s conjecture. At this point it seems likely, but not yet proven, that many animal patterns are actually formed by reaction-diffusion processes of some kind."""

# ╔═╡ ba90d318-34b9-47ec-981e-5e733d855da2
md"""### Measuring Reaction-Diffusion

Compared with pure diffusion, this model has sources and sinks:

- the feed term adds chemical ``A``;
- the kill term removes chemical ``B``;
- the reaction converts ``A`` into ``B``.

So the total amount of material is not conserved. A useful additional observable is the variance of ``B``: when spots or stripes develop, the field becomes more contrasted.
"""

# ╔═╡ 610cdf02-ddf4-4c4e-84db-9bfe998cb553
"""
	reactiondiffusion_observables(; n=80, steps=200, every=10, f=0.039, k=0.065, seed=2025)

Run a smaller seeded Gray-Scott experiment and collect aggregate diagnostics.
"""
function reactiondiffusion_observables(; n::Int=80, steps::Int=200, every::Int=10, f::Float64=0.039, k::Float64=0.065, seed::Int=2025)
	rng = MersenneTwister(seed)
	a = ones(Float64, n, n)
	b = rand(rng, Float64, n, n) .* 0.1
	center = n ÷ 2
	radius = max(2, n ÷ 20)
	b[center-radius:center+radius, center-radius:center+radius] .+= 0.1

	time = Int[]
	total_a = Float64[]
	total_b = Float64[]
	contrast_b = Float64[]
	for step in 0:steps
		if step % every == 0
			push!(time, step)
			push!(total_a, sum(a))
			push!(total_b, sum(b))
			push!(contrast_b, var(vec(b[2:end-1, 2:end-1])))
		end
		step == steps && break
		a, b = applyreactiondiffusion(a, b, 0.5, 0.25, f, k)
	end

	return (; time, total_a, total_b, contrast_b)
end

# ╔═╡ d22ef684-9b40-43b7-bdcb-a67d71cd5f8a
let
	stats = reactiondiffusion_observables()
	p1 = plot(stats.time, stats.total_a, xlabel="Step", ylabel="Total amount", label="A")
	plot!(p1, stats.time, stats.total_b, label="B")
	p2 = plot(stats.time, stats.contrast_b, xlabel="Step", ylabel="Variance of B", label="", marker=:circle)
	plot(p1, p2, layout=(1, 2), size=(900, 320))
end

# ╔═╡ 40f84b2e-f66a-11ea-1dc7-3ded9e11af06
md"""## Percolation
!!! info "Percolation"
	Percolation is a concept from physics and mathematics that describes how something (a fluid, information, or influence) spreads through a medium. 

Some examples of percolation include oil in rock formations, water in paper, hydrogen gas in micropores, but you could also consider coffee brewing.

**Note:** Percolation models are also used to study systems that are not literally percolation, including epidemics and networks (of electrical resistors).

!!! tip "Percolation of water in a wall"
	A 2-dimensional CA, where each cell is either “porous” with probability `q` or “non-porous” with probability `1-q`. This system is subject to the following principles:
	* The porous cells can be "dry" or "wet". When the simulation begins, all cells are considered “dry” except the top row, which is “wet”.
	* During each time step, if a porous cell has at least one wet neighbor, it becomes wet. Non-porous cells stay dry.
	* The simulation runs until it reaches a “fixed point” where no more cells change state.
	
	*Note*: due to the way the water propagation is modelled, it can also move upwards. You might link artefact to the capillary action.

We want to know the following related to this wall :
1. What is the probability that a random array contains a percolating cluster (the CA has a “percolating cluster” if there is a path of wet cells from the top to the bottom row).
2. How does that probability depend on `q`?
"""

# ╔═╡ 98caca4c-20db-4f19-ae8a-c0e6ff207148
md"""### Percolation as Connectivity

Percolation can also be read as a graph problem. Each porous cell is a node, and neighboring porous cells are connected by edges. A wall percolates when there is a connected path from the top row to the bottom row.

This is why percolation is useful beyond fluids: it is a simple model for connected components in networks, epidemic reachability, electrical conduction, and failure propagation.
"""

# ╔═╡ 7140fbf4-a30d-479a-a539-7f7c0a350bf4
md"We can implement the percolation as follows:"

# ╔═╡ 77dcd828-f66a-11ea-0942-c5d613d828b7
"""
	applypercolation(array::Array{Float64, 2})

Given an `array`, we update using the prescribed percolation rules.
"""
function applypercolation(array::Array{Float64, 2})
    nr_y, nr_x = size(array)
    out = deepcopy(array)
    for y in 2:nr_y-1
        for x in 2:nr_x-1
            if out[y, x] > 0.0
                c = array[y-1, x] + array[y, x-1] + array[y, x+1] + array[y+1, x]
                if c ≥ 0.5
                    out[y, x] = 0.5
                end
            end
        end
    end
	
    return out
end

# ╔═╡ 44c8b17a-f66b-11ea-39af-f554593e33eb
"""
	Wall

A struct used for the percolation process that holds the array with the values.

*Note*: a border is added for the visualisation and to account for the update rules.
"""
mutable struct Wall
	array::Array{Float64, 2}
	"""
		Wall(n, q)

	Generate a square `Wall` of size `n` x `n` with a probability `q` of being porous. The top row is initiated to be wet.
	"""
	function Wall(n, q)
    	array = zeros(Float64, n+2, n+2)
		array[2, 2:n+1] = ones(Float64, n)*0.5
		array[3:n+1, 2:n+1] = rand(Float64, n-1, n)
		for y in 3:n+1
			for x in 2:n+1
				if array[y, x] < q
					array[y, x] = 0.1
				else
					array[y, x] = 0.0
				end
			end
		end
		new(array)
	end
end

# ╔═╡ d9ccf8f8-f66b-11ea-2c81-0d771c2e900e
wall = Wall(40, 0.62);

# ╔═╡ e492630e-f66b-11ea-3aed-f37a400243be
visualizearray(wall.array, 10)

# ╔═╡ e048231c-f66b-11ea-191d-8517a6c65bc5
@bind togglepercolation html"<input type=button value='Next'>"

# ╔═╡ 11847488-f66c-11ea-1aca-4b1613dbfb8e
if togglepercolation === "Next"
	wall.array = applypercolation(wall.array)
	visualizearray(wall.array, 10)
end

# ╔═╡ e51771ec-f66c-11ea-1606-fd159b8d216f
md"""
### Probability of percolating
To get an estimate of the probability of a percolating cluster, we will generate many random arrays and test them."""

# ╔═╡ 2b9c8a86-f66c-11ea-0447-1fb7ba83d3a1
"""
	testpercolation(array::Array{Float64, 2}, vis=false)

Run a percolation process until convergence and subsequently count the number of "wet" cells on the bottom row. If any wet cells are found, the function returns true and false otherwise.

`vis` can be used to toggle the visualisation.
"""
function testpercolation(array::Array{Float64, 2}, vis=false)
	nr_y, nr_x = size(array)
	active_rows = 2:nr_y-1
	active_cols = 2:nr_x-1
	bottom_row = nr_y-1
    numberwet = count(x->x==0.5, array[active_rows, active_cols])
    while true
        array = applypercolation(array)
        if count(x->x==0.5, array[bottom_row, active_cols]) > 0
			if vis
				return true, visualizearray(array, 8) 
			else
            	return true
			end
        end
        newnumberwet = count(x->x==0.5, array[active_rows, active_cols])
        if numberwet == newnumberwet
            if vis
				return false, visualizearray(array, 8)
			else
            	return false
			end
        end
        numberwet = newnumberwet
    end
end

# ╔═╡ 9fe496ab-7277-4c99-8533-6c329b82b563
md"""Example:"""

# ╔═╡ c71f0f24-f66c-11ea-0ba7-d765f3998ed9
let
	# instantiate the wall
	wall = Wall(100, 0.6)
	# run the testpercolation function and render the results
	result, drawing = testpercolation(wall.array, true)
	@info "Percolation $(result ? "reached" : "did not reach") the bottom"
	# show the drawing
	drawing
end

# ╔═╡ 1254b21a-f66e-11ea-2b36-7985687edd02
"""
	estimateprob(;n=100, q=0.5, iters=100)

Estimate the percolation probability for a `Wall` of size `n`, initiated with a porous probability `q` based on `iters` estimates.
"""
function estimateprob(;n=100, q=0.5, iters=100)
    successes = 0
    for _ in 1:iters
        wall = Wall(n, q)
        successes += testpercolation(wall.array) ? 1 : 0
    end
    successes / iters
end

# ╔═╡ c828c986-5f12-4dab-8aac-d18d34ae6086
"""
	estimateprob_stats(; n=100, q=0.5, iters=100)

Estimate the percolation probability and an approximate Monte Carlo standard error.
"""
function estimateprob_stats(; n::Int=100, q::Float64=0.5, iters::Int=100)
	successes = 0
	for _ in 1:iters
		wall = Wall(n, q)
		successes += testpercolation(wall.array) ? 1 : 0
	end
	p = successes / iters
	se = sqrt(p * (1 - p) / iters)
	
	return (; p, se, successes, iters)
end

# ╔═╡ dda2cd12-f66c-11ea-3f31-837c9a749b5c
estimateprob(q = 0.60)

# ╔═╡ a92e9fe7-1cf7-4426-8221-c3e4946f4860
md"""
### Impact of `q` on the probability of percolating
We can use our ```estimateprob``` function to get an idea to what extent (and if) `q` has any impact on the probability of percolating.
"""

# ╔═╡ 2b6328b1-0384-4937-994b-ae8270824f42
begin
	# Different q values
	q_vals = collect(range(0.5, stop=0.7, length=20))
	# Associated probabilities and approximate Monte Carlo uncertainty
	percolation_stats = map(q -> estimateprob_stats(q=q, iters=50), q_vals)
	p_prob = [stat.p for stat in percolation_stats]
	p_se = [stat.se for stat in percolation_stats]
end

# ╔═╡ 952f559a-46bc-40ec-9d1f-1841e2240615
plot(q_vals, p_prob, ribbon=1.96 .* p_se, marker=:circle, label="estimated P(percolation)", xlabel="q", ylabel="Probability", ylim=(0, 1))

# ╔═╡ 258e9da9-dec2-47fc-b943-8bb3ff5aee05
md"""The shaded band is an approximate 95% Monte Carlo interval. It reminds us that the curve is not a deterministic function evaluation: each point is estimated from a finite number of random walls."""

# ╔═╡ 2a945f8f-26c8-4c8e-8632-e7cad95fc621
md"""
The rapid change in behavior around `q=0.58` is called a phase change, by analogy with phase changes in physical systems, like the way water changes from liquid to solid at its freezing point.

!!! info "Phase change"
	A phase change, or phase transition, is when a system shifts from one distinct state of matter or organization to another. 

	It is driven by changes in conditions where the system’s properties jump or shift dramatically.


"""

# ╔═╡ 340521e8-8c97-4c7d-85b9-93a37ee85563
md"""
### Estimating a critical value for `q`
We now know that a phase change is happening, but you might want to find a value ``q_{\text{crit}}``, such that the percolation probability is above a desired threshold ``P_{\text{crit}}``. 

This can be done in different ways. For example, you could use a bisection method (cf. numerical methods from last year). In the following, we will use a random walk to realise this.

!!! info "Random walk"
	A random walk is a mathematical concept where a "walker" moves step-by-step through a space, with each step’s direction or distance determined by chance.

	This optimisation approach is a form of local search (also see next year: DS425)

Applied on our problem, we can do this as follows:
* Starting from an initial value `q_0`, we construct a wall and compute its percolation probability `P`.
* Depending on the value of `p`, we increase or decrease the value of `q` by a fixed amount (e.g. 0.004).
* We stop the random walk when 1) no more changes occur 2) we are "close enough" to ``P_{\text{crit}}``
"""

# ╔═╡ d9fc2ec3-b3c3-41b3-8510-b599a1e8e059
"""
	findcritical(;n::Int=100, iters::Int=100, P_crit::Float64=0.7, q₀::Float64=0.5, δq::Float64=0.004,tol::Float64=0.02, maxiter::Int=100)

Determine the required value of `q` to match the required percolation probability `P_crit`. 

# Arguments
- n::Int=100: size of the wall
- iters::Int=100 number of iterations for a single estimate of `P` (cf. ```estimateprob```)
- P_crit::Float=0.7: the desired percolation probability
- q₀::Float=0.5: the inital value for the random walk
- δq::Float=0.004: the update step for the q-value
- tol::Float64=0.02: tolerance to stop computation
- maxiter::Int=100: maximum number of probability estimates
"""
function findcritical(;n::Int=100, iters::Int=100, P_crit::Float64=0.7, q₀::Float64=0.5, δq::Float64=0.004, tol::Float64=0.02, maxiter::Int=100)
	# initialise the values
	qs = [q₀]
	ps = Float64[]
	# run the optimisation
	while length(ps) < maxiter
		# compute the associated probability
		p = estimateprob(;n=n, q=qs[end], iters=iters)
		push!(ps, p)
		if abs(p - P_crit) < tol
			break
		elseif p > P_crit
			next_q = clamp(qs[end] - δq, 0.0, 1.0)
			next_q == qs[end] && break
			push!(qs, next_q)
		elseif p < P_crit
			next_q = clamp(qs[end] + δq, 0.0, 1.0)
			next_q == qs[end] && break
			push!(qs, next_q)
		end
	end

	return qs, ps
	
end

# ╔═╡ 501878b4-f66e-11ea-270f-d7542715acbb
qs, ps = findcritical(q₀=0.58)

# ╔═╡ 44719f1b-bcbd-4cc3-ab05-aa004f926f6c
plot(ps, xlabel="Iteration", ylabel="P(percolation)",label="", marker=:circle)

# ╔═╡ afd57d30-8a2c-45be-a2fe-091525f6b254
md"""### Tuned Criticality and Self-Organized Criticality

Percolation is a **tuned** critical system: we change `q` from the outside and observe a sharp transition around a critical value.

The sand pile below is different. It is slowly driven by adding grains, and it dissipates at the boundary when avalanches reach the edge. After many drops, the system settles into a statistically steady state with avalanche distributions that can be very broad. This is the idea of **self-organized criticality**: the system moves toward a critical-like state without us tuning a parameter such as `q`.
"""

# ╔═╡ 0a76134a-e735-4184-ac41-674174132f8e
md"""## Sand Piles

The sand pile model was [proposed by Bak, Tang and Wiesenfeld in 1987](https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.59.381). It is not meant to be a realistic model of a sand pile, but rather an abstraction that models physical systems with a large number of elements that interact with their neighbors.

!!! tip "Sand pile model"
	A 2-D cellular automaton that adheres to the following principles:
	- the state of each cell represents the slope of a part of a sand pile. 
	- During each time step, each cell is checked to see whether it exceeds a critical value, `K`, which is usually 3. If so, it “topples” and transfers sand to four neighboring cells: the slope of the cell is decreased by 4, and each of the neighbors is increased by 1. 
	- At the perimeter of the grid, all cells are kept at slope 0, so the excess spills over the edge.

> Experiment:
> 1. initialize all cells at a level greater than `K` and run the model until it stabilizes. 
> 2. observe the effect of small perturbations: choose a cell at random, increment its value by 1, and run the model again until it stabilizes.
> 3. for each perturbation, they measure `T`, the number of time steps the pile takes to stabilize, and `S`, the total number of cells that topple.

Most of the time, dropping a single grain causes no cells to topple, so `T=1` and `S=0`. But occasionally a single grain can cause an avalanche that affects a substantial fraction of the grid. The distributions of `T` and `S` turn out to be heavy-tailed, which supports the claim that the system is in a critical state.

!!! info "Heavy-tailed distribution"
	A probability distribution that has a tail that decays more slowly than an exponential distribution.

	Mathematically, the tail (i.e. ``x \rightarrow \infty``) satisfies ``P(X>x) \propto x^{-\alpha} (\alpha > 0)``

Visualisation of a heavy-tailed distribution:

$(LocalResource("./lectures/img/heavy_tail.png", :width => 400))

The sand pile model exhibits “self-organized criticality”, which means that it evolves toward a critical state without the need for external control or for “fine tuning” of any parameters. The model stays in a critical state as more grains are added.
"""

# ╔═╡ 3af0633c-3c5d-45ba-b590-0a433cd008ab
md"""
### Implementation
"""

# ╔═╡ dd7ef855-c9da-4984-a4d5-a7f81972027b
"""
	applytoppling(array::Array{Int64, 2}, K::Int64=3)

Given an `array` and a threshold value `K` above which the sand piles will topple, determine the new state.
"""
function applytoppling(array::Array{Int64, 2}, K::Int64=3)
    out = copy(array)
    (ydim, xdim) = size(array)
	# initiate counter
    numtoppled = 0
	# do the toppling
    for y in 2:ydim-1
        for x in 2:xdim-1
            if array[y,x] > K
                numtoppled += 1
                out[y-1:y+1,x-1:x+1] += [0 1 0;1 -4 1;0 1 0]
            end
        end
    end
	# reset boundaries
    out[1,:] .= 0
    out[end, :] .= 0
    out[:, 1] .= 0
    out[:, end] .= 0
	
    return out, numtoppled
end

# ╔═╡ d304fd4e-3321-48b3-9901-da061dca2f98
"""
	visualizepile(array::Array{Int64, 2}, dim, scale)

Make a graphical representation of the values in an `array`. `dim` is a scaling factor for the illustration. 

The plot uses grayscale going from black (0) to white (1). The values in the `array` are rescaled by the factor `scale` to be between zero and one.

`dim` is a scaling factor for the illustration. 
"""
function visualizepile(array::Array{Int64, 2}, dim, scale)
    (ydim, xdim) = size(array)
    width = dim * (xdim - 1)
    height = dim * (ydim - 1)
    Drawing(width=width, height=height) do
		for (j, y) in enumerate(2:ydim-1)
			for (i, x) in enumerate(2:xdim-1)
				gray = 100*(1-array[y,x]/scale)
				fill = "rgb($gray%,$gray%,$gray%"
				rect(x=i*dim, y=j*dim, width=dim, height=dim, fill=fill)
			end
		end
	end
end

# ╔═╡ daeb8116-72ac-4850-adbf-7a1705196558
"""
	steptoppling(array::Array{Int64, 2}, K::Int64=3)

Do a single toppling iteration for the `array` using threshold value `K` above which the sand piles will topple. I.e. this function will run until no more changes in the state occur.
"""
function steptoppling(array::Array{Int64, 2}, K::Int64=3)
    total = 0
    i = 0
    while true
        array, numtoppled = applytoppling(array, K)
        total += numtoppled
        i += 1
        if numtoppled == 0
			# after no more changes, return the state, the number of iterations and the total number of piles toppled.
            return array, i, total
        end
    end
end

# ╔═╡ 0555f705-85be-4e49-82c6-fee854070c0f
"""
	Pile

A struct used to hold and instantiate a sand pile. 
Initially, everything is set to the value `initial`, except for the boundaries, which are set to zero.
"""
mutable struct Pile
	array::Array{Int64, 2}
	function Pile(dim::Int64, initial::Int64)
		pile = zeros(Int64, dim, dim)
		pile[2:end-1, 2:end-1] = initial * ones(Int64, dim-2, dim-2)
		new(pile)
	end
end

# ╔═╡ 3e0d8751-4bd3-4a1f-943b-f2c92bf2fcab
"""
	drop(array::Array{Int64, 2})

Drop a new grain of sand on a random non-boundary element of the sand pile.
"""
function drop(array::Array{Int64, 2}, rng::AbstractRNG=Random.default_rng())
    (ydim, xdim) = size(array)
    y = rand(rng, 2:ydim-1)
    x = rand(rng, 2:xdim-1)
    array[y,x] += 1
	
    return array
end

# ╔═╡ 63e73256-d9e4-4edc-9f52-192fcda9a9b4
"""
	runtoppling(array::Array{Int64, 2}, iter=200)

Given an `array`, run `iter` iterations where the following happens:
1. a grain of sand is dropped
2. the toppling is run.
"""
function runtoppling(array::Array{Int64, 2}, iter=200)
    array, steps, total = steptoppling(array, 3)
    for _ in 1:iter
        array = drop(array)
        array, steps, total = steptoppling(array, 3)
    end
	
    return array
end

# ╔═╡ 58b2953c-5f15-41fa-a6ec-2c990562b411
md"""### Example"""

# ╔═╡ 39042d4a-d777-4e05-a857-dc8e55003d89
md"""Construct and visualize a sand pile, with all values initiated at 10. This should lead to a square that has the same value (10) in every cell."""

# ╔═╡ 26a1ddd2-67a3-498e-b653-43af7c9aeace
begin
	pile20 = Pile(22, 10);
	visualizepile(pile20.array, 30, 10)
end

# ╔═╡ bcaf050a-8da2-4dc1-99eb-90bc05f61386
md"""Visualize the state after the toppling."""

# ╔═╡ 9e666fb4-f6da-426b-b35f-587014f79814
begin
	pile20.array, steps, total = steptoppling(pile20.array);
	@info "pile20 toppled in $(steps) steps and a total of $(total) topplings occurred."
	visualizepile(pile20.array, 30, 10)
end

# ╔═╡ 874cacb5-332e-4672-beca-b58f260e0f73
@bind toggletoppling html"<input type=button value='Drop & topple (x200)'>"

# ╔═╡ ade0a573-059f-4f12-8627-45ea734c65a2
if toggletoppling === "Drop & topple (x200)"
	for _ in 1:200
		pile20.array = drop(pile20.array)
    	pile20.array, steps, total = steptoppling(pile20.array)
	end
	visualizepile(pile20.array, 30, 10)
end

# ╔═╡ b3505179-3861-46fc-b0fb-7fac96c95dd2
md"""
We can repeat this 'drop and topple' idea for many times. Every time, we end up with a configuration that looks similar to the configuration after 200 drops. In fact, the pile is now in a steady state where its **statistical properties** don’t change over time."""

# ╔═╡ da9e17e4-9490-4927-87bc-99dce93b15aa
md"""### Retrieving the heavy-tailed distribution
Recall from earlier that a heavy-tailed distribution is a distribution that has a tail that decays more slowly than an exponential distribution (``x \rightarrow \infty`` satisfies ``P(X>x) \propto x^{-\alpha} (\alpha > 0)``).

> If the sand pile model is in a critical state, we expect to find heavy-tailed distributions for quantities like the duration and size of avalanches. 
>
> We try to retrieve this relation for a sand pile with n=50 and an initial level of 30. 
>
> For a configurable number of random drops, we run this until equilibrium.
> 



"""

# ╔═╡ 7006688d-5e49-4d90-9aac-9608faf707a5
@bind sandpile_trials Slider(2_000:2_000:20_000; default=8_000, show_value=true)

# ╔═╡ c7872f6b-9c9f-4b2c-9dda-531c6edf5501
begin
	rng = MersenneTwister(2025)
	pile50 = Pile(50, 30);
	durations = Int64[]
	avalanches = Int64[]	
	for _ in 1:sandpile_trials
		pile50.array = drop(pile50.array, rng)
		pile50.array, steps, total = steptoppling(pile50.array)
		push!(durations, steps)
		push!(avalanches, total)
	end
	
	# only keep durations above 1 and avalanches more than 0 (majority of observations)
	filter!(steps->steps>1, durations), filter!(total->total>1, avalanches);
	nothing
end

# ╔═╡ 69f25cf7-7319-4d88-82f4-b43d86afa8f6
begin
	"""
		complementary_cdf(values)
	
	Return points for the complementary cumulative distribution P(X > x).
	"""
	function complementary_cdf(values::Vector{Int64})
		xs = sort(unique(values))
		length(xs) <= 1 && return Int64[], Float64[]
		xs = xs[1:end-1]
		sorted_values = sort(values)
		n = length(values)
		ps = [sum(sorted_values .> x) / n for x in xs]
		
		return xs, ps
	end

	"""
		fit_tail_powerlaw(xs, ps; xmin)
	
	Fit log10(P(X>x)) = intercept + slope * log10(x) for x >= xmin.
	"""
	function fit_tail_powerlaw(xs::Vector{Int64}, ps::Vector{Float64}; xmin::Real)
		mask = (xs .>= xmin) .& (ps .> 0)
		count(mask) < 2 && return (intercept=NaN, slope=NaN, alpha=NaN)
		X = [ones(count(mask)) log10.(Float64.(xs[mask]))]
		Y = log10.(ps[mask])
		β = X \ Y
		
		return (intercept=β[1], slope=β[2], alpha=-β[2])
	end

	nothing
end

# ╔═╡ 9299334a-935e-461b-afea-5b6c3d094a46
begin
	# durations part
	duration_xs, duration_ps = complementary_cdf(durations)
	duration_xmin = isempty(duration_xs) ? 0 : max(2, round(Int, quantile(duration_xs, 0.75)))
	duration_fit = fit_tail_powerlaw(duration_xs, duration_ps; xmin=duration_xmin)


	# avalanches part
	avalanche_xs, avalanche_ps = complementary_cdf(avalanches)
	avalanche_xmin = isempty(avalanche_xs) ? 0 : max(2, round(Int, quantile(avalanche_xs, 0.75)))
	avalanche_fit = fit_tail_powerlaw(avalanche_xs, avalanche_ps; xmin=avalanche_xmin)

	scatter(duration_xs, duration_ps, xaxis=:log10, yaxis=:log10, label="durations", alpha=0.5)
	if isfinite(duration_fit.alpha)
		plot!(duration_xs, 10 .^ (duration_fit.slope .* log10.(duration_xs) .+ duration_fit.intercept), color=:blue, label=@sprintf("duration tail α: %.2f", duration_fit.alpha), alpha=0.5)
	end
	scatter!(avalanche_xs, avalanche_ps, xaxis=:log10, yaxis=:log10, label="avalanche size", alpha=0.5)
	if isfinite(avalanche_fit.alpha)
		plot!(avalanche_xs, 10 .^ (avalanche_fit.slope .* log10.(avalanche_xs) .+ avalanche_fit.intercept), color=:green, label=@sprintf("avalanche tail α: %.2f", avalanche_fit.alpha), alpha=0.5)
	end
	plot!(legendposition=:bottomleft)
	ylims!(1e-5,1)
	xlabel!("Value")
	ylabel!("P(X>x)")

	
end

# ╔═╡ b989e963-8fca-49d6-9f36-1ac6f24923f1
md"""The fitted line is a diagnostic, not proof of a power law. Tail fits are sensitive to sample size, the chosen fitting range, and finite grid effects. The robust conclusion for this lecture is qualitative: avalanches are not all the same size, and rare large events matter."""

# ╔═╡ 87c7816a-f66e-11ea-02fe-1752fee2c7eb
md"""# Fractals
!!! info "Fractal"
	A fractal can be defined as a geometric shape or pattern that exhibits self-similarity, i.e. it looks similar at different scales.

Closely linked to the notion of a "fractal", is the notion of dimension:

!!! info "Dimension"
	The dimension of an object is obtained by measuring some kind of size (like area or volume) as a function of some kind of linear measure (like the length of a side).


For simple geometric objects, dimension is defined in terms of scaling behavior. For example:

> If the side of a square has length `l`, its area is `l^2`. The exponent, 2, indicates that a square is two-dimensional. 
> 
> If the side of a cube has length `l`, its volume is `l^3`, which indicates that a cube is three-dimensional.

When we say that some systems show "fractal behavior", the dimension can be non-integer (hence the name). For cellular automata, we can determine the "dimension" of a CA by using box counting:

!!! tip "Box counting for a CA"
	In a simplified approach, you could obtain a quantitative measure of complexity by counting the number of cells that are "on" after a certain number of time steps and link this to the size of the CA.

"""

# ╔═╡ 862b7efd-3b8b-4f7b-921e-a5b43114f991
md"""
## Fractals and Wolfram's CA
As an example, we can estimate the dimension of a 1-D cellular automaton by measuring its area (total number of “on” cells) as a function of the number of rows.

!!! tip "Wolfram's CA"
	* A 1-dimensional CA with 2 state values (i.e. 0 or 1). 
	
	* Evolution: the new value of a cell depends only on its own state and the state of its two neighbouring cells. The outcomes can be represented as a table:


	|current state (L-S-R)         |111|110|101|100|011|010|001|000|
	|-------------|---|---|---|---|---|---|---|---|
	|next state ("rule")         |0  |0  |1  |1  |0  |0  |1  |0  |
	|byte position|``b_7`` |``b_6`` |``b_5`` |``b_4`` |``b_3`` |``b_2`` |``b_1`` |``b_0`` |
	|value | ``128`` | ``64`` | ``32`` | ``16`` | ``8`` | ``4`` | 2 | ``1``|
"""

# ╔═╡ 48f6cfc2-0659-45e9-ad44-bb87ec4024a9
# support code Wolfram's CA (cf. "01_Cellular_Automata.jl")
begin
	"""
		inttorule1dim(val::Integer)
	
	Transform an integer into a rule for Wolfram's 1-dimensional CA
	
	# Example usage
	```julia
	julia> inttorule1dim(50)
	Bool[0, 0, 1, 1, 0, 0, 1, 0]
	```
	"""
	function inttorule1dim(val::Integer)
		# robustness check (we only use 8-bits)
		val > typemax(UInt8) ? throw(ArgumentError("`val` ($val) exceeds 8 bits.")) : nothing
		sign(val) < 0 ? throw(ArgumentError("`val` ($val) cannot be negative.")) : nothing
		
		# convert value into binary
	    digs = BitArray(digits(val, base=2, pad=8))
	
	    return digs[end:-1:1] # flip it around to match the table layout
	end

	"""
		applyrule1dim(rule::BitArray{1}, state::BitArray{1})
	
	Return the new state based on the own states and the left and right neighbour.
	"""
	function applyrule1dim(rule::BitArray{1}, state::BitArray{1})
		# get position of the state in the rule in rule
	    pos = 8 - (state[3] + 2*state[2] + 4*state[1])
		# return next value
	    return rule[pos]
	end

	"""
		step1dim(x₀::BitArray{1}, rule::BitArray{1}, steps::Int64)
	
	From a starting configuration `x₀`, apply a `rule` for a total of `steps` times.
	"""
	function step1dim(x₀::BitArray{1}, rule::BitArray{1}, steps::Int64)
	    xs = [x₀]
	    len = length(x₀)
	    for i in 1:steps
	        x = copy(x₀)
	        for j in 2:len-1
	            x[j] = applyrule1dim(rule, xs[end][j-1:j+1])
	        end
	        push!(xs, x)
	    end
	    xs
	end

	"""
		visualize1dim(res, dim)
	
	Helper function to illustrate the evolution of a one-dimensional Wolfram experiment.
	
	`res` contains the subsequent states and `dim` is a scaling factor for the illustration.
	"""
	function visualize1dim(res, dim)
	    width = dim * (length(res[1]) + 1)
	    height = dim * (length(res) + 1)
	    Drawing(width = width, height = height) do
	        for (i, arr) in enumerate(res)
	            for (j, val) in enumerate(arr)
	                fill = if val "grey" else "lightgrey" end
	                rect(x = j*dim, y = i*dim, width = dim, height = dim, fill = fill)
	            end
	        end
	    end
	end

	nothing
end

# ╔═╡ ea25224a-f66e-11ea-1c90-b30dba111177
begin
	x₀ = falses(65)
	x₀[33] = true
	res = step1dim(x₀, inttorule1dim(18), 31) # 20, 50, 18
	visualize1dim(res, 10)
end

# ╔═╡ 070b57aa-f66f-11ea-1a12-bd1529268d4f
md"""We estimate the dimension of these CAs with the following function, which counts the number of on cells after each time step."""

# ╔═╡ 041baf7c-f66f-11ea-270b-2179bd949a67
"""
	countcells_wolfram(rule, n=501)

Count the number of "on" cells in the one-dimensional CA at each of the `n` time steps.

The CA has a width =  `2n + 1 + 2` (borders) and start with a single "on" value in the center.
"""
function countcells_wolfram(rule, n=501)
	# initiate the CA
    x₀ = falses(2*n+3)
    x₀[n+2] = true
	# run n steps
    res = step1dim(x₀, inttorule1dim(UInt8(rule)), n)
	# initial count
    cells = [1]
	# additional counts
    for i in 2:n
        push!(cells, cells[end]+sum(line->count(cell->cell, line), res[i]))
    end
	
    return cells
end

# ╔═╡ 81657f1a-f66f-11ea-183b-0ba3f1c3a38e
md"""
* Rule 20 produces 3 cells every 2 time steps, so the total number of cells after $i$ steps is $y = 1.5i$. Taking the log of both sides, we have $\log y = \log 1.5 + \log i$, so on a log-log scale, we expect a line with slope 1. In fact, the estimated slope of the line is 1.01.
* Rule 50 produces i+1 new cells during the ith time step, so the total number of cells after $i$ steps is $y = i^2 + i$. If we ignore the second term and take the log of both sides, we have $\log y \approx 2 \log i$, so as $i$ gets large, we expect to see a line with slope 2. In fact, the estimated slope is 1.97.
* Finally, for Rule 18, the estimated slope is about 1.57, which is clearly not 1, 2, or any other integer. This suggests that the pattern generated by Rule 18 has a “fractional dimension”; that is, it is a fractal.
"""

# ╔═╡ 73fd7b5e-f66f-11ea-12cd-dd36181cf956
begin
	n = 501;
	fplot = plot(1:n, 1:n, xaxis=:log, yaxis=:log, label="d = 1", xlabel="Iteration", ylabel="Dimension")
	plot!(fplot, 1:n, (1:n).^2, xaxis=:log, yaxis=:log, label="d = 2",legendposition=:topleft)
	for rule in [20; 50; 18]
		plot!(fplot, 1:n, countcells_wolfram(rule, n), xaxis=:log, yaxis=:log, label="rule $rule")
	end
	fplot
end

# ╔═╡ feefb6e4-f66f-11ea-2998-a30311bee9f4
md"""## Fractals and percolation of water in a wall


!!! tip "Percolation of water in a wall"
	A 2-dimensional CA, where each cell is either “porous” with probability `q` or “non-porous” with probability `1-q`. This system is subject to the following principles:
	* The porous cells can be "dry" or "wet". When the simulation begins, all cells are considered “dry” except the top row, which is “wet”.
	* During each time step, if a porous cell has at least one wet neighbor, it becomes wet. Non-porous cells stay dry.
	* The simulation runs until it reaches a “fixed point” where no more cells change state.
	
	*Note*: due to the way the water propagation is modelled, it can also move upwards. You might link artefact to the capillary action.

To estimate their fractal dimension, we can run CAs with a range of sizes, count the number of wet cells in each percolating cluster, and then see how the cell counts scale as we increase the size of the array."""

# ╔═╡ 21d918ee-f670-11ea-0359-cbb1809bab9b
"""
	countcells_percolation(array::Array{Float64, 2})

Count the number of "wet" cells in the two-dimensional percolation at each of the `n` time steps.

The percolation update process stops if either the bottom row is wet, or if we reach a steady-state.
"""
function countcells_percolation(array::Array{Float64, 2})
    numberwet = count(x->x==0.5, array[3:end-1, 2:end-1])
    while true
        array = applypercolation(array)
        if count(x->x==0.5, array[end-1, 2:end-1]) > 0
            break
        end
        newnumberwet = count(x->x==0.5, array[3:end-1, 2:end-1])
        if numberwet == newnumberwet
            break
        end
        numberwet = newnumberwet
    end
	
    return numberwet
end

# ╔═╡ 4da9c3ba-f670-11ea-1627-d7c5e6b36742
md"""The dots show the number of cells in each percolating cluster. The slope of a line fitted to these dots is often near 1.85, which suggests that the percolating cluster is, in fact, fractal when `q` is near the critical value.

* When `q` is larger than the critical value, nearly every porous cell gets filled, so the number of wet cells is close to `q * size^2`, which has dimension 2.
* When `q` is substantially smaller than the critical value, the number of wet cells is proportional to the linear size of the array, so it has dimension 1."""

# ╔═╡ 3206914e-f670-11ea-3072-d162f584fbf0
let	
	sizes = 10:10:200

	pplot = plot(sizes, sizes, xaxis=:log, yaxis=:log, label="d = 1", xlabel="Iteration", ylabel="Dimension")
	plot!(pplot, sizes, (sizes).^2, xaxis=:log, yaxis=:log, label="d = 2")
	for q in [0.4; 0.8; 0.596]
		res = Float64[]
		for size in sizes
			wall = Wall(size, q)
			push!(res, countcells_percolation(wall.array))
		end
		plot!(pplot, sizes, res, xaxis=:log, yaxis=:log, seriestype=:scatter, label="q = $q")
	end
	
	pplot
end

# ╔═╡ c095e146-a761-4b63-97bb-e09a2329da8f
md"""
## Fractals and sand piles
For the sand piles, we have a look at the geometry, by making a bigger sand pile, with `n=131` and initial level 22.
"""

# ╔═╡ d8782c4d-1b4f-432a-b1aa-3c186477a9d7
pile131 = Pile(133, 22);

# ╔═╡ 2ecd7822-59d1-4f12-a703-741324108bd1
let
	pile131.array, steps, total = steptoppling(pile131.array)
	@info "it takes $(steps) and a total of $(total) topplings for pile131 to topple"
end

# ╔═╡ 5ea01e86-67ce-46b1-a22f-0e0e88562bfb
md"""We can study the geometrical patterns in detail by plotting the cells with levels 0, 1, 2, and 3 separately:"""

# ╔═╡ cd89bc55-a86e-42c5-8e69-ee8f74c99b11
"""
	visualizepileonekind(pile, dim, val)

Visualise a sand `pile`, showing only those cells that have a value `val`.

`dim` is a scaling factor for the illustration. 
"""
function visualizepileonekind(pile, dim, val)
    (ydim, xdim) = size(pile)
    width = dim * (xdim - 1)
    height = dim * (ydim - 1)
    Drawing(width=width, height=height) do
		for (j, y) in enumerate(2:ydim-1)
			for (i, x) in enumerate(2:xdim-1)
				if pile[y,x] == val
					rect(x=i*dim, y=j*dim, width=dim, height=dim, fill="gray")
				end
			end
		end
	end
end

# ╔═╡ 36bd6862-32d7-4ef8-99ab-05d547f5db3d
visualizepileonekind(pile131.array, 4, 0)

# ╔═╡ a40ead54-317e-441c-9728-88da17062789
md"""Visually, these patterns resemble fractals, but looks can be deceiving. To be more confident, we can estimate the fractal dimension for each pattern using box counting:

> Count the number of cells in a small box at the center of the pile, then see how the number of cells increases as the box gets bigger.
"""

# ╔═╡ 45d30fb8-f75f-4318-a2d0-d51bd6ef069c
"""
	countcells_pile(pile, val)

For a given sand `pile`, count those cells that have a value equal to `val` for increasing box sizes.
"""
function countcells_pile(pile, val)
    (ydim, xdim) = size(pile)
    ymid = Int((ydim+1)/2)
    xmid = Int((xdim+1)/2)
    res = Int64[]
    for i in 0:Int((ydim-1)/2)-1
        push!(res, 1.0*count(x->x==val, pile[ymid-i:ymid+i,xmid-i:xmid+i]))
    end
	
    return res
end

# ╔═╡ 3dbd33c1-ec71-4e93-ab7b-a4e8299ca830
md"""On a log-log scale, the cell counts form nearly straight lines, which indicates that we are measuring fractal dimension over a valid range of box sizes.
"""

# ╔═╡ d6b56ea1-b84b-471a-b00f-8d49088fc583
let 
	(ydim, xdim) = size(pile131.array)
	m = Int((ydim-1)/2)
	fp = plot(1:2:2*m-1, 1:2:2*m-1, xaxis=:log, yaxis=:log, label="d = 1",legend=:topleft, xlabel="Box size", ylabel="Dimension")
	plot!(fp,1:2:2*m-1, (1:2:2*m-1).^2, xaxis=:log, yaxis=:log, label="d = 2")
	for level in [0;1;2;3]
		res = filter(x->x>0, countcells_pile(pile131.array, level))
		n = length(res)
		plot!(fp,1+2*(m-n):2:2*m-1, res, xaxis=:log, yaxis=:log, label="level $level")
	end
	fp
end

# ╔═╡ 363a48e8-aeab-4aeb-9d16-43f06990799a
md"""To estimate the slopes of these lines, we have to fit a line to the data by linear regression"""

# ╔═╡ 303be840-0096-4fea-9a2d-3c4e87fd9ce3
begin 

	"""
		linres(x, y)
	
	Estimate the linear regression coefficient such that y ≈ α + β * x
	"""
	function linres(x, y)
		# Data length
	    n = length(x)
		# x and y means
	    mx = sum(x) / n
	    my = sum(y) / n
		# slope estimate (cf. statistics course)
	    β = sum((x.-mx).*(y.-my))/sum((x.-mx).^2)
		# offset
	    α = my - β * mx
		
	    return α, β
	end
	
	level_frac_dims = [(level, (begin 	(ydim, xdim) = size(pile131.array) 
										m = Int((ydim-1)/2)
										res = filter(x->x>0, countcells_pile(pile131.array, level))
										n = length(res)
										linres(log.(1.0*collect(1+2*(m-n):2:2*m-1)), 
										log.(res)) end)[2])
						for level in [0;1;2;3]]
	msg = join(["$(level): $(frac_dim)" for (level, frac_dim) in level_frac_dims], "\n")
	@info """
	The estimated fractal dimension (using box counting) are:
	
	$(msg)
	"""
end

# ╔═╡ Cell order:
# ╠═1d6260d4-f663-11ea-03da-efe9ed63f9bd
# ╟─a62f8ca0-4680-4a73-8333-8c56b385839f
# ╠═f231418d-4bbc-46a1-bb65-5b1d14141b31
# ╟─e6ff0e98-f662-11ea-03a7-e3d09e6272a6
# ╟─737c3da8-15ce-4f05-8c6b-c1eae0998630
# ╟─2abf49e0-f663-11ea-25f3-2f9229de732e
# ╠═40373f12-f663-11ea-256c-abd1458a8e85
# ╟─52f4e280-f663-11ea-38a4-c52a7b06b564
# ╠═61437b46-f663-11ea-12c6-2ff992812dca
# ╠═358ac3e2-f666-11ea-2058-11eedeabff5f
# ╠═863a3fa4-f664-11ea-2597-8f18f2a862ac
# ╠═966fc752-f666-11ea-1794-195433f4cce5
# ╟─b0148fb4-f664-11ea-2d64-976658b08661
# ╟─b25969c4-f665-11ea-222b-df9786a710d2
# ╟─4c3d12f5-0606-4f7f-96f4-d687e7b59fa4
# ╟─95dc78e8-f667-11ea-1c07-8f5cc11b011b
# ╟─98df4f0f-2b67-4e4d-b967-f8f151af4976
# ╠═03f96645-e314-46bb-bc12-28b1fb0b600e
# ╠═0768d49b-1e26-4cec-b370-4ffd8d44dba2
# ╟─c03905f2-f667-11ea-3484-b111f7c14f60
# ╠═cf7c1a2c-f667-11ea-358f-df431ec27476
# ╠═23f98030-f668-11ea-389b-ff911adaadfd
# ╠═3c706f38-f669-11ea-2266-f743535073b5
# ╠═1b551fc2-f669-11ea-0d2f-ad0e089592d8
# ╟─e1988846-f668-11ea-1b26-8f7dca1bb4e7
# ╟─dda066c0-f668-11ea-3096-bdea16f40db7
# ╟─1734b35e-f66a-11ea-10b4-317d12008809
# ╟─ba90d318-34b9-47ec-981e-5e733d855da2
# ╠═610cdf02-ddf4-4c4e-84db-9bfe998cb553
# ╠═d22ef684-9b40-43b7-bdcb-a67d71cd5f8a
# ╟─40f84b2e-f66a-11ea-1dc7-3ded9e11af06
# ╟─98caca4c-20db-4f19-ae8a-c0e6ff207148
# ╟─7140fbf4-a30d-479a-a539-7f7c0a350bf4
# ╠═77dcd828-f66a-11ea-0942-c5d613d828b7
# ╠═44c8b17a-f66b-11ea-39af-f554593e33eb
# ╠═d9ccf8f8-f66b-11ea-2c81-0d771c2e900e
# ╠═e492630e-f66b-11ea-3aed-f37a400243be
# ╟─e048231c-f66b-11ea-191d-8517a6c65bc5
# ╟─11847488-f66c-11ea-1aca-4b1613dbfb8e
# ╟─e51771ec-f66c-11ea-1606-fd159b8d216f
# ╠═2b9c8a86-f66c-11ea-0447-1fb7ba83d3a1
# ╟─9fe496ab-7277-4c99-8533-6c329b82b563
# ╠═c71f0f24-f66c-11ea-0ba7-d765f3998ed9
# ╠═1254b21a-f66e-11ea-2b36-7985687edd02
# ╠═c828c986-5f12-4dab-8aac-d18d34ae6086
# ╠═dda2cd12-f66c-11ea-3f31-837c9a749b5c
# ╟─a92e9fe7-1cf7-4426-8221-c3e4946f4860
# ╠═2b6328b1-0384-4937-994b-ae8270824f42
# ╟─952f559a-46bc-40ec-9d1f-1841e2240615
# ╟─258e9da9-dec2-47fc-b943-8bb3ff5aee05
# ╟─2a945f8f-26c8-4c8e-8632-e7cad95fc621
# ╟─340521e8-8c97-4c7d-85b9-93a37ee85563
# ╠═d9fc2ec3-b3c3-41b3-8510-b599a1e8e059
# ╠═501878b4-f66e-11ea-270f-d7542715acbb
# ╟─44719f1b-bcbd-4cc3-ab05-aa004f926f6c
# ╟─afd57d30-8a2c-45be-a2fe-091525f6b254
# ╟─0a76134a-e735-4184-ac41-674174132f8e
# ╟─3af0633c-3c5d-45ba-b590-0a433cd008ab
# ╠═dd7ef855-c9da-4984-a4d5-a7f81972027b
# ╠═d304fd4e-3321-48b3-9901-da061dca2f98
# ╠═daeb8116-72ac-4850-adbf-7a1705196558
# ╠═0555f705-85be-4e49-82c6-fee854070c0f
# ╠═3e0d8751-4bd3-4a1f-943b-f2c92bf2fcab
# ╠═63e73256-d9e4-4edc-9f52-192fcda9a9b4
# ╟─58b2953c-5f15-41fa-a6ec-2c990562b411
# ╟─39042d4a-d777-4e05-a857-dc8e55003d89
# ╠═26a1ddd2-67a3-498e-b653-43af7c9aeace
# ╟─bcaf050a-8da2-4dc1-99eb-90bc05f61386
# ╠═9e666fb4-f6da-426b-b35f-587014f79814
# ╠═874cacb5-332e-4672-beca-b58f260e0f73
# ╠═ade0a573-059f-4f12-8627-45ea734c65a2
# ╟─b3505179-3861-46fc-b0fb-7fac96c95dd2
# ╟─da9e17e4-9490-4927-87bc-99dce93b15aa
# ╟─7006688d-5e49-4d90-9aac-9608faf707a5
# ╠═c7872f6b-9c9f-4b2c-9dda-531c6edf5501
# ╠═69f25cf7-7319-4d88-82f4-b43d86afa8f6
# ╠═9299334a-935e-461b-afea-5b6c3d094a46
# ╟─b989e963-8fca-49d6-9f36-1ac6f24923f1
# ╟─87c7816a-f66e-11ea-02fe-1752fee2c7eb
# ╟─862b7efd-3b8b-4f7b-921e-a5b43114f991
# ╟─48f6cfc2-0659-45e9-ad44-bb87ec4024a9
# ╠═ea25224a-f66e-11ea-1c90-b30dba111177
# ╟─070b57aa-f66f-11ea-1a12-bd1529268d4f
# ╠═041baf7c-f66f-11ea-270b-2179bd949a67
# ╟─81657f1a-f66f-11ea-183b-0ba3f1c3a38e
# ╟─73fd7b5e-f66f-11ea-12cd-dd36181cf956
# ╟─feefb6e4-f66f-11ea-2998-a30311bee9f4
# ╠═21d918ee-f670-11ea-0359-cbb1809bab9b
# ╟─4da9c3ba-f670-11ea-1627-d7c5e6b36742
# ╟─3206914e-f670-11ea-3072-d162f584fbf0
# ╟─c095e146-a761-4b63-97bb-e09a2329da8f
# ╠═d8782c4d-1b4f-432a-b1aa-3c186477a9d7
# ╠═2ecd7822-59d1-4f12-a703-741324108bd1
# ╟─5ea01e86-67ce-46b1-a22f-0e0e88562bfb
# ╠═cd89bc55-a86e-42c5-8e69-ee8f74c99b11
# ╠═36bd6862-32d7-4ef8-99ab-05d547f5db3d
# ╟─a40ead54-317e-441c-9728-88da17062789
# ╠═45d30fb8-f75f-4318-a2d0-d51bd6ef069c
# ╟─3dbd33c1-ec71-4e93-ab7b-a4e8299ca830
# ╟─d6b56ea1-b84b-471a-b00f-8d49088fc583
# ╟─363a48e8-aeab-4aeb-9d16-43f06990799a
# ╟─303be840-0096-4fea-9a2d-3c4e87fd9ce3
