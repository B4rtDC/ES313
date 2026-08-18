### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ 61508000-0000-4000-8000-000000000002
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__), ".."))
	Pkg.activate(pwd())
	using BenchmarkTools
	using Random
	using Profile
end

# ╔═╡ 61508000-0000-4000-8000-000000000001
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

# ╔═╡ 61508000-0000-4000-8000-000000000003
md"""
# Performance — Profiling

The companion notebook `PS08-Performance.jl` focused on **benchmarking**: measuring *how long* a function takes and *how much* it allocates. This notebook is about the natural next question — **profiling** — which tells you *where* inside your code that time and memory actually go.

!!! info "Benchmarking vs. profiling"
	- **Benchmarking** answers *"how fast is this function?"* — a single, repeatable number (with `@benchmark`).
	- **Profiling** answers *"which lines are responsible?"* — a breakdown of time (CPU profile) or memory (allocation profile) across your call stack.

	You benchmark to know *whether* something is slow, and you profile to know *why*. In practice you alternate: profile to find the hotspot, change it, benchmark to confirm the gain.

!!! warning "The first run includes compilation"
	Julia compiles a function the first time it is called. That compilation shows up in a profile as one-off frames. Always run a function once (a *warm-up* call) before profiling it, otherwise you are mostly measuring the compiler. (`@benchmark`/`@belapsed` handle this themselves — they compile during tuning and report a distribution over many runs — but `@time` and the profiler do not.)
"""

# ╔═╡ 61508000-0000-4000-8000-000000000004
md"""
## Two ways to profile

Julia ships a profiler in the standard library [`Profile`](https://docs.julialang.org/en/v1/stdlib/Profile/). There are two common front-ends for it.

!!! tip "In VS Code — graphical flame graphs (`@profview`)"
	The Julia VS Code extension injects two macros into the REPL:

	```julia
	@profview        profile_test_bad(10)   # CPU flame graph
	@profview_allocs profile_test_bad(10)   # allocation flame graph
	```

	These open an interactive **flame graph**: wide blocks are where the time/memory goes, and blocks lower in the stack are the functions they call. This is the most convenient tool, but the macros only exist inside the **VS Code REPL** — they are *not* defined in a Pluto session (that is why a `@profview` cell breaks a notebook). The cells below therefore use the standard-library front-end, which runs everywhere.

!!! info "Everywhere — text profiles (`Profile` stdlib)"
	The `Profile` standard library works in any Julia process, including this Pluto notebook:

	```julia
	Profile.@profile f()          # collect CPU samples
	Profile.print(; format=:flat) # print them as a table

	Profile.Allocs.@profile f()   # collect allocation samples
	Profile.Allocs.fetch()        # inspect them
	```

	The two small helpers `cpuprofile` and `allocsummary` defined below wrap exactly this, so every profiling cell in this notebook runs live.

!!! danger "Reading a flame graph / flat profile"
	- **Wide** (many samples / high count) = expensive.
	- Look for hotspots **inside your own functions** first, before blaming library internals.
	- The very first profile may still contain compilation frames — warm up first.
"""

# ╔═╡ 61508000-0000-4000-8000-000000000005
md"""
## Example 1 — an allocation-heavy array workload

`profile_test_bad` is written in a convenient but wasteful way. It is not *wrong*, just expensive, which makes it a good profiling target. On every iteration it:

- `randn(...)` — allocates a fresh `100×100×20` array,
- `mapslices(sum, A; dims=2)` — flexible, but allocates for a simple reduction,
- `A[:, :, 5]` — copies a slice,
- `mapslices(sort, B; dims=1)` — allocates while sorting each column,
- `B .* reshape(b, :, 1)` — allocates a new matrix.

`profile_test_better` computes the **same result** (verified below) but allocates its buffers **once** and reuses them: `randn!`/`rand!` fill in place, `@view` avoids the slice copy, the reductions become explicit loops, and `sort!` sorts in place.

!!! warning "Same work, same numbers"
	Both functions consume random numbers in the same order, so their accumulated totals must match. The warm-up cell asserts this before we trust any profile.
"""

# ╔═╡ 61508000-0000-4000-8000-000000000006
begin
	const PROFILE_ROWS = 100
	const PROFILE_COLS = 100
	const PROFILE_LAYERS = 20

	"""
		profile_test_bad(n; seed=161)

	Convenient but allocation-heavy array workload (the profiling target).
	"""
	function profile_test_bad(n::Int; seed::Int=161)
		rng = MersenneTwister(seed)
		total = 0.0
		for _ in 1:n
			A = randn(rng, PROFILE_ROWS, PROFILE_COLS, PROFILE_LAYERS)
			total += maximum(A)

			Am = mapslices(sum, A; dims=2)
			total += sum(Am)

			B = A[:, :, 5]
			Bsort = mapslices(sort, B; dims=1)

			b = rand(rng, PROFILE_ROWS)
			C = B .* reshape(b, :, 1)

			total += sum(Bsort) + sum(C)
		end
		return total
	end

	"""
		profile_test_better(n; seed=161)

	Same computation as `profile_test_bad`, but buffers are allocated once and
	reused (`randn!`/`rand!`, `@view`, in-place `sort!`, explicit loops).
	"""
	function profile_test_better(n::Int; seed::Int=161)
		rng = MersenneTwister(seed)
		A = Array{Float64}(undef, PROFILE_ROWS, PROFILE_COLS, PROFILE_LAYERS)
		b = Vector{Float64}(undef, PROFILE_ROWS)
		Bsort = Matrix{Float64}(undef, PROFILE_ROWS, PROFILE_COLS)
		C = Matrix{Float64}(undef, PROFILE_ROWS, PROFILE_COLS)
		total = 0.0
		for _ in 1:n
			randn!(rng, A)
			total += maximum(A)

			@inbounds for k in axes(A, 3)
				for i in axes(A, 1)
					rowsum = 0.0
					for j in axes(A, 2)
						rowsum += A[i, j, k]
					end
					total += rowsum
				end
			end

			B = @view A[:, :, 5]
			copyto!(Bsort, B)
			sort!(Bsort; dims=1)

			rand!(rng, b)
			@inbounds for j in axes(B, 2)
				for i in axes(B, 1)
					C[i, j] = B[i, j] * b[i]
				end
			end

			total += sum(Bsort) + sum(C)
		end
		return total
	end

	"""
		compare_profile_examples(n=3)

	Warm-up + correctness check: run both versions once and assert equal totals.
	"""
	function compare_profile_examples(n::Int=3)
		bad = profile_test_bad(n)
		better = profile_test_better(n)
		@assert isapprox(bad, better; rtol=1e-10, atol=1e-8)
		return (; bad, better)
	end
end

# ╔═╡ 61508000-0000-4000-8000-000000000007
# Warm-up / correctness check. Run this before profiling larger calls.
compare_profile_examples(1)

# ╔═╡ 61508000-0000-4000-8000-000000000008
begin
	"""
		cpuprofile(f; nlines=25, mincount=3)

	Run `f()` under the CPU sampler and return the flat profile as text,
	sorted by sample count. Wraps `Profile.@profile` + `Profile.print`.
	"""
	function cpuprofile(f; nlines::Int=25, mincount::Int=3)
		Profile.clear()
		Profile.@profile f()
		io = IOBuffer()
		Profile.print(IOContext(io, :displaysize => (nlines, 120));
					  format=:flat, sortedby=:count, mincount=mincount)
		return Text(String(take!(io)))
	end

	"""
		allocsummary(f)

	Run `f()` under the allocation profiler and return the number of recorded
	allocation events and their total size in bytes.
	"""
	function allocsummary(f)
		Profile.Allocs.clear()
		Profile.Allocs.@profile sample_rate=1.0 f()
		results = Profile.Allocs.fetch()
		return (n_allocations = length(results.allocs),
				total_bytes = sum(a.size for a in results.allocs; init=0))
	end

	nothing
end

# ╔═╡ 61508000-0000-4000-8000-000000000009
md"""
### CPU profile

Run each version under the sampler. In the flat table, **Count** is how many samples landed on that line — the higher, the more time spent there. Compare where the two versions spend their time:

- in `profile_test_bad`, expect `mapslices`, `randn`, sorting and the broadcast to dominate;
- in `profile_test_better`, the same total work is there, but far less of it is allocation and copying overhead.
"""

# ╔═╡ 61508000-0000-4000-8000-000000000010
cpuprofile(() -> profile_test_bad(50))

# ╔═╡ 61508000-0000-4000-8000-000000000011
cpuprofile(() -> profile_test_better(50))

# ╔═╡ 61508000-0000-4000-8000-000000000012
md"""
!!! tip "The VS Code equivalent"
	If you open this material in VS Code instead of Pluto, replace the two cells above with the graphical profiler:

	```julia
	@profview profile_test_bad(50)
	@profview profile_test_better(50)
	```

	You get an interactive flame graph instead of a text table — same data, easier to explore.
"""

# ╔═╡ 61508000-0000-4000-8000-000000000013
md"""
### Allocation profile

CPU profiling answers *"where is time spent?"*. Allocation profiling answers *"where is memory allocated?"*. They are related — allocation is often *why* code is slow — but not identical.

Here we summarise the totals. The contrast between the two versions is the whole lesson: reusing buffers removes almost every allocation from the hot loop.

!!! note "Totals only — not per line"
	`allocsummary` reports aggregate totals (event count + bytes). To attribute allocations to specific *lines*, inspect the stacktraces returned by `Profile.Allocs.fetch()`, or open the graphical `@profview_allocs` flame graph in VS Code (mentioned earlier).
"""

# ╔═╡ 61508000-0000-4000-8000-000000000014
(bad = allocsummary(() -> profile_test_bad(3)),
 better = allocsummary(() -> profile_test_better(3)))

# ╔═╡ 61508000-0000-4000-8000-000000000015
md"""
### Confirm with a benchmark

Profiling pointed at the cause; benchmarking quantifies the effect. Now that both functions are compiled and verified equal, compare them head-to-head. Watch the **allocations** line as much as the time.
"""

# ╔═╡ 61508000-0000-4000-8000-000000000041
md"""
!!! warning "Interpolate globals with `\$`"
	`@benchmark` evaluates its expression in **global** scope. Writing `@benchmark f(events)` with `events` a non-`const` global makes every sample repeat a slow global lookup and dynamic dispatch *on top of* `f`'s real cost — you end up measuring benchmarking overhead, not `f`.

	Splice the **value** in as a local with `\$`: `@benchmark f(\$events)` captures `events` once, so you time `f` alone. Interpolate every runtime variable you pass this way.

	Literal arguments need no `\$` — `@benchmark profile_test_bad(3)` is already fine, because the `3` is baked straight into the expression.
"""

# ╔═╡ 61508000-0000-4000-8000-000000000016
@benchmark profile_test_bad(3)

# ╔═╡ 61508000-0000-4000-8000-000000000017
@benchmark profile_test_better(3)

# ╔═╡ 61508000-0000-4000-8000-000000000018
md"""
## Example 2 — a hidden $\mathcal{O}(n^2)$: the wrong container

Not every performance problem is about allocation. Some are **algorithmic**, and those are exactly the ones profiling is best at exposing.

The task: walk once through a stream of events (think user IDs, tokens, sensor tags) and collect the **distinct** values *in order of first appearance*. The code reads like a single linear pass — one loop over the data — so at a glance it looks like $\mathcal{O}(n)$:

```julia
seen = T[]
for x in xs
    if !(x in seen)      # looks innocent...
        push!(seen, x)
    end
end
```

The trap is `x in seen`. Because `seen` is a **`Vector`**, membership is a *linear scan*: every new element is compared against everything collected so far. One pass over the data, but a full scan hidden inside it — the function is secretly $\mathcal{O}(n^2)$. Reading the code, this is easy to miss. In a profile, it is impossible to miss.
"""

# ╔═╡ 61508000-0000-4000-8000-000000000019
begin
	"""
		first_seen_slow(xs)

	Order-preserving unique. Membership is tested against a `Vector`, so every
	`x in seen` is a linear scan — the single pass is secretly O(n²).
	"""
	function first_seen_slow(xs::AbstractVector{T}) where {T}
		seen = T[]
		for x in xs
			if !(x in seen)
				push!(seen, x)
			end
		end
		return seen
	end

	"""
		first_seen_fast(xs)

	Same result, but membership is tested against a `Set` (O(1) hash lookup),
	so the whole function is O(n). The `Vector` only records the order.
	"""
	function first_seen_fast(xs::AbstractVector{T}) where {T}
		order = T[]
		seen  = Set{T}()
		for x in xs
			if !(x in seen)
				push!(order, x)
				push!(seen, x)
			end
		end
		return order
	end

	"""
		make_events(n_unique, repeats; seed=1)

	A shuffled stream in which each of `n_unique` values occurs `repeats` times.
	"""
	function make_events(n_unique::Int, repeats::Int; seed::Int=1)
		return shuffle!(MersenneTwister(seed), repeat(1:n_unique, repeats))
	end
end

# ╔═╡ 61508000-0000-4000-8000-000000000020
events = make_events(30_000, 2)

# ╔═╡ 61508000-0000-4000-8000-000000000021
# Validity: both agree with each other and with Base `unique`.
first_seen_slow(events) == first_seen_fast(events) == unique(events)

# ╔═╡ 61508000-0000-4000-8000-000000000022
md"""
### Where does the time go?

Profile the slow version. Almost every sample lands on the same handful of frames — the `in` call and the array `iterate`/`getindex` beneath it — all tracing back to the `x in seen` line of `first_seen_slow`. That linear scan *is* the runtime; nothing else registers.
"""

# ╔═╡ 61508000-0000-4000-8000-000000000023
cpuprofile(() -> first_seen_slow(events))

# ╔═╡ 61508000-0000-4000-8000-000000000024
md"""
!!! danger "Diagnosis"
	The profile is dominated by `in` → `iterate` → `getindex`: a linear search through `seen`. The cost is not in reading the data or in `push!` — it is entirely in *re-scanning what we already collected*. An allocation profile would **not** have found this; it is a pure time/complexity issue, and only the CPU profile reveals it.

!!! tip "Fix — change the data structure, not the loop"
	Test membership against a `Set` instead of a `Vector`. Hash lookup is $\mathcal{O}(1)$, so the pass becomes $\mathcal{O}(n)$. The loop is otherwise unchanged — only the container changed. Profiling the fixed version below shows the linear-scan frames gone, replaced by cheap hash lookups (`haskey` / `ht_keyindex`).
"""

# ╔═╡ 61508000-0000-4000-8000-000000000025
# fast is so quick that a single call barely registers — loop it to gather samples.
cpuprofile(() -> for _ in 1:200
	first_seen_fast(events)
end)

# ╔═╡ 61508000-0000-4000-8000-000000000026
md"""
### Was it really algorithmic?

A constant-factor bug (like Example 1) makes everything a fixed multiple slower. An **algorithmic** bug gets *relatively* worse as the input grows. The table below times both versions at increasing sizes: each time the input doubles, the slow version's time roughly **quadruples** (the $\mathcal{O}(n^2)$ signature) while the speedup keeps climbing. That growing speedup is the fingerprint of a complexity fix rather than a micro-optimisation.
"""

# ╔═╡ 61508000-0000-4000-8000-000000000027
let
	sizes = [2_000, 4_000, 8_000, 16_000]
	rows = ["| n\\_unique | events | slow (ms) | fast (ms) | speedup |",
			"|---:|---:|---:|---:|---:|"]
	for nu in sizes
		e  = make_events(nu, 2)
		ts = @belapsed first_seen_slow($e) seconds=0.3
		tf = @belapsed first_seen_fast($e) seconds=0.3
		push!(rows, "| $(nu) | $(length(e)) | $(round(ts*1e3, digits=2)) | " *
					"$(round(tf*1e3, digits=3)) | $(round(Int, ts/tf))× |")
	end
	Markdown.parse(join(rows, "\n"))
end

# ╔═╡ 61508000-0000-4000-8000-000000000028
@benchmark first_seen_slow($events)

# ╔═╡ 61508000-0000-4000-8000-000000000029
@benchmark first_seen_fast($events)

# ╔═╡ 61508000-0000-4000-8000-000000000030
md"""
## Example 3 — a branch that blocks SIMD

Modern CPUs process several array elements per instruction (**SIMD** — *single instruction, multiple data*). Julia's compiler *auto-vectorises* simple numeric loops into these wide instructions — but only when the loop body is straight-line arithmetic. A **data-dependent branch** inside the loop breaks that: the compiler can no longer apply one instruction to a whole lane of elements, so the loop falls back to slow, one-element-at-a-time scalar code.

Take summing only the positive elements of an array. The natural version uses a branch:

```julia
s = 0.0
for i in eachindex(x)
    if x[i] > 0      # data-dependent branch → blocks vectorisation
        s += x[i]
    end
end
```

The branchless equivalent replaces the `if` with a *masked* select (`ifelse`), which is straight-line and therefore vectorisable. We compare three versions:

1. `possum_branch` — scalar loop with the branch;
2. `possum_simd_branch` — the same body, but annotated `@simd`;
3. `possum_simd_mask` — branchless (`ifelse`) **and** `@simd`.

!!! warning "Why `@simd` alone is not enough"
	`@simd` gives the compiler permission to re-associate the floating-point `+` reduction (normally forbidden, since FP addition is not associative). That permission is *necessary* to vectorise a sum — but not *sufficient*: with the branch still in the body, `@simd` changes nothing.
"""

# ╔═╡ 61508000-0000-4000-8000-000000000031
begin
	"""
		possum_branch(x)

	Sum of positive elements — scalar loop with a data-dependent branch.
	"""
	function possum_branch(x::Vector{Float64})
		s = 0.0
		@inbounds for i in eachindex(x)
			if x[i] > 0
				s += x[i]
			end
		end
		return s
	end

	"""
		possum_simd_branch(x)

	Same body, annotated `@simd`. The branch still blocks vectorisation.
	"""
	function possum_simd_branch(x::Vector{Float64})
		s = 0.0
		@inbounds @simd for i in eachindex(x)
			if x[i] > 0
				s += x[i]
			end
		end
		return s
	end

	"""
		possum_simd_mask(x)

	Branchless: the `if` becomes a masked `ifelse`, which vectorises under `@simd`.
	"""
	function possum_simd_mask(x::Vector{Float64})
		s = 0.0
		@inbounds @simd for i in eachindex(x)
			s += ifelse(x[i] > 0, x[i], 0.0)
		end
		return s
	end
end

# ╔═╡ 61508000-0000-4000-8000-000000000032
xs_simd = randn(MersenneTwister(1), 1_000_000)

# ╔═╡ 61508000-0000-4000-8000-000000000033
# All three compute the same sum (up to FP reordering under @simd).
possum_branch(xs_simd) ≈ possum_simd_branch(xs_simd) ≈ possum_simd_mask(xs_simd)

# ╔═╡ 61508000-0000-4000-8000-000000000034
md"""
### Benchmark — the branch causes a large slowdown (hardware-dependent factor)

Watch the middle row: adding `@simd` to the branchy loop changes **nothing** — the branch prevents vectorisation regardless. Only removing the branch (`ifelse`) lets the loop vectorise, and it then runs faster by a factor set by the CPU's SIMD width for `Float64` — roughly **2×** on Apple-Silicon NEON, and more on wide-AVX x86.
"""

# ╔═╡ 61508000-0000-4000-8000-000000000035
let
	cases = [("scalar branch", possum_branch),
			 ("`@simd` + branch", possum_simd_branch),
			 ("`@simd` + `ifelse` (branchless)", possum_simd_mask)]
	rows = ["| version | time (µs) | vs. scalar |", "|:--|--:|--:|"]
	base = 0.0
	for (k, (name, f)) in enumerate(cases)
		t = @belapsed $f($xs_simd) seconds=0.3
		k == 1 && (base = t)
		push!(rows, "| $(name) | $(round(t*1e6, digits=1)) | $(round(base/t, digits=2))× |")
	end
	Markdown.parse(join(rows, "\n"))
end

# ╔═╡ 61508000-0000-4000-8000-000000000036
md"""
### Can the profiler see it?

Only halfway. Profile the branchy version: the sampler correctly points at the loop as *the* hotspot — that is the *where*. But every version's loop looks the same to a sampling profiler; it counts *time*, not *instructions*, so it cannot tell you that the slow one skipped SIMD. For the *why*, ask the compiler directly with `@code_llvm` / `@code_native`.
"""

# ╔═╡ 61508000-0000-4000-8000-000000000037
# Accumulate the result — otherwise the compiler drops the side-effect-free calls
# (dead-code elimination) and the profiler collects no samples.
cpuprofile() do
	acc = 0.0
	for _ in 1:300
		acc += possum_branch(xs_simd)
	end
	acc
end

# ╔═╡ 61508000-0000-4000-8000-000000000038
md"""
### Confirm the cause with `@code_llvm`

`@code_llvm f(x)` prints the LLVM IR the compiler produced. We do not have to read all of it — just check whether it contains **packed** operations on `double`s (e.g. `<2 x double>`, two `Float64`s handled per instruction). The helper below reports exactly that for each version: only the branchless one is vectorised.
"""

# ╔═╡ 61508000-0000-4000-8000-000000000039
begin
	"""
		simd_report(f, types=(Vector{Float64},))

	Inspect the optimised LLVM IR of `f` and report whether it contains packed
	`double` (SIMD) operations, and at which widths.
	"""
	function simd_report(f, types=(Vector{Float64},))
		io = IOBuffer()
		code_llvm(io, f, types; optimize=true, debuginfo=:none)
		ir = String(take!(io))
		widths = unique([m.match for m in eachmatch(r"<\d+ x double>", ir)])
		return (; vectorized = !isempty(widths), widths)
	end

	(scalar_branch = simd_report(possum_branch),
	 simd_branch   = simd_report(possum_simd_branch),
	 simd_ifelse   = simd_report(possum_simd_mask))
end

# ╔═╡ 61508000-0000-4000-8000-000000000040
md"""
!!! tip "Takeaway"
	- A **data-dependent branch** in a hot numeric loop blocks auto-vectorisation, and `@simd` cannot rescue it while the branch remains.
	- Rewrite the branch as **branchless arithmetic** — `ifelse`, `min`/`max`, `clamp`, or multiplication by a boolean mask — so the body is straight-line and vectorises.
	- The **profiler** tells you *which* loop is hot; **`@code_llvm` / `@code_native`** tell you *whether it vectorised*. Profiling narrows the search; the code introspection macros close the case.
"""

# ╔═╡ 61508000-0000-4000-8000-000000000042
md"""
## Bonus — `@code_warntype`: catching type instability

Examples 1–3 leaned on the profilers and `@code_llvm`. The `@code_*` family has a third everyday member: **`@code_warntype`**. It prints the type the compiler inferred for every variable and for the return value; anything it could *not* pin down is highlighted in **red** as `::Any` or `::Union{...}`.

Those red annotations flag **type instability** — a value whose type the compiler cannot predict — which is the single most common Julia performance bug. Unstable code forces the runtime to box values and dispatch dynamically on every operation, defeating the compiler. The CPU profiler only sees this *indirectly*, as time spent in dynamic-dispatch frames; `@code_warntype` names the culprit directly.

The classic mistake is seeding an accumulator with the wrong type: `s = 0` (an `Int`) that then accumulates `Float64`s. The fix is to seed it from the data — `s = zero(eltype(xs))`. Run the cell below and compare the two `@code_warntype` outputs (they print to the terminal / captured output).
"""

# ╔═╡ 61508000-0000-4000-8000-000000000043
begin
	"""
		unstable_sum(xs)

	`s` starts as an `Int` (`0`) but accumulates `Float64`s, so its inferred type
	widens to a `Union` — the red `::Union{...}` you see in `@code_warntype`.
	"""
	function unstable_sum(xs)
		s = 0
		for x in xs
			s += x
		end
		return s
	end

	"""
		stable_sum(xs)

	`s` is seeded with `zero(eltype(xs))`, so it keeps the element type throughout
	and `@code_warntype` reports only concrete types.
	"""
	function stable_sum(xs)
		s = zero(eltype(xs))
		for x in xs
			s += x
		end
		return s
	end

	# Compare the two — the first shows red ::Union{...}, the second stays concrete:
	@code_warntype unstable_sum(Float64[1, 2, 3, 4, 5])
end

# ╔═╡ 61508000-0000-4000-8000-000000000044
md"""
!!! tip "Diagnostic workflow: symptom → tool → fix"
	1. **Benchmark first** (`@benchmark`) to confirm there really is a problem and to get a baseline number to beat.
	2. **Allocations dominate** (large `memory estimate` / high alloc count) → read the **allocation profile** or the `@benchmark` memory line → **reuse buffers** and work in place. *(Example 1)*
	3. **Time concentrates in one hot line and grows super-linearly** as the input doubles → **CPU profile** to find it → fix the **algorithm / container** (e.g. `Vector` → `Set`). *(Example 2)*
	4. **A tight numeric loop is slow but scales linearly (flat)** → inspect with **`@code_llvm`** / **`@code_warntype`** → **remove data-dependent branches** and **fix type instability**. *(Example 3)*

	Then benchmark again to confirm the gain. Profiling finds the cause, benchmarking proves the cure.
"""

# ╔═╡ Cell order:
# ╟─61508000-0000-4000-8000-000000000001
# ╟─61508000-0000-4000-8000-000000000002
# ╟─61508000-0000-4000-8000-000000000003
# ╟─61508000-0000-4000-8000-000000000004
# ╟─61508000-0000-4000-8000-000000000005
# ╠═61508000-0000-4000-8000-000000000006
# ╠═61508000-0000-4000-8000-000000000007
# ╠═61508000-0000-4000-8000-000000000008
# ╟─61508000-0000-4000-8000-000000000009
# ╠═61508000-0000-4000-8000-000000000010
# ╠═61508000-0000-4000-8000-000000000011
# ╟─61508000-0000-4000-8000-000000000012
# ╟─61508000-0000-4000-8000-000000000013
# ╠═61508000-0000-4000-8000-000000000014
# ╟─61508000-0000-4000-8000-000000000015
# ╟─61508000-0000-4000-8000-000000000041
# ╠═61508000-0000-4000-8000-000000000016
# ╠═61508000-0000-4000-8000-000000000017
# ╟─61508000-0000-4000-8000-000000000018
# ╠═61508000-0000-4000-8000-000000000019
# ╠═61508000-0000-4000-8000-000000000020
# ╠═61508000-0000-4000-8000-000000000021
# ╟─61508000-0000-4000-8000-000000000022
# ╠═61508000-0000-4000-8000-000000000023
# ╟─61508000-0000-4000-8000-000000000024
# ╠═61508000-0000-4000-8000-000000000025
# ╟─61508000-0000-4000-8000-000000000026
# ╠═61508000-0000-4000-8000-000000000027
# ╠═61508000-0000-4000-8000-000000000028
# ╠═61508000-0000-4000-8000-000000000029
# ╟─61508000-0000-4000-8000-000000000030
# ╠═61508000-0000-4000-8000-000000000031
# ╠═61508000-0000-4000-8000-000000000032
# ╠═61508000-0000-4000-8000-000000000033
# ╟─61508000-0000-4000-8000-000000000034
# ╠═61508000-0000-4000-8000-000000000035
# ╟─61508000-0000-4000-8000-000000000036
# ╠═61508000-0000-4000-8000-000000000037
# ╟─61508000-0000-4000-8000-000000000038
# ╠═61508000-0000-4000-8000-000000000039
# ╟─61508000-0000-4000-8000-000000000040
# ╟─61508000-0000-4000-8000-000000000042
# ╠═61508000-0000-4000-8000-000000000043
# ╟─61508000-0000-4000-8000-000000000044
