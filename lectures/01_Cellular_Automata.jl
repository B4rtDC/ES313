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

# ╔═╡ 310ce685-2661-4f32-bf14-91a4f4e569ce
# Explicit use of own environment instead of a local one for each notebook
begin
	# Pkg needs to be used to force Pluto to use the current project instead of making an environment for each notebook
	using Pkg
	# this is redundant if you run it through start.jl, but to make sure...
	while !isfile("Project.toml") && !isdir("Project.toml")
        cd("..")
    end
    Pkg.activate(pwd())
	using PlutoUI
	PlutoUI.TableOfContents(depth=4)
end

# ╔═╡ a27d4d98-c20c-4251-b7ba-73e60fcb472c
# Dependencies
begin
using NativeSVG # SVG plotting library
using Random    # for random related activities
using Printf    # for nice string plotting
end

# ╔═╡ e9873822-4bf1-425e-bc32-98922b27995f
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

# ╔═╡ 56f41ca0-eb93-11ea-1ea6-11b0e8bb9a7d
md"""# Cellular Automata
**Note**: based on a port of Chapter 5 and 6 of [Think Complexity](http://greenteapress.com/complexity2/html/index.html) by Allen Downey."""

# ╔═╡ dab709d0-eb93-11ea-050e-3bfa6a5e1836
md"""
!!! info "Cellular Automaton (CA)"
	A cellular automaton consists of a grid of cells, each of which can be in one of a finite number of states. The state of each cell evolves over discrete time steps according to a set of rules that depend on the state of the cell and the states of its neighboring cells."""

# ╔═╡ f4b601b0-eb93-11ea-0969-7967a1e85c8b
md"""## A Trivial Example

!!! tip "0-dimensional CA"
	a CA, composed of only a single cell can be in one of two states. At each discrete timestep, the cell changes its state.

We can implement this as show below:
"""

# ╔═╡ 14a02c30-eb94-11ea-2114-5102409c8ae5
"""
	rule0dim(x::Bool)

CA behavior rule for a 0-dimensional CA. This just switches the state of the cell.
"""
function rule0dim(x::Bool)
    !x
end

# ╔═╡ 1a915240-eb94-11ea-087f-231ade62690d
md"time evolution:"

# ╔═╡ 2393fe0e-eb94-11ea-2858-b50503395d4a
"""
	step0dim(x₀::Bool, n::Int64)

Returns a vector containing `n` timesteps for a 0-dimensional CA starting in state `x₀`
"""
function step0dim(x₀::Bool, n::Int64)
    xs = [x₀]
    for i in 1:n
        push!(xs, rule0dim(xs[end]))
    end
    xs
end

# ╔═╡ 2dde4510-eb94-11ea-212a-5da1e7733bf6
md"We can use NativeSVG to generate a visualisation of the 0-dimensional CA:"

# ╔═╡ 35cbd760-eb94-11ea-201a-6b58802154a1
let
	res = step0dim(false, 10)
	Drawing(width = 50, height = 300) do
		for (i, val) in enumerate(res)
			fill = if val "grey" else "lightgrey" end
			rect(x = 20, y = 5+i*20, width = 20, height = 20, fill = fill)
		end
	end
end

# ╔═╡ 758a0c50-eb94-11ea-11a2-e3e007b089a9
md"""## Wolfram's Experiment
### Description
!!! tip "Wolfram's CA"
	* A 1-dimensional CA with 2 state values (i.e. 0 or 1). 
	
	* Evolution: the new value of a cell depends only on its own state and the state of its two neighbouring cells. The outcomes can be represented as a table:


	|current state (L-S-R)         |111|110|101|100|011|010|001|000|
	|-------------|---|---|---|---|---|---|---|---|
	|next state ("rule")         |0  |0  |1  |1  |0  |0  |1  |0  |
	|byte position|``b_7`` |``b_6`` |``b_5`` |``b_4`` |``b_3`` |``b_2`` |``b_1`` |``b_0`` |
	|value | ``128`` | ``64`` | ``32`` | ``16`` | ``8`` | ``4`` | ``2`` | ``1``|


Based on the byte positions, we can convert a rule into an integer. The present example can be transformed as follows:
```math
\sum_{i=0}^{7} b_{i} 2^{i}.
```
When aplied to the example in the table, we find "rule 50": ``32 + 16 + 2 = 50``
"""

# ╔═╡ 2d708d14-38ff-4554-b3ce-a2e5b8ef7eff
md"### Building the components"

# ╔═╡ d8481030-eb94-11ea-1af4-db838adc37ed
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

# ╔═╡ 49527027-1c4a-460a-b455-de2767a3c0ef
md"""Example usage:"""

# ╔═╡ 5cb02abd-dacc-4cec-96f0-387455dfb495
begin
	# rule 50
	rule_50 = inttorule1dim(UInt8(50))
	# examples (max, rand, min, rule_50)
	for val in sort([255; rand(0:255); 0; 50])
		@printf("Value: %3i, Rule: %s \n", val, inttorule1dim(val))
	end
end

# ╔═╡ e393e8b2-eb94-11ea-3d70-d31f7ee89420
md"""
We now need to define a function that allows us to apply a rule to a cell knowing its own previous state and the previous state of his left and right neighbour:
"""

# ╔═╡ eed0a600-eb94-11ea-1863-0f33980508ba
"""
	applyrule1dim(rule::BitArray{1}, state::BitArray{1})

Return the new state based on the own states and the left and right neigbour.
"""
function applyrule1dim(rule::BitArray{1}, state::BitArray{1})
	# get position of the state in the rule in rule
    pos = 8 - (state[3] + 2*state[2] + 4*state[1])
	# return next value
    return rule[pos]
end

# ╔═╡ af9f9fad-66dc-44c9-baf0-d553a1487f2e
md"""Example usage:"""

# ╔═╡ 0749769f-ff28-45d7-8ebb-3bd2de8e36cd
# quick test
begin
	for state in [BitArray([1;1;1]), 
				  BitArray([1;1;0]), 
				  BitArray([1;0;1]), 
				  BitArray([1;0;0]),
				  BitArray([0;1;1]),
				  BitArray([0;1;0]),
				  BitArray([0;0;1]),
				  BitArray([0;0;0])]
		@printf("State: %s, Next: %i \n", state, applyrule1dim(rule_50, state))
	end
end

# ╔═╡ 0002a810-eb95-11ea-2ba8-bb2849bdec17
md"Using this function, we can now create another one that runs a number of steps on the entire state:"

# ╔═╡ 04139c70-eb95-11ea-1759-298193ce97b0
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
	
    return xs
end

# ╔═╡ 108edf3d-c230-4180-8892-6f8d487ca650
md"""
!!! warning "Watch out!"
	In our update function, we exclude the left- and rightmost cells, because we cannot determine the values of their adjacent cells!
"""

# ╔═╡ 60e8deb0-eb95-11ea-2bde-d9c259432318
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

# ╔═╡ 10100040-eb95-11ea-3a6d-271e63301b17
md"""
### Complete example

Initialisation:
"""

# ╔═╡ 1a508340-eb95-11ea-08f9-6f085748d7ff
res = let
	# start configation has 21 values, all false.
	x₀ = falses(21)
	# set the center value true
	x₀[11] = true
	# run 9 iterations using rule_50
	step1dim(x₀, rule_50, 9)
end;

# ╔═╡ 5d2a01f0-eb95-11ea-3dcd-b794e1b0d566
md"visualisation:"

# ╔═╡ 6a08d680-eb95-11ea-17b5-d199cc14b12a
visualize1dim(res, 30)

# ╔═╡ 9db5c010-eb95-11ea-3257-652ddbd3939d
md"""### Classifying CAs

#### Class 1

Evolution from any starting condition to the same uniform pattern, eg. rule_0"""

# ╔═╡ adfe9aa0-eb95-11ea-1ce9-e5370aeec375
let
	rule_0 = inttorule1dim(UInt8(0))
	# random initial state
	x₀ = bitrand(21)
	# set border to false
	x₀[1] = false; x₀[end] = false;
	# apply rules
	res = step1dim(x₀, rule_0, 1)
	# show result
	visualize1dim(res, 30)
end

# ╔═╡ 1c6b5780-eb96-11ea-2bbd-755d35c27938
md"""#### Class 2

Generation of a simple pattern with nested structure, i.e. a pattern that contains many smaller versions of itself, eg. rule_50.

Example that looks like a Sierpinsi triangle (fractal): rule_18."""

# ╔═╡ 2bcfc580-eb96-11ea-1837-c703fac6cd69
let
	rule_18 = inttorule1dim(UInt8(18))
	# central true value, all the others false
	x₀ = falses(129)
	x₀[65] = true
	# apply rule
	res = step1dim(x₀, rule_18, 63);
	# show result
	visualize1dim(res, 6)
end

# ╔═╡ 4d3dd0e0-eb96-11ea-0f6a-8f6fb24e8f9d
md"""#### Class 3

CAs that generate randomness, eg. rule_30."""

# ╔═╡ 4d2f51f0-eb96-11ea-1c16-b7b7b81a3ca3
let
	rule_30 = inttorule1dim(UInt8(30))
	# central true value, all the others false
	x₀ = falses(201)
	x₀[101] = true
	# apply rule
	res = step1dim(x₀, rule_30, 99);
	# show result
	visualize1dim(res, 4)
end

# ╔═╡ 8eb8d100-eb96-11ea-12f5-751c018540fc
md"""Center column as a sequence of bits, is hard to distinguish from a truly random sequence: pseudo-random number generators (PRNGs).

- regularities can be detected statistically
- a PRNG with finite amount of state will eventually repeat itself (period)
- underlying process is fundamentally deterministic (unlike some physical processes: thermodynamics or quantum mechanics)

This complex behavior is surprising (chaos is often associated with non-linear behavior of continuous time and space processes)."""

# ╔═╡ a075adee-eb96-11ea-3ddc-572f2795d6b5
md"""#### Class 4

CAs that are Turing complete or universal, which means that they can compute any computable function, eg. rule_110."""

# ╔═╡ aed6b5b0-eb96-11ea-2a3d-7f82f61ea518
let
	rule_110 = inttorule1dim(UInt8(110))
	# random initialisation
	x₀ = bitrand(600)
	# apply rule
	res = step1dim(x₀, rule_110, 599);
	# show result
	visualize1dim(res, 1)
end

# ╔═╡ c56df180-eb96-11ea-1a57-2d0571da6ac3
md"""- After about 100 steps, simple repeating patterns emerge, but there are a number of persistent structures that appear as disturbances. Some are vertical, other are diagonal and are called spaceships.

- Collisions between spaceships yields different results depending on their type and their phase. Some collisions annihilate both ships; other leaves one ship unchanged; still other yield one or more ships of different types.

- The collisions are the basis of computation in a rule110 CA. You can think of spaceships as signals that propagate through space, and collisions as gates that compute logical operations like AND and OR."""

# ╔═╡ 11fa5930-eb97-11ea-274e-3f2c45958666
md"""
We can define our own struct to represent the Turing State-Machine:"""

# ╔═╡ 9b61fa20-eb97-11ea-0f1c-c922c04a796f
md"Implementation of a step:"

# ╔═╡ c21ab861-5522-436c-a253-18b664592528
md"""
## Conway's Game of Life (GoL)
!!! tip "Conway's Game of Life"
	A 2-dimensional CA that adheres to the following principles:
	* The cells in GoL are arranged in a 2-D grid, that is, an array of rows and columns. Usually the grid is considered to be infinite, but in practice it is often “wrapped”; that is, the right edge is connected to the left, and the top edge to the bottom.
	* Each cell in the grid has two states — live and dead — and 8 neighbors — north, south, east, west, and the four diagonals. This set of neighbors is sometimes called a “Moore neighborhood”.
	* the next state of each cell depends on its current state and its number of live neighbors. If a cell is alive, it stays alive if it has 2 or 3 neighbors, and dies otherwise. If a cell is dead, it stays dead unless it has exactly 3 neighbors.

	**Note:** this behavior is loosely analogous to real cell growth: cells that are isolated or overcrowded die; at moderate densities they flourish.

### Implementation
"""

# ╔═╡ 3d3d0ff7-1026-4ce2-85d6-5606c6b86dba
"""
	applyrulegameoflife(bits::BitArray{2})

Given a bitmatrix, determine the new state using Conway's game of life rules.

*Notes*: 
- the borders are not updated.
- using the `@view` macro to not slice the matrix (better performance)

"""
function applyrulegameoflife(bits::BitArray{2})
    (nr_y, nr_x) = size(bits)
    out = falses(nr_y, nr_x)
    for y in 2:nr_y-1
        for x in 2:nr_x-1
            if bits[y, x]
				# If a cell is alive, it stays alive if it has 2 or 3 neighbors
                if 2 ≤ count(v->v, @view bits[y-1:y+1,x-1:x+1]) - 1 ≤ 3
                    out[y, x] = true
                end
            else
				# If a cell is dead, it stays dead unless it has exactly 3 neighbors
                if count(v->v, @view bits[y-1:y+1,x-1:x+1]) == 3
                    out[y, x] = true
                end
            end
        end
    end
	
    return out
end

# ╔═╡ 7bc324ef-c92e-44e6-9d74-6f8c47be5d4e
"""
	visualize2dim(bits::BitArray{2}, dim)

Helper function to illustrate the evolution of a 2-dimensional Conway Game of Life.

`bits` contains the state and `dim` is a scaling factor for the illustration.

*Note*: borders are not plotted
"""
function visualize2dim(bits::BitArray{2}, dim)
    (nr_y, nr_x) = size(bits)
    width = dim * (nr_x - 1)
    height = dim * (nr_y - 1)
    Drawing(width = width, height = height) do
        for (j, y) in enumerate(2:nr_y-1)
            for (i, x) in enumerate(2:nr_x-1)
                fill = if bits[y, x] "lightgreen" else "grey" end
                rect(x = i*dim, y = j*dim, width = dim, height = dim, fill = fill)
            end
        end
    end
end

# ╔═╡ 3ffda0e6-2bc1-46a0-bbac-2b350f31b1c3
"""
	Gol

An struct holding the information of a GoL instance. The inner constructor initialises the world with false on every location.
"""
mutable struct Gol
	bits :: BitArray{2}
	"""
		Gol(xdim::Int, ydim::Int)

	Initialise a new GoL of size `xdim` x `ydim`.
	"""
	function Gol(xdim::Int, ydim::Int)
		new(falses(xdim, ydim))
	end
end

# ╔═╡ 9c71d310-d18a-4abf-937a-b7c22ca35a38
"""
	applyrule!(gol::Gol)

Update the `gol` state by applying the GoL rules.
"""
function applyrule!(gol::Gol)
	gol.bits = applyrulegameoflife(gol.bits)
end

# ╔═╡ e9194e90-4afd-4645-bf07-7ee276b3e12c
"""
	goltest()

Testing function to create a random GoL instance of size `xdim` x `ydim`. 

*Note*: borders will be padded with zeros
"""
function goltest(xdim::Int, ydim::Int)
	# instantiate
	gol = Gol(xdim+2, ydim+2)
	# fill with random
	gol.bits[2:xdim+1,2:ydim+1] = reshape(bitrand(xdim*ydim), (xdim,ydim))
	
	return gol
end

# ╔═╡ c490e7fb-a60f-4e11-a336-118a10406d54
md"Instantiate a random GoL situation:"

# ╔═╡ 6fd08ac6-932e-45d8-9fd8-a4c87e90b139
gol = goltest(12, 12);

# ╔═╡ 1c0a1ea7-0fb8-40b5-96cf-e1321ec2c05d
gol.bits

# ╔═╡ 147af6e2-6927-4ee6-a402-7efe5550b418
visualize2dim(gol.bits, 20)

# ╔═╡ 6bfc41ee-a799-4c95-863a-46ac7110ff10
visualize2dim(applyrule!(gol), 20)

# ╔═╡ aea98b31-7840-4822-b731-12c5a40b14b5
md"""### Life Patterns

A number of stable patterns are likely to appear.

#### Beehive

A stable pattern."""

# ╔═╡ 37f558b7-8df1-4ab7-9394-78d2eb8032c1
"""
	Beehive()

Generate a beehive GoL instance, which is a stable pattern.
"""
function Beehive()
	beehive = Gol(5, 6)
	beehive.bits[2,3:4] = [true, true]
	beehive.bits[3,2] = true
	beehive.bits[3,5] = true
	beehive.bits[4,3:4] = [true, true]
	beehive
end

# ╔═╡ 3b061fd5-d860-4af9-9d3b-625982227b98
beehive = Beehive();

# ╔═╡ 8238a3ab-d39f-449f-b465-975a8db707d9
visualize2dim(applyrule!(beehive), 30)

# ╔═╡ 8a48dd07-b924-481b-9fc7-c49a7c8e38ff
md"""#### Toad

An oscillating pattern. The toad has a period of 2 timesteps."""

# ╔═╡ 2b3157b8-6342-4cb1-a09d-212a76d53071
"""
	Toad()

Generate a toad GoL instance, which is an oscillating pattern.
"""
function Toad()
	toad = Gol(6, 6)
	toad.bits[3,3:5] = [true, true, true]
	toad.bits[4,2:4] = [true, true, true]
	toad
end

# ╔═╡ 9bad3752-5733-46cb-a598-72fb4042aafa
toad = Toad();

# ╔═╡ ddfa10fe-0856-4d49-9cca-d1e3c6b2c1a9
visualize2dim(applyrule!(toad), 30)

# ╔═╡ 033db172-d8ee-4a21-9f2a-85214777b9a4
md"""#### Glider

Oscillation pattern that shifts in space. After a period of 4 steps, the glider is back in the starting configuration, shifted one unit down and to the right."""

# ╔═╡ 07e99ce2-da75-4c71-a873-b36579f787c9
"""
	Glider()

Generate a glider GoL instance, which is a pattern that shifts in space.
"""
function Glider()
	glider = Gol(8, 8)
	glider.bits[2,3] = true
	glider.bits[3,4] = true
	glider.bits[4,2:4] = [true, true, true]
	glider
end

# ╔═╡ 21bc6cfe-dff1-4ae8-a814-3fbb137f3ab6
glider = Glider();

# ╔═╡ b8c2f6db-a087-4785-9ea8-9592857c943d
visualize2dim(glider.bits, 30)

# ╔═╡ aac83f03-252e-4006-9b4c-9b869c9e9b6b
@bind toggleglider html"<input type=button value='Next'>"

# ╔═╡ d128ac2e-69d2-4122-aa1f-de65355ae6a2
if toggleglider === "Next"
	visualize2dim(applyrule!(glider), 30)
else
	visualize2dim(glider.bits, 30)
end

# ╔═╡ 4ab7fbe2-c8a8-44e5-91d3-c1eb7d15b7ee
md"""#### Methusalems

From most initial conditions, GoL quickly reaches a stable state where the number of live cells is nearly constant (possibly with some oscillation).

But there are some simple starting conditions that yield a surprising number of live cells, and take a long time to settle down. Because these patterns are so long-lived, they are called “Methusalems”.

One of the simplest Methusalems is the r-pentomino, which has only five cells, roughly in the shape of the letter 'r'."""

# ╔═╡ 6a2a9c8a-5a39-4ccd-aa4b-a9a333be92b8
"""
	R_Pentomino()

Generate a GoL instance, with an r-pentonimo in it.
"""
function R_Pentomino()
	r_pentomino = Gol(66, 66)
	r_pentomino.bits[28,28:29] = [true, true]
	r_pentomino.bits[29,27:28] = [true, true]
	r_pentomino.bits[30,28] = true
	r_pentomino
end

# ╔═╡ 0e419a01-0e16-4425-b5aa-cedf587fc49c
r_pentomino = R_Pentomino();

# ╔═╡ 32793422-29c0-4700-a852-ac20190eb99e
@bind togglerpentomino html"<input type=button value='Next'>"

# ╔═╡ 83a0d73e-354f-4699-b700-6dddec18619d
if togglerpentomino === "Next"
	visualize2dim(applyrule!(r_pentomino), 8)
else
	visualize2dim(r_pentomino.bits, 8)
end

# ╔═╡ fc9d0a1a-d8c8-41dd-a092-e5470dc7fdd7
md"""
Situation after 1,000 iterations:
"""

# ╔═╡ f3510f3d-259d-4678-a2ed-81c1f5a2fd72
let r_pentomino = deepcopy(r_pentomino)
	for _ in 1:1000
		r_pentomino.bits = applyrule!(r_pentomino)
	end
	visualize2dim(r_pentomino.bits, 8)
end

# ╔═╡ 68d9c2ed-a762-4e3c-b00b-e82c8ac637b2
md"""This configuration is final in the sense that all remaining patterns are either stable, oscillators or gliders that will never collide with another pattern.

There are initial patterns that never stabilize, eg. a gun or a puffer train

The Game of Life was proved Turing complete in 1982. Since then, several people have constructed GoL patterns that implement a Turing machine or another machine known to be Turing complete."""

# ╔═╡ f2a45860-eb96-11ea-2e5f-b1850621020b
md"""## Turing State-Machines
### Concept
Based on [wikipedia: Turing Machine](https://en.wikipedia.org/wiki/Turing_machine).

!!! info "Turing machine"
	A Turing machine is a mathematical model of computation that defines an abstract machine, which manipulates symbols on a tape according to a table of rules. Despite the model's simplicity, given any computer algorithm, a Turing machine capable of simulating that algorithm's logic can be constructed.

A turing machine is composed of the following:
- A tape divided into cells, one next to the other. Each cell contains a symbol from some finite alphabet. The alphabet contains a special blank symbol (here written as '0') and one or more other symbols. The tape is assumed to be arbitrarily extendable to the left and to the right, i.e., the Turing machine is always supplied with as much tape as it needs for its computation. Cells that have not been written before are assumed to be filled with the blank symbol. In some models the tape has a left end marked with a special symbol; the tape extends or is indefinitely extensible to the right.
- A head that can read and write symbols on the tape and move the tape left and right one (and only one) cell at a time. In some models the head moves and the tape is stationary.
- A state register that stores the state of the Turing machine, one of finitely many. Among these is the special start state with which the state register is initialized. These states, writes Turing, replace the "state of mind" a person performing computations would ordinarily be in.
- A finite table of instructions that, given the state the machine is currently in and the symbol it is reading on the tape (symbol currently under the head), tells the machine to do the following in sequence:
    - Erase or write a symbol.
    - Move the head ( 'L' for one step left or 'R' for one step right or 'N' for staying in the same place).
    - Assume the same or a new state as prescribed.



### Busy Beaver
Below you can find a table of rules for one such machine, "the busy beaver". The Busy Beaver is a special kind of Turing machine — specifically, one that tries to write as many 1s as possible before halting, under very strict constraints (e.g., a fixed number of states and symbols).

| Tape Symbol | State A   | State B   | State C   |
|:-----------:|-----------|-----------|-----------|
| 0           | 1 - R - B | 1 - L - A | 1 - L - B |
| 1           | 1 - L - C | 1 - R - B | 1 - R - H |

!!! tip "Nice to know" 
	Turing machines can be simulated by cellular automata, and vice versa. In fact, some cellular automata are Turing complete (e.g., Rule 110, Game of Life), meaning they can simulate Turing machines.


We can implement this principle in a function which returns a new state based on the present state and the symbol that was read.
"""

# ╔═╡ fa9e94e0-eb96-11ea-061c-a36a28f5e7b1
"""
	applyrulebusybeaver(state, read)

Given a `state` and the tape symbol `read`, return the new state.
"""
function applyrulebusybeaver(state, read)
    if state == 'A' && read == 0
        return 1, 'R', 'B'
    elseif state == 'A' && read == 1
        return 1, 'L', 'C'
    elseif state == 'B' && read == 0
        return 1, 'L', 'A'
    elseif state == 'B' && read == 1
        return 1, 'R', 'B'
    elseif state == 'C' && read == 0
        return 1, 'L', 'B'
    elseif state == 'C' && read == 1
        return 1, 'R', 'H'
    end
end

# ╔═╡ 1a07f6a0-eb97-11ea-0f51-a3d742fcf260
"""
	Turing

A struct to represent a Turing state-machine
"""
mutable struct Turing
    tape::Array{Int64}
    position::Int64
    state::Char
end

# ╔═╡ 7bfdef90-eb97-11ea-03ce-4fb081079815
# Extend the Base.show function to represent a Turing state-machine 
function Base.show(io::IO, turing::Turing)
    print(io, turing.position, " - ", turing.state, ": ", turing.tape)
end

# ╔═╡ a68bf2c0-eb97-11ea-30ea-87d20ea07175
"""
	stepturing!(turing::Turing, applyrule::Function)

Update a `Turing` struct, using the function `applyrule`. Note that this modifies the struct.
"""
function stepturing!(turing::Turing, applyrule::Function)
    if turing.state == 'H'
        error("Machine has stopped!")
    end
    read = turing.tape[turing.position]
    (write, dir, turing.state) = applyrule(turing.state, read)
    turing.tape[turing.position] = write
    if dir == 'L'
        if turing.position == length(turing.tape)
            push!(turing.tape, false)
        end
        turing.position -= 1
    else
        if turing.position == 1
            pushfirst!(turing.tape, false)
        else
            turing.position += 1
        end
    end
	
    return nothing
end

# ╔═╡ a3263280-eb97-11ea-2e91-532bfa433f6c
md"### Small illustration"

# ╔═╡ be984390-ebb1-11ea-0729-39795172949b
begin
	# Define a Turing state-maching
	turing = Turing(zeros(Int64, 11), 6, 'A')
	@info "Initialisation: $(turing)"
	# Apply a single step
	stepturing!(turing, applyrulebusybeaver)
	# Show the new state
	@info "After one step: $(turing)"
end

# ╔═╡ d24b2602-9be2-44d6-8ec1-307e5feab26e
md"### Larger illustration"

# ╔═╡ 74832baf-5779-47f6-907e-5288420bb1b9
let
	turing = Turing(zeros(Int64, 11), 6, 'A')
	@info turing
	try
		while true
			stepturing!(turing, applyrulebusybeaver)
			@info turing
		end
	catch err
		@info err
	end
end

# ╔═╡ Cell order:
# ╠═310ce685-2661-4f32-bf14-91a4f4e569ce
# ╟─e9873822-4bf1-425e-bc32-98922b27995f
# ╟─a27d4d98-c20c-4251-b7ba-73e60fcb472c
# ╟─56f41ca0-eb93-11ea-1ea6-11b0e8bb9a7d
# ╟─dab709d0-eb93-11ea-050e-3bfa6a5e1836
# ╟─f4b601b0-eb93-11ea-0969-7967a1e85c8b
# ╠═14a02c30-eb94-11ea-2114-5102409c8ae5
# ╟─1a915240-eb94-11ea-087f-231ade62690d
# ╠═2393fe0e-eb94-11ea-2858-b50503395d4a
# ╟─2dde4510-eb94-11ea-212a-5da1e7733bf6
# ╟─35cbd760-eb94-11ea-201a-6b58802154a1
# ╟─758a0c50-eb94-11ea-11a2-e3e007b089a9
# ╟─2d708d14-38ff-4554-b3ce-a2e5b8ef7eff
# ╠═d8481030-eb94-11ea-1af4-db838adc37ed
# ╟─49527027-1c4a-460a-b455-de2767a3c0ef
# ╠═5cb02abd-dacc-4cec-96f0-387455dfb495
# ╟─e393e8b2-eb94-11ea-3d70-d31f7ee89420
# ╠═eed0a600-eb94-11ea-1863-0f33980508ba
# ╟─af9f9fad-66dc-44c9-baf0-d553a1487f2e
# ╠═0749769f-ff28-45d7-8ebb-3bd2de8e36cd
# ╟─0002a810-eb95-11ea-2ba8-bb2849bdec17
# ╠═04139c70-eb95-11ea-1759-298193ce97b0
# ╟─108edf3d-c230-4180-8892-6f8d487ca650
# ╠═60e8deb0-eb95-11ea-2bde-d9c259432318
# ╟─10100040-eb95-11ea-3a6d-271e63301b17
# ╠═1a508340-eb95-11ea-08f9-6f085748d7ff
# ╟─5d2a01f0-eb95-11ea-3dcd-b794e1b0d566
# ╠═6a08d680-eb95-11ea-17b5-d199cc14b12a
# ╟─9db5c010-eb95-11ea-3257-652ddbd3939d
# ╠═adfe9aa0-eb95-11ea-1ce9-e5370aeec375
# ╟─1c6b5780-eb96-11ea-2bbd-755d35c27938
# ╠═2bcfc580-eb96-11ea-1837-c703fac6cd69
# ╟─4d3dd0e0-eb96-11ea-0f6a-8f6fb24e8f9d
# ╠═4d2f51f0-eb96-11ea-1c16-b7b7b81a3ca3
# ╟─8eb8d100-eb96-11ea-12f5-751c018540fc
# ╟─a075adee-eb96-11ea-3ddc-572f2795d6b5
# ╠═aed6b5b0-eb96-11ea-2a3d-7f82f61ea518
# ╟─c56df180-eb96-11ea-1a57-2d0571da6ac3
# ╟─11fa5930-eb97-11ea-274e-3f2c45958666
# ╟─9b61fa20-eb97-11ea-0f1c-c922c04a796f
# ╟─c21ab861-5522-436c-a253-18b664592528
# ╠═3d3d0ff7-1026-4ce2-85d6-5606c6b86dba
# ╠═7bc324ef-c92e-44e6-9d74-6f8c47be5d4e
# ╠═3ffda0e6-2bc1-46a0-bbac-2b350f31b1c3
# ╠═9c71d310-d18a-4abf-937a-b7c22ca35a38
# ╠═e9194e90-4afd-4645-bf07-7ee276b3e12c
# ╟─c490e7fb-a60f-4e11-a336-118a10406d54
# ╠═6fd08ac6-932e-45d8-9fd8-a4c87e90b139
# ╠═1c0a1ea7-0fb8-40b5-96cf-e1321ec2c05d
# ╠═147af6e2-6927-4ee6-a402-7efe5550b418
# ╠═6bfc41ee-a799-4c95-863a-46ac7110ff10
# ╟─aea98b31-7840-4822-b731-12c5a40b14b5
# ╠═37f558b7-8df1-4ab7-9394-78d2eb8032c1
# ╠═3b061fd5-d860-4af9-9d3b-625982227b98
# ╠═8238a3ab-d39f-449f-b465-975a8db707d9
# ╟─8a48dd07-b924-481b-9fc7-c49a7c8e38ff
# ╠═2b3157b8-6342-4cb1-a09d-212a76d53071
# ╠═9bad3752-5733-46cb-a598-72fb4042aafa
# ╠═ddfa10fe-0856-4d49-9cca-d1e3c6b2c1a9
# ╟─033db172-d8ee-4a21-9f2a-85214777b9a4
# ╠═07e99ce2-da75-4c71-a873-b36579f787c9
# ╠═21bc6cfe-dff1-4ae8-a814-3fbb137f3ab6
# ╠═b8c2f6db-a087-4785-9ea8-9592857c943d
# ╟─aac83f03-252e-4006-9b4c-9b869c9e9b6b
# ╟─d128ac2e-69d2-4122-aa1f-de65355ae6a2
# ╟─4ab7fbe2-c8a8-44e5-91d3-c1eb7d15b7ee
# ╠═6a2a9c8a-5a39-4ccd-aa4b-a9a333be92b8
# ╠═0e419a01-0e16-4425-b5aa-cedf587fc49c
# ╟─32793422-29c0-4700-a852-ac20190eb99e
# ╟─83a0d73e-354f-4699-b700-6dddec18619d
# ╟─fc9d0a1a-d8c8-41dd-a092-e5470dc7fdd7
# ╟─f3510f3d-259d-4678-a2ed-81c1f5a2fd72
# ╟─68d9c2ed-a762-4e3c-b00b-e82c8ac637b2
# ╟─f2a45860-eb96-11ea-2e5f-b1850621020b
# ╠═fa9e94e0-eb96-11ea-061c-a36a28f5e7b1
# ╠═1a07f6a0-eb97-11ea-0f51-a3d742fcf260
# ╠═7bfdef90-eb97-11ea-03ce-4fb081079815
# ╠═a68bf2c0-eb97-11ea-30ea-87d20ea07175
# ╟─a3263280-eb97-11ea-2e91-532bfa433f6c
# ╠═be984390-ebb1-11ea-0729-39795172949b
# ╟─d24b2602-9be2-44d6-8ec1-307e5feab26e
# ╠═74832baf-5779-47f6-907e-5288420bb1b9
