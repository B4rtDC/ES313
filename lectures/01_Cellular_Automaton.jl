### A Pluto.jl notebook ###
# v0.19.42

using Markdown
using InteractiveUtils

# ╔═╡ 310ce685-2661-4f32-bf14-91a4f4e569ce
# Explicit use of own environment instead of a local one for each notebook
begin
	# Pkg needs to be used to force Pluto to use the current project instead of making an environment for each notebook
	using Pkg
	# this is redundant if you run it through start.jl, but to make sure...
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using PlutoUI
	PlutoUI.TableOfContents()
end

# ╔═╡ a27d4d98-c20c-4251-b7ba-73e60fcb472c
# Dependencies
begin
using NativeSVG # SVG plotting library
using Random    # for random related activities
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
md"""# Cellular Automaton

Port of [Think Complexity chapter 5](http://greenteapress.com/complexity2/html/index.html) by Allen Downey."""

# ╔═╡ dab709d0-eb93-11ea-050e-3bfa6a5e1836
md"Cellular Automaton (CA) = discrete space (cells) as input for a calculation in discrete time"

# ╔═╡ f4b601b0-eb93-11ea-0969-7967a1e85c8b
md"""## A Trivial Example

0 dimensional CA, inverting its cell at each timestep (2 state values only)

rule:"""

# ╔═╡ 14a02c30-eb94-11ea-2114-5102409c8ae5
function rule0dim(x::Bool)
    !x
end

# ╔═╡ 1a915240-eb94-11ea-087f-231ade62690d
md"time evolution:"

# ╔═╡ 2393fe0e-eb94-11ea-2858-b50503395d4a
function step0dim(x₀::Bool, steps::Int64)
    xs = [x₀]
    for i in 1:steps
        push!(xs, rule0dim(xs[end]))
    end
    xs
end

# ╔═╡ 2dde4510-eb94-11ea-212a-5da1e7733bf6
md"visualisation:"

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

This is a 1-dimensional CA with 2 state values (i.e. 0 or 1). The new value of a cell depends only on its own state and the state of its two neighbouring cells. The outcomes can be represented as a table:


|prev         |111|110|101|100|011|010|001|000|
|-------------|---|---|---|---|---|---|---|---|
|next         |0  |0  |1  |1  |0  |0  |1  |0  |
|byte position|``b_7`` |``b_6`` |``b_5`` |``b_4`` |``b_3`` |``b_2`` |``b_1`` |``b_0`` |


Based on the byte positions, we can convert a rule into an integer. The present example can be transformed as follows:
```math
\sum_{i=0}^{7} b_{i} 2^{i}.
```
When aplied to our example, we find "rule 50".
"""

# ╔═╡ d8481030-eb94-11ea-1af4-db838adc37ed
"""
	inttorule1dim(val::UInt8)

Transform an integer into a rule for Wolfram's experiment
"""
function inttorule1dim(val::UInt8)
	# convert value into binary
    digs = BitArray(digits(val, base=2))
	# pad with additional 'zeros'
    for i in length(digs):7
        push!(digs, false)
    end
	
    return digs
end

# ╔═╡ 5cb02abd-dacc-4cec-96f0-387455dfb495
begin
	# rule 50
	rule_50 = inttorule1dim(UInt8(50))
	# examples (max, rand, min, rule_50)
	(inttorule1dim(UInt8(255)), inttorule1dim(UInt8(rand(0:255))), inttorule1dim(UInt8(0)), rule_50)
end

# ╔═╡ e393e8b2-eb94-11ea-3d70-d31f7ee89420
md"""
We now need to define a function that allows us to apply a rule to a cell knowing its own previous state and the previous state of his left and right neighbour:
"""

# ╔═╡ eed0a600-eb94-11ea-1863-0f33980508ba
"""
	applyrule1dim(rule::BitArray{1}, bits::BitArray{1})

Return the new state based on the own states and the left and right neigbor.
"""
function applyrule1dim(rule::BitArray{1}, bits::BitArray{1})
	# get position in rule
    pos = 1 + bits[3] + 2*bits[2] + 4*bits[1]
	# return next value
    return rule[pos]
end

# ╔═╡ 0749769f-ff28-45d7-8ebb-3bd2de8e36cd
# quick test
applyrule1dim(rule_50, BitVector([0, 0, 1]))

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
    xs
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

# ╔═╡ 6a08d680-eb95-11ea-17b5-d199cc14b12a
visualize1dim(res, 30)

# ╔═╡ 9db5c010-eb95-11ea-3257-652ddbd3939d
md"""## Classifying CAs

### Class 1

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
md"""### Class 2

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
md"""### Class 3

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
md"""### Class 4

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

- The collisions are the basis of computation in a rule110 CA. You can think of spaceships as signales that propagate through space, and collisions as gate that compute logical operations like AND and OR."""

# ╔═╡ f2a45860-eb96-11ea-2e5f-b1850621020b
md"""## Turing State-Machines

Based on [wikipedia: Turing Machine](https://en.wikipedia.org/wiki/Turing_machine).

A Turing machine is a mathematical model of computation that defines an abstract machine, which manipulates symbols on a tape according to a table of rules. Despite the model's simplicity, given any computer algorithm, a Turing machine capable of simulating that algorithm's logic can be constructed.

- A tape divided into cells, one next to the other. Each cell contains a symbol from some finite alphabet. The alphabet contains a special blank symbol (here written as '0') and one or more other symbols. The tape is assumed to be arbitrarily extendable to the left and to the right, i.e., the Turing machine is always supplied with as much tape as it needs for its computation. Cells that have not been written before are assumed to be filled with the blank symbol. In some models the tape has a left end marked with a special symbol; the tape extends or is indefinitely extensible to the right.
- A head that can read and write symbols on the tape and move the tape left and right one (and only one) cell at a time. In some models the head moves and the tape is stationary.
- A state register that stores the state of the Turing machine, one of finitely many. Among these is the special start state with which the state register is initialized. These states, writes Turing, replace the "state of mind" a person performing computations would ordinarily be in.
- A finite table of instructions that, given the state the machine is currently in and the symbol it is reading on the tape (symbol currently under the head), tells the machine to do the following in sequence:
    - Erase or write a symbol.
    - Move the head ( 'L' for one step left or 'R' for one step right or 'N' for staying in the same place).
    - Assume the same or a new state as prescribed.

Below you can find a table of rules for one such machine:

| Tape Symbol | State A   | State B   | State C   |
|:-----------:|-----------|-----------|-----------|
| 0           | 1 - R - B | 1 - L - A | 1 - L - B |
| 1           | 1 - L - C | 1 - R - B | 1 - R - H |

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

# ╔═╡ 11fa5930-eb97-11ea-274e-3f2c45958666
md"""
We can define our own struct to represent the Turing State-Machine:"""

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

# ╔═╡ 9b61fa20-eb97-11ea-0f1c-c922c04a796f
md"Implementation of a step:"

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
        turing.position += 1
    else
        if turing.position == 1
            pushfirst!(turing.tape, false)
        else
            turing.position -= 1
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
# ╟─310ce685-2661-4f32-bf14-91a4f4e569ce
# ╟─e9873822-4bf1-425e-bc32-98922b27995f
# ╟─56f41ca0-eb93-11ea-1ea6-11b0e8bb9a7d
# ╟─dab709d0-eb93-11ea-050e-3bfa6a5e1836
# ╠═a27d4d98-c20c-4251-b7ba-73e60fcb472c
# ╟─f4b601b0-eb93-11ea-0969-7967a1e85c8b
# ╠═14a02c30-eb94-11ea-2114-5102409c8ae5
# ╟─1a915240-eb94-11ea-087f-231ade62690d
# ╠═2393fe0e-eb94-11ea-2858-b50503395d4a
# ╟─2dde4510-eb94-11ea-212a-5da1e7733bf6
# ╠═35cbd760-eb94-11ea-201a-6b58802154a1
# ╟─758a0c50-eb94-11ea-11a2-e3e007b089a9
# ╠═d8481030-eb94-11ea-1af4-db838adc37ed
# ╠═5cb02abd-dacc-4cec-96f0-387455dfb495
# ╟─e393e8b2-eb94-11ea-3d70-d31f7ee89420
# ╠═eed0a600-eb94-11ea-1863-0f33980508ba
# ╠═0749769f-ff28-45d7-8ebb-3bd2de8e36cd
# ╟─0002a810-eb95-11ea-2ba8-bb2849bdec17
# ╠═04139c70-eb95-11ea-1759-298193ce97b0
# ╟─10100040-eb95-11ea-3a6d-271e63301b17
# ╠═1a508340-eb95-11ea-08f9-6f085748d7ff
# ╟─5d2a01f0-eb95-11ea-3dcd-b794e1b0d566
# ╠═60e8deb0-eb95-11ea-2bde-d9c259432318
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
# ╟─f2a45860-eb96-11ea-2e5f-b1850621020b
# ╠═fa9e94e0-eb96-11ea-061c-a36a28f5e7b1
# ╟─11fa5930-eb97-11ea-274e-3f2c45958666
# ╠═1a07f6a0-eb97-11ea-0f51-a3d742fcf260
# ╠═7bfdef90-eb97-11ea-03ce-4fb081079815
# ╟─9b61fa20-eb97-11ea-0f1c-c922c04a796f
# ╠═a68bf2c0-eb97-11ea-30ea-87d20ea07175
# ╟─a3263280-eb97-11ea-2e91-532bfa433f6c
# ╠═be984390-ebb1-11ea-0729-39795172949b
# ╟─d24b2602-9be2-44d6-8ec1-307e5feab26e
# ╠═74832baf-5779-47f6-907e-5288420bb1b9
