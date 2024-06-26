### A Pluto.jl notebook ###
# v0.19.42

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ fe5b0068-f67d-11ea-11e2-5925e8699ff0
begin
	# Pkg needs to be used to force Pluto to use the current project instead of making an environment for each notebook
	using Pkg
	# this is redundant if you run it through start.jl, but to make sure...
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using PlutoUI
	PlutoUI.TableOfContents()
end

# ╔═╡ ddc30e2a-d9fc-42df-b89d-d8e16862e140
# Dependencies
begin
using NativeSVG # SVG plotting library
using Plots    # for random related activities
end

# ╔═╡ aea7c1dd-5a59-44d1-85e0-2a4115fca307
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

# ╔═╡ f260f2c2-f67d-11ea-0132-4523bff8cea4
md"""# Self-Organized Criticality

Port of [Think Complexity chapter 8](http://greenteapress.com/complexity2/html/index.html) by Allen Downey."""

# ╔═╡ 1839ed8c-f67e-11ea-2c86-8954fe2d6dd5
md"""## Critical Systems

Many critical systems demonstrate common behaviors:

- Fractal geometry: For example, freezing water tends to form fractal patterns, including snowflakes and other crystal structures. Fractals are characterized by self-similarity; that is, parts of the pattern are similar to scaled copies of the whole.

- Heavy-tailed distributions of some physical quantities: For example, in freezing water the distribution of crystal sizes is characterized by a power law.

- Variations in time that exhibit [pink noise](https://en.wikipedia.org/wiki/Pink_noise): Complex signals can be decomposed into their frequency components. In pink noise, low-frequency components have more power than high-frequency components. Specifically, the power at frequency f is proportional to 1/f.

Critical systems are usually unstable. For example, to keep water in a partially frozen state requires active control of the temperature. If the system is near the critical temperature, a small deviation tends to move the system into one phase or the other."""

# ╔═╡ 2210e0ae-f67e-11ea-3052-87bff5a116fa
md"""## Sand Piles

The sand pile model was [proposed by Bak, Tang and Wiesenfeld in 1987](https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.59.381). It is not meant to be a realistic model of a sand pile, but rather an abstraction that models physical systems with a large number of elements that interact with their neighbors.

The sand pile model is a 2-D cellular automaton where the state of each cell represents the slope of a part of a sand pile. During each time step, each cell is checked to see whether it exceeds a critical value, `K`, which is usually 3. If so, it “topples” and transfers sand to four neighboring cells; that is, the slope of the cell is decreased by 4, and each of the neighbors is increased by 1. At the perimeter of the grid, all cells are kept at slope 0, so the excess spills over the edge.

Bak, Tang and Wiesenfeld initialize all cells at a level greater than `K` and run the model until it stabilizes. Then they observe the effect of small perturbations: they choose a cell at random, increment its value by 1, and run the model again until it stabilizes.

For each perturbation, they measure `T`, the number of time steps the pile takes to stabilize, and `S`, the total number of cells that topple.

Most of the time, dropping a single grain causes no cells to topple, so `T=1` and `S=0`. But occasionally a single grain can cause an avalanche that affects a substantial fraction of the grid. The distributions of `T` and `S` turn out to be heavy-tailed, which supports the claim that the system is in a critical state.

They conclude that the sand pile model exhibits “self-organized criticality”, which means that it evolves toward a critical state without the need for external control or what they call “fine tuning” of any parameters. And the model stays in a critical state as more grains are added.

In the next few sections we will replicate their experiments and interpret the results."""

# ╔═╡ 2a6c14b2-f67e-11ea-0ad1-db86beb0602a
md"""### Implementation"""

# ╔═╡ 539a8576-f67e-11ea-07ba-b11f07f7ad39
"""
	applytoppling(array::Array{Int64, 2}, K::Int64=3)

Given an `array` and a treshold value `K` above which the sand piles will topple, determine the new state.
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

# ╔═╡ 5c141fe6-f67e-11ea-343f-bf6e672aa0ca
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

# ╔═╡ b95e615e-f67e-11ea-3d58-b5166ea2c0ca
"""
	steptoppling(array::Array{Int64, 2}, K::Int64=3)

Do a single toppling iteration for the `array` using treshold value `K` above which the sand piles will topple. I.e. this function will run untill no more changes in the state occur.
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

# ╔═╡ ff579efa-f67e-11ea-0f08-999fb18421c3
"""
	Pile

A struct used to hold and instantiate a sand pile. 
Initialy, everyting set to the value `initial`, except for the boundaries, which are set to zero.
"""
mutable struct Pile
	array::Array{Int64, 2}
	function Pile(dim::Int64, initial::Int64)
		pile = zeros(Int64, dim, dim)
		pile[2:end-1, 2:end-1] = initial * ones(Int64, dim-2, dim-2)
		new(pile)
	end
end

# ╔═╡ a1683e6e-f67f-11ea-2b79-8552ffaa92e3
pile20 = Pile(22, 10);

# ╔═╡ af120f36-f67f-11ea-2825-e14581e0ded8
visualizepile(pile20.array, 30, 10)

# ╔═╡ d04bea1e-f67f-11ea-1bc8-5bbd9a7666f0
begin
	pile20.array, steps, total = steptoppling(pile20.array);
	@info "pile20 toppled in $(steps) steps and a total of $(total) topplings occured."
end

# ╔═╡ f3adf3f8-f67f-11ea-2a18-7d2f8d93e817
visualizepile(pile20.array, 30, 10)

# ╔═╡ fa60b5aa-f67f-11ea-3ec0-bfaf222f3415
md"""With an initial level of 10, this sand pile takes 332 time steps to reach equilibrium, with a total of 53,336 topplings. The figure shows the configuration after this initial run. Notice that it has the repeating elements that are characteristic of fractals. We’ll come back to that soon."""

# ╔═╡ ef1f49cc-f67f-11ea-04e9-817d6bc2c902
"""
	drop(array::Array{Int64, 2})

Drop a new grain of sand on a random non-boundary element.
"""
function drop(array::Array{Int64, 2})
    (ydim, xdim) = size(array)
    y = rand(2:ydim-1)
    x = rand(2:xdim-1)
    array[y,x] += 1
	
    return array
end

# ╔═╡ 6f3dcd7c-f680-11ea-2929-f94b53bd7a67
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

# ╔═╡ 79230ffa-f680-11ea-3432-4d50e71a2935
@bind toggletoppling html"<input type=button value='Next'>"

# ╔═╡ b1472044-f67e-11ea-0c87-5be8f6114fef
if toggletoppling === "Next"
	for _ in 1:200
		pile20.array = drop(pile20.array)
    	pile20.array, steps, total = steptoppling(pile20.array)
	end
	visualizepile(pile20.array, 30, 10)
end

# ╔═╡ 082bbb5c-f681-11ea-007a-f5a8df45b69d
md"""The figure shows the configuration of the sand pile after dropping 200 grains onto random cells, each time running until the pile reaches equilibrium. The symmetry of the initial configuration has been broken; the configuration looks random."""

# ╔═╡ 0d14ce24-f681-11ea-1637-5f4cf290f81d
begin
	for _ in 1:200
    	pile20.array = drop(pile20.array)
    	pile20.array, steps, total = steptoppling(pile20.array)
	end
	visualizepile(pile20.array, 30, 10)
end

# ╔═╡ 39100fb6-f681-11ea-0e1e-693359773c9c
md"""Finally the figure shows the configuration after 400 drops. It looks similar to the configuration after 200 drops. In fact, the pile is now in a steady state where its statistical properties don’t change over time. Some of those statistical properties will be explained in the next section."""

# ╔═╡ 42cc5096-f681-11ea-0744-5d078169fd28
md"""### Heavy-Tailed Distributions & power laws

If the sand pile model is in a critical state, we expect to find heavy-tailed distributions for quantities like the duration and size of avalanches. So let’s take a look.

Let's make a larger sand pile, with n=50 and an initial level of 30, and run until equilibrium with 100,000 random drops:"""

# ╔═╡ 4f12ad3c-f681-11ea-31e4-1ddc4d78694e
pile50 = Pile(50, 30);

# ╔═╡ c38c4bb4-f681-11ea-2569-85142c07e21e
durations, avalanches = begin
	durations = Int64[]
	avalanches = Int64[]
	for _ in 1:100000
		pile50.array = drop(pile50.array)
		pile50.array, steps, total = steptoppling(pile50.array)
		push!(durations, steps)
		push!(avalanches, total)
	end

	# only keep durations above 1 and avalanches more than 0
	filter(steps->steps>1, durations), filter(total->total>0, avalanches);
end

# ╔═╡ 00597288-f682-11ea-31d4-278441aaca2c
md"""A large majority of drops have duration 1 and no toppled cells; if we filter them out before plotting, we get a clearer view of the rest of the distribution.

We build a histogram with the durations/avalanches as keys and their occurences as values."""

# ╔═╡ 19c9c10a-f682-11ea-235a-1b78e0af52b4
"""
	hist(array)

Generate a frequency histogram of the `array` as a dictionary.
"""
function hist(array)
    h = Dict()
    for v in array
        h[v] = get!(h, v, 0) + 1
    end
    h
end

# ╔═╡ 5e3575ee-f682-11ea-3df7-5f4b9439c646
md"""We plot the probabilities of each value of the durations / avalanches with loglog axes."""

# ╔═╡ 71e25a5a-f682-11ea-006f-abcdefc354c2
let
	# duration part of the plot
	h = hist(durations)
	total = sum(values(h))
	x = Int64[]
	y = Float64[]
	for i in 2:maximum(collect(keys(h)))
		v = get(h, i, 0)
		if v ≠ 0
			push!(x, i)
			push!(y, v/total)
		end
	end
	scatter(x, y, xaxis=:log, yaxis=:log, label="Durations", alpha=0.5)
	# add trend based on values below 100 (linear regression)
	inds = findall(x -> x <= 100, x)
	X = [log.(x[inds]).^0 log.(x[inds]) ]
	Y = log.(y[inds])
	b = (X' * X) \  (X' * Y)
	x = collect(1:5000)
	plot!(x, x .^ b[2] * exp(b[1]), color=:gray, label="")
	@info "Duration log-log slope: $(b[2])"

	# avalanche count part of the plot
	h = hist(avalanches)
	total = sum(values(h))
	x = Int64[]
	y = Float64[]
	for i in 1:maximum(collect(keys(h)))
		v = get(h, i, 0)
		if v ≠ 0
			push!(x, i)
			push!(y, v/total)
		end
	end
	scatter!(x, y, xaxis=:log, yaxis=:log, label="Avalanches", alpha=0.5)
	# add trend based on values below 100 (linear regression)
	inds = findall(x -> x <= 100, x)
	X = [log.(x[inds]).^0 log.(x[inds]) ]
	Y = log.(y[inds])
	b = (X' * X) \  (X' * Y)
	x = collect(1:5000)
	plot!(x, x .^ b[2] * exp(b[1]), color=:gray, label="")
	@info "Avalanche log-log slope: $(b[2])"

	# general slope part of the plot
	x = collect(1:5000)
	plot!(x, 1 ./ x, label="slope -1", color=:black, xlabel="Value", ylabel="Probability")
	
	#@info b[2] * x .+ b[1]
end

# ╔═╡ 93ff6fce-f682-11ea-375f-691a773a4015
md"""For values between 1 and 100, the distributions are nearly straight on a log-log scale, which is characteristic of a heavy tail. The gray lines in the figure have slopes near -1, which suggests that these distributions follow a power law with parameters near α=1.

For values greater than 100, the distributions fall away more quickly than the power law model, which means there are fewer very large values than the model predicts. One possibility is that this effect is due to the finite size of the sand pile; if so, we might expect larger piles to fit the power law better."""

# ╔═╡ 89a1673a-f682-11ea-3839-a13baae73084
md"""### Fractals

Another property of critical systems is fractal geometry. The initial configuration resembles a fractal, but you can’t always tell by looking. A more reliable way to identify a fractal is to estimate its fractal dimension, as we saw in previous lectures.

Let's start by making a bigger sand pile, with `n=131` and initial level 22."""

# ╔═╡ e3bc11fc-f682-11ea-092b-df0887d4e0b1
pile131 = Pile(133, 22);

# ╔═╡ 011377c2-f683-11ea-0bf0-9f3f1ee4d0d2
let
	pile131.array, steps, total = steptoppling(pile131.array)
	steps, total
end

# ╔═╡ 44db4192-f683-11ea-385a-692911a834bd
visualizepile(pile131.array, 4, 10)

# ╔═╡ 66ddeb8c-f683-11ea-3a68-6f1e4f0f5cc0
md"""It takes 28,379 steps for this pile to reach equilibrium, with more than 200 million cells toppled.
To see the resulting pattern more clearly, let's select the cells with levels 0, 1, 2, and 3, and plot them separately:"""

# ╔═╡ 769bfda2-f683-11ea-1103-7302a19f909f
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

# ╔═╡ bc1f2d22-f683-11ea-1dcc-21b4e3a235d2
visualizepileonekind(pile131.array, 4, 0) # 0, 1, 2, 3

# ╔═╡ d0a5d958-f683-11ea-0f60-2189804eedd2
md"""Visually, these patterns resemble fractals, but looks can be deceiving. To be more confident, we can estimate the fractal dimension for each pattern using [box-counting](https://en.wikipedia.org/wiki/Box_counting).

We will count the number of cells in a small box at the center of the pile, then see how the number of cells increases as the box gets bigger."""

# ╔═╡ dc3aa8ac-f683-11ea-07a3-1dd0b339ed20
"""
	countcells(pile, val)

For a given sand `pile`, count those cells that have a value equal to `val` for increasing box sizes.
"""
function countcells(pile, val)
    (ydim, xdim) = size(pile)
    ymid = Int((ydim+1)/2)
    xmid = Int((xdim+1)/2)
    res = Int64[]
    for i in 0:Int((ydim-1)/2)-1
        push!(res, 1.0*count(x->x==val, pile[ymid-i:ymid+i,xmid-i:xmid+i]))
    end
	
    return res
end

# ╔═╡ 7cc80c4e-2e18-4a87-84ca-07c9a7d18c4b
countcells(pile131.array, 2)

# ╔═╡ cf14e6b0-f683-11ea-22d8-51ac2e84ae1f
let 
	(ydim, xdim) = size(pile131.array)
	m = Int((ydim-1)/2)
	fp = plot(1:2:2*m-1, 1:2:2*m-1, xaxis=:log, yaxis=:log, label="d = 1",legend=:topleft, xlabel="Box size", ylabel="Dimension")
	plot!(fp,1:2:2*m-1, (1:2:2*m-1).^2, xaxis=:log, yaxis=:log, label="d = 2")
	for level in [0;1;2;3]
		res = filter(x->x>0, countcells(pile131.array, level))
		n = length(res)
		plot!(fp,1+2*(m-n):2:2*m-1, res, xaxis=:log, yaxis=:log, label="level $level")
	end
	fp
end

# ╔═╡ 1d2387c6-f684-11ea-28cc-bb2ad15a66ab
md"""On a log-log scale, the cell counts form nearly straight lines, which indicates that we are measuring fractal dimension over a valid range of box sizes.

To estimate the slopes of these lines, we have to fit a line to the data by linear regression"""

# ╔═╡ cd1481b0-f683-11ea-3e20-2b9af0d081f5
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

# ╔═╡ e2614b24-8fa2-4a7d-ae9d-47b402e10e5f
md"""
The estimated fractal dimensions are:
"""

# ╔═╡ 2e68131e-4013-4d4e-a7d0-cba973aa7f51
begin 
	level_frac_dims = [(level, (begin 	(ydim, xdim) = size(pile131.array) 
										m = Int((ydim-1)/2)
										res = filter(x->x>0, countcells(pile131.array, level))
										n = length(res)
										linres(log.(1.0*collect(1+2*(m-n):2:2*m-1)), 
										log.(res)) end)[2])
						for level in [0;1;2;3]]
	msg = join(["$(level): $(frac_dim)" for (level, frac_dim) in level_frac_dims], "\n")
	@info """
	
	$(msg)
	"""
end

# ╔═╡ Cell order:
# ╟─fe5b0068-f67d-11ea-11e2-5925e8699ff0
# ╟─aea7c1dd-5a59-44d1-85e0-2a4115fca307
# ╠═ddc30e2a-d9fc-42df-b89d-d8e16862e140
# ╟─f260f2c2-f67d-11ea-0132-4523bff8cea4
# ╟─1839ed8c-f67e-11ea-2c86-8954fe2d6dd5
# ╟─2210e0ae-f67e-11ea-3052-87bff5a116fa
# ╟─2a6c14b2-f67e-11ea-0ad1-db86beb0602a
# ╠═539a8576-f67e-11ea-07ba-b11f07f7ad39
# ╠═5c141fe6-f67e-11ea-343f-bf6e672aa0ca
# ╠═b95e615e-f67e-11ea-3d58-b5166ea2c0ca
# ╠═ff579efa-f67e-11ea-0f08-999fb18421c3
# ╠═a1683e6e-f67f-11ea-2b79-8552ffaa92e3
# ╠═af120f36-f67f-11ea-2825-e14581e0ded8
# ╠═d04bea1e-f67f-11ea-1bc8-5bbd9a7666f0
# ╠═f3adf3f8-f67f-11ea-2a18-7d2f8d93e817
# ╟─fa60b5aa-f67f-11ea-3ec0-bfaf222f3415
# ╠═ef1f49cc-f67f-11ea-04e9-817d6bc2c902
# ╠═6f3dcd7c-f680-11ea-2929-f94b53bd7a67
# ╟─79230ffa-f680-11ea-3432-4d50e71a2935
# ╠═b1472044-f67e-11ea-0c87-5be8f6114fef
# ╟─082bbb5c-f681-11ea-007a-f5a8df45b69d
# ╠═0d14ce24-f681-11ea-1637-5f4cf290f81d
# ╟─39100fb6-f681-11ea-0e1e-693359773c9c
# ╟─42cc5096-f681-11ea-0744-5d078169fd28
# ╠═4f12ad3c-f681-11ea-31e4-1ddc4d78694e
# ╠═c38c4bb4-f681-11ea-2569-85142c07e21e
# ╟─00597288-f682-11ea-31d4-278441aaca2c
# ╟─19c9c10a-f682-11ea-235a-1b78e0af52b4
# ╟─5e3575ee-f682-11ea-3df7-5f4b9439c646
# ╟─71e25a5a-f682-11ea-006f-abcdefc354c2
# ╟─93ff6fce-f682-11ea-375f-691a773a4015
# ╟─89a1673a-f682-11ea-3839-a13baae73084
# ╠═e3bc11fc-f682-11ea-092b-df0887d4e0b1
# ╠═011377c2-f683-11ea-0bf0-9f3f1ee4d0d2
# ╠═44db4192-f683-11ea-385a-692911a834bd
# ╟─66ddeb8c-f683-11ea-3a68-6f1e4f0f5cc0
# ╠═769bfda2-f683-11ea-1103-7302a19f909f
# ╠═bc1f2d22-f683-11ea-1dcc-21b4e3a235d2
# ╟─d0a5d958-f683-11ea-0f60-2189804eedd2
# ╠═dc3aa8ac-f683-11ea-07a3-1dd0b339ed20
# ╠═7cc80c4e-2e18-4a87-84ca-07c9a7d18c4b
# ╟─cf14e6b0-f683-11ea-22d8-51ac2e84ae1f
# ╟─1d2387c6-f684-11ea-28cc-bb2ad15a66ab
# ╠═cd1481b0-f683-11ea-3e20-2b9af0d081f5
# ╟─e2614b24-8fa2-4a7d-ae9d-47b402e10e5f
# ╟─2e68131e-4013-4d4e-a7d0-cba973aa7f51
