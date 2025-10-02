### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ dc3c2030-144f-11eb-08ab-0b68dc2698ac
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using BenchmarkTools
end

# ╔═╡ 615d2b78-9a47-41bf-bae4-f0f7fb875956
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

# ╔═╡ 1c49d8ae-144e-11eb-024a-137460f78b15
md"""
# Performance
During the introductory session, we already covered the performance benefits of Julia compared to other dynamic languages such as Python and R. It is however of utmost importance that you get a feeling for the programming *best practices* in Julia to fully exploit its capabilities.

When building more complex programs, performance can be an issue. The [performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/) website already contains a lot tips. We will briefly summarise these performance tips before we proceed with a few examples.

!!! info "Performance Tips"
	- **Put performance-critical code inside functions:**  
	  Julia’s compiler optimizes functions much better than code in global scope.
	
	- **Avoid untyped global variables:**  
	  Globals slow down code; use local variables or pass arguments to functions. Mark truly constant globals as `const`.
	
	- **Avoid containers with abstract type parameters:**  
	  Use concrete types where possible for better memory layout and speed.
	
	- **Write type-stable code:**  
	  Types should be predictable and not change dynamically during execution to allow compiler optimizations.
	
	- **Use parametric types for structs:**  
	  This helps Julia generate efficient code for multiple concrete types.
	
	- **Avoid fields with abstract types in structs:**  
	  This prevents dynamic dispatch and type instability.
	
	- **Break complex functions into multiple methods:**  
	  Helps compiler generate specialized, optimized code.
	
	- **Profile and benchmark regularly:**  
	  Identify bottlenecks and optimize where it counts.

These tips collectively help write fast, efficient, and idiomatic Julia code.

We will illustrate potential **performance gains** for a function by providing one or more alternatives. 

!!! warning "Validity"
	In order to make sure the the functions produce the same result, the results are verified to be identical before starting the benchmarks.

The actual performance is measured using [BenchmarkTools](https://github.com/JuliaCI/BenchmarkTools.jl). BenchmarkTools repeatedly runs your code snippet and collects timing samples while accounting for system noise and compiler optimizations. You can customize the benchmarking process and exclude setup costs.

More advanced methods (that we cannot cover due to time constraints) include **profiling** your code. Profiling tells you where in your program the time is spent. It breaks down execution time across functions and lines of code, helping identify hotspots needing optimization. In Visual Studio Code you can get a detailed overview with the [`@profview`](https://discourse.julialang.org/t/julia-vs-code-extension-version-v0-17-released/42865) macro. For a REPL based method you could use [Traceur](https://github.com/JunoLab/Traceur.jl).

## Tools
Below you can find a set of very generic functions that we will be using to evaluate the functions that we will be benchmarking.

### Notes
At some point we try to make use of multithreading. You can see the number of threads that are currently being used with
```julia
Threads.nthreads()
```

Should this be only 1, you can set the number of threads to use by setting the environment variable `JULIA_NUM_THREADS` to the required before starting julia.

In a windows terminal:
```
$env:JULIA_NUM_THREADS = 4
julia
```
In a Linux/Mac OS terminal:
```
export JULIA_NUM_THREADS=4
julia
```

both examples above suppose "julia" is known in your terminal. If this is not the case, simply replace it by the path to the julia executable.

!!! warning "Remark"
	Starting from julia 1.5 you can use command line arguments to specify the number of threads e.g. `julia --threads 4`
"""

# ╔═╡ a4ed00b8-144f-11eb-0c66-932242a1767c
begin
	"""
    testfuns(F, args...; kwargs...)

Benchmark the functions in F using `args` and `kwargs`.
"""
function testfuns(F::Union{Array{Function,1}, Array{Type,1}}, args...; kwargs...)
    # set up benchmark suite
    suite = BenchmarkGroup()
    for f in F
        suite[string(f)] = @benchmarkable $(f)($(args)...; $(kwargs)...)
    end
    # tune and run suite
    tune!(suite)
    results = run(suite, verbose=get(kwargs, :verbose, false))
    # show results
    for f in F
        println("\nResult for $(f):\n$("-"^length("Result for $(f):"))")
        display(results[string(f)])
    end
    medians = sort!([(fun, median(trial.times)) for (fun, trial) in results], by=x->x[2])
    speedup = round(Int,medians[end][2] / medians[1][2])
    println("\n$(speedup)x speedup (fastest: $(medians[1][1]), slowest: $(medians[end][1]))\n")
    return 

end
	nothing
end

# ╔═╡ e32569b0-144f-11eb-33e9-8fd8755c208f
begin
	"""
		equality(F::Array{Function,1}, args...; kwargs...)

	Verify the result of an array of functions F is the same using `args` and `kwargs`.

	### Notes
	The first function in the array is used as the reference
	"""
	function equality(F::Array{Function,1}, args...; kwargs...)
		return all([equality(F[1], F[i], args...; kwargs...) for i in 2:length(F)])
	end

	"""
		equality(f::Function, g::Function, args...; kwargs...)

	Verify the result of function f and g is the same (element-wise) using `args` and `kwargs`.
	"""
	function equality(f::Function, g::Function, args...; kwargs...)
		return all(isequal.(map(f->f(args...; kwargs...), [f, g])...))
	end

	nothing
end

# ╔═╡ ff480c88-144f-11eb-2839-598b8452a945
md"""
## Hands-on

### String Joining

How do they handle string concatenation?

!!! danger "renew"
	* `renew`: Julia strings are immutable. Each concatenation creates a new string. This leads to an $\mathcal{O}(n^2)$ complexity.
!!! tip "buffer"
	* `buffer`: Uses an *IOBuffer* as a mutable container to collect strings. Each iteration prints/appends the character to this buffer without copying the entire string repeatedly. Only once at the end, `take!(res)` extracts the entire string without overhead. This approach is $\mathcal{O}(n)$.
"""

# ╔═╡ 1e0ef46a-1450-11eb-2676-d94d5cc1f073
begin

	"""
		renew(char="", n::Int=0)

	Slow implementation of string joining
	"""
	function renew(char="", n::Int=0; kwargs...)
		res = ""
		for i in 1:n
			res *= char
		end

		return res
	end

	"""
		buffer(char="", n::Int=0)

	Fast implementation of string joining
	"""
	function buffer(char="", n::Int=0; kwargs...)
		res = IOBuffer()
		for i in 1:n
			print(res, char)
		end

		return String(take!(res))
	end

	"""
		demo1

	- Illustration of implementation issues

	speedup ∝ length
	"""
	function demo1()
		F = [renew, buffer]; 
		args=("a", 10000)
		# test validity
		@info "Testing demo 1"
		@assert equality(F, args...)
		# Run benchmark
		@info "Benching demo 1"
		testfuns(F, args...)
	end
	
	demo1()
	
end

# ╔═╡ e6c2157e-f5d1-4240-8852-86a459ee9431
md"""
### Memory Allocation

You can observe some significant differences between following functions:

!!! danger " f_alloc "
	* `f_alloc` explicitly creates a new array `result = zeros(T, size(x))` to store intermediate results.
	* Multiple reassignment operations on `result` with broadcasting. Each reassignment creates a new array due to the reassignment on the left side.
	* The parameters `props` are passed as a generic `Vector{T}`, which involves array indexing each time.

!!! tip "f_noalloc"
	* `f_noalloc` uses a structured type `Props{T<:AbstractFloat}` to store parameters as typed fields, enabling compiler optimizations and avoiding abstract type overhead.
	* The function uses `@views` to avoid copying slices of `y`.
	* The whole expression is a single broadcasted operation with `.`, `.+`, and `.*` that composes a fused operation, optimized by Julia’s broadcasting machinery when applied together. This fusion avoids temporary arrays.

"""

# ╔═╡ 41ef249a-1450-11eb-2c52-0930531fa46e
begin
	function f_alloc(x::Vector{T}, y::Array{T,2}; props::Vector{T}, kwargs...) where T
		# read properties
		prop_A = props[1]
		prop_B = props[2] 
		prop_C = props[3]
		prop_D = props[4]
		# initialise
		result = zeros(T, size(x))
		result .+= x
		# update result
		result = result .+ prop_A .* y[:,1]
		result = result .+ prop_B .* y[:,2]
		result = result .+ prop_C .* y[:,3]
		result = result .+ prop_D .* y[:,4]
		return result
	end

	struct Props{T<:AbstractFloat}
		prop_A::T
		prop_B::T
		prop_C::T
		prop_D::T
	end

	@views function f_noalloc(x::Vector{T}, y::Array{T,2}; p::Props, kwargs...) where T
		return x .+ p.prop_A .* y[:,1] .+ p.prop_B .* y[:,2] + p.prop_C .* y[:,3] + p.prop_D .* y[:,4]
	end


	"""
		demo2()

	- Avoiding unnecessary allocations
	- Using views 
	- Avoiding fields with abstract types
	"""
	function demo2()
		F = [f_alloc, f_noalloc]
		N = 10000
		x = rand(N)
		y = rand(N,4)
		args = [x, y]
		props = Float64[1,2,3,4]
		p = Props(props...)
		kwargs = Dict(:props => props, :p => p)
		# test validity
		@info "Testing demo 2"
		@assert equality(F, args...; kwargs...)
		# run benchmark
		@info "Benching demo 2"
		testfuns(F, args...; kwargs...)
	end
	
	demo2()
	
end

# ╔═╡ cbf339be-d2f4-4aa1-968f-377e0c4ae16b
md"""
### Changing variable type

!!! danger "f_typechange"
	In `f_typechange`, the variable `res` is initialized as an integer `0` by default. When summing elements `val` from the possibly floating-point array `x`, Julia must promote the type of `res` dynamically (e.g., from Int to Float) on the fly to accommodate the element types, leading to type instability and runtime overhead.

!!! tip "f_notypechange"
	In `f_notypechange`, the result variable `res` is initialized as `zero(T)`, creating a zero value exactly matching the element type of the array `x`. This makes the type of `res` stable and consistent throughout the loop, enabling Julia’s compiler to generate efficient, specialized machine code without type checks or runtime boxing/unboxing.

"""

# ╔═╡ 6332ef7e-1450-11eb-0a36-41818207b78f
begin
	# avoid changing type of a variable
	function f_typechange(x)
		res = 0
		for val in x
			res += val
		end
		return res
	end

	function f_notypechange(x::Array{T,1}) where T <: Number
		res = zero(T)
		for val in x
			res += val
		end
		return res
	end

	"""
		demo3()

	- avoid changing type of a variable
	"""
	function demo3()
		F = [f_typechange, f_notypechange]
		N = 2
		args = [rand(N)]
		# test validity
		@info "Testing demo 3"
		@assert equality(F, args...)
		# run benchmark
		@info "Benching demo 3"
		testfuns(F, args...)
	end
	
	demo3()
end

# ╔═╡ c008820b-efad-4b93-a63c-3e5ffcbf4264
md"""
### Vectorization

!!! danger "f_norm"
	`f_norm(x)` computes the expression `3x.^2 + 4x + 7x.^3` without broadcasting the entire expression at once. Julia interprets this as separate scalar operations with array exponentiation and multiplication. While the elementwise operations occur, Julia may create temporary arrays for each sub-expression (e.g., `x.^2`, `x.^3`) which results in multiple allocations and extra computation time.
!!! tip "f_vec"
	`f_vec(x)` uses the macro `@.` which applies broadcasting (elementwise operation) to the entire expression in a fused manner. The whole expression `3x.^2 + 4x + 7x.^3` is simultaneously broadcasted without generating intermediate temporary arrays. This reduces memory allocations and enables the compiler to generate faster and more efficient machine code.
"""

# ╔═╡ 75948388-1450-11eb-0a0e-431ad5929504
begin
	f_norm(x) = 3x.^2 + 4x + 7x.^3;
	f_vec(x) = @. 3x.^2 + 4x + 7x.^3;

	"""
		demo 4

	- use vectorisation where possible
	"""
	function demo4()
		F = [f_norm, f_vec]
		N::Int = 1e6
		args = [rand(N)]
		# test validity
		@info "Testing demo 4"
		@assert equality(F, args...)
		# run benchmark
		@info "Benching demo 4"
		testfuns(F, args...)
	end
	
	demo4()
	
end

# ╔═╡ fc0f8d9d-ff5f-4c78-8fd2-939cd85345f0
md"""
### Bringing it together
* Preallocation
* Multithreading
* `@view` macro

!!! info "Macros"
	* `@views`: Normally, slicing arrays creates a copy of that part of the array, which allocates new memory and slows down the code. The `@views` macro converts standard indexing operations in an expression into views, which are lightweight references to the original array data without copying.
	* `@inbounds`: Julia checks array bounds on every index operation to catch errors. `@inbounds` tells the compiler to skip these bounds checks within a block or loop. Removing bounds checks reduces overhead in tight loops with many index operations, boosting speed. However, using it means you must be sure your code does not access invalid indices, or you’ll get undefined behavior or crashes.
"""

# ╔═╡ 98e356f4-1450-11eb-0229-eb57f262ea4d
begin
	function f_nopre(x::Vector; kwargs...)
		y = similar(x)
		for i in eachindex(x)
			y[i] = sum(x[1:i])
		end
		return y
	end

	function f_pre!(x::Vector{T}; y::Vector{T}, kwargs...) where {T}
		for i in eachindex(x)
			y[i] = sum(x[1:i])
		end
		return y
	end

	function f_preboost!(x::Vector{T}; y::Vector{T}, kwargs...) where {T}
		Threads.@threads for i in eachindex(x)
			@inbounds y[i] = sum(x[1:i])
		end
		return y
	end

	@views function f_preturboboost!(x::Vector{T}; y::Vector{T}, kwargs...) where {T}
		Threads.@threads for i in eachindex(x)
			@inbounds y[i] = sum(x[1:i])
		end
		return y
	end

	"""
		demo5()

	- preallocate outputs if possible
	- make use of threads if possible
	- make use of views if possible
	- skip index check when sure of dimensions
	"""
	function demo5()
		F = [f_nopre, f_pre!, f_preboost!, f_preturboboost!]
		@info "Currently running on $(Threads.nthreads()) threads"
		N::Int = 1e4
		x::Vector = rand(N)
		y_pre = similar(x)
		args = [x]
		kwargs = Dict( :y => y_pre)
		# test validity
		@info "Testing demo 5"
		@assert equality(F, args...; kwargs...)
		# run benchmark
		@info "Benching demo 5"
		testfuns(F, args...; kwargs...)
	end
	
	demo5()
end

# ╔═╡ 55578fed-d830-4362-b00b-5acefd8d4c30
md"""
### Growing your array

!!! danger "grow"
	Each `push!` may trigger reallocation and copying as the array capacity needs to grow dynamically (often by doubling the size).
!!! tip "nogrow"
	Uses `similar(x)` to preallocate an array `res` of the exact size needed (length `N`).
"""

# ╔═╡ b341b4d2-1450-11eb-0549-7db5bd6756ba
begin
	function grow(N::Int; kwargs...)
		res = []
		for _ in 1:N
			push!(res, 1)
		end
		return res
	end

	function nogrow(N::Int; x::Array{T,1}) where{T}
		res = similar(x)
		for i in 1:N
			res[i] = 1
		end
		return res
	end

	"""
		demo6()

	- growing vs. allocating for known dimensions
	"""
	function demo6()
		N = 10000
		x = rand(N)
		F = [grow, nogrow]
		args = [N]
		kwargs = Dict(:x => x)
		# test validity
		@info "Testing demo 6"
		@assert equality(F, args...; kwargs...)
		# run benchmark
		@info "Benching demo 6"
		testfuns(F, args...; kwargs...)
	end
	
	demo6()
end

# ╔═╡ e7a21dbb-e5a9-4eae-a384-3c65198867c9
md"""
### Struct types

| Struct Type             | Mutability | Field Typing   | Performance Characteristics                           |
|------------------------|------------|----------------|-------------------------------------------------------|
| `mystruct`             | Immutable  | Untyped fields | Fast creation, but less optimized than typed structs  |
| `mytypedstruct{T}`     | Immutable  | Parametric typed | Fastest creation and access, best compiler optimization |
| `mymutablestruct`      | Mutable    | Untyped fields | Slowest creation due to heap allocation and dynamic typing overhead |
"""

# ╔═╡ c6702048-1450-11eb-1f1d-a54089545949
begin
	struct mystruct
		a
		b
		c
	end

	struct mytypedstruct{T}
		a::T
		b::T
		c::T
	end

	mutable struct mymutablestruct
		a
		b
		c
	end

	"""
		demo7

	- creation time of mutable vs unmutable structs and the parameter version
	"""
	function demo7()
		structs = [mystruct, mytypedstruct, mymutablestruct]
		@info "Benching demo 7"
		testfuns(structs, [1;2;3]...)
	end
	
	demo7()
	
end

# ╔═╡ df4563da-1450-11eb-08a7-25ed365f578c
begin
	function reader(s::mystruct)
		return (s.a, s.b, s.c)
	end

	function reader(s::mytypedstruct)
		return (s.a, s.b, s.c)
	end

	function reader(sm::mymutablestruct)
		return (sm.a, sm.b, sm.c)
	end

	"""
		demo8

	- read times of fields of mutable vs unmutable structs and the parameter version
	"""
	function demo8()
		vals = [1;2;3]
		@info "Benching demo8"
		for arg in [mystruct, mytypedstruct, mymutablestruct]
			println("\nResult for $(arg):\n$("-"^length("Result for $(arg):"))")
			x = arg(vals...)
			display(@benchmark reader($(x)))
		end
	end
	
	demo8()
end

# ╔═╡ Cell order:
# ╟─615d2b78-9a47-41bf-bae4-f0f7fb875956
# ╟─dc3c2030-144f-11eb-08ab-0b68dc2698ac
# ╟─1c49d8ae-144e-11eb-024a-137460f78b15
# ╠═a4ed00b8-144f-11eb-0c66-932242a1767c
# ╠═e32569b0-144f-11eb-33e9-8fd8755c208f
# ╟─ff480c88-144f-11eb-2839-598b8452a945
# ╠═1e0ef46a-1450-11eb-2676-d94d5cc1f073
# ╟─e6c2157e-f5d1-4240-8852-86a459ee9431
# ╠═41ef249a-1450-11eb-2c52-0930531fa46e
# ╟─cbf339be-d2f4-4aa1-968f-377e0c4ae16b
# ╠═6332ef7e-1450-11eb-0a36-41818207b78f
# ╟─c008820b-efad-4b93-a63c-3e5ffcbf4264
# ╠═75948388-1450-11eb-0a0e-431ad5929504
# ╟─fc0f8d9d-ff5f-4c78-8fd2-939cd85345f0
# ╠═98e356f4-1450-11eb-0229-eb57f262ea4d
# ╟─55578fed-d830-4362-b00b-5acefd8d4c30
# ╠═b341b4d2-1450-11eb-0549-7db5bd6756ba
# ╟─e7a21dbb-e5a9-4eae-a384-3c65198867c9
# ╠═c6702048-1450-11eb-1f1d-a54089545949
# ╠═df4563da-1450-11eb-08a7-25ed365f578c
