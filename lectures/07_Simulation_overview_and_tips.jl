### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ af43ec68-24a5-11ef-395c-f52d0ef97f09
begin
	# Pkg needs to be used to force Pluto to use the current project instead of making an environment for each notebook
	using Pkg
	# this is redundant if you run it through start.jl, but to make sure...
	course_root = normpath(joinpath(dirname(@__FILE__), ".."))
	cd(course_root)
    Pkg.activate(pwd())

	# the source file
	des_support_file = joinpath(course_root, "lectures", "DES_spt.jl")
	include(des_support_file)
	txt = readlines(des_support_file)
	
	# helper function to find code for a function in the spt file
	function function_source_extractor(src, target)
		start_idx = findfirst(x -> occursin("function $(target)", x), src)
	
		end_idx = findfirst( x -> startswith(x, "end"), @view src[start_idx:end])
	
		#return join(src[start_idx:start_idx+end_idx-1], "\n")
		return join(["```julia", src[start_idx:start_idx+end_idx-1]..., "```"], "\n")
	end

	
	import PlutoUI: TableOfContents, LocalResource
	TableOfContents(depth=4)
end

# ╔═╡ bad420d3-8971-4b03-816d-8be354f5009d
# dependencies
begin
	using ResumableFunctions
	using ConcurrentSim
	using Logging

	using BenchmarkTools
	using Distributions
	using Plots
	using Random
	using Statistics
	using StatsPlots
	using LaTeXStrings
	using DataFrames
	using Measures            # For fine-grained plot control 
end

# ╔═╡ 3ffef524-2386-4010-878c-c11c7e0515a8
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

# ╔═╡ dfe045a5-b5a4-4b98-aad8-668d2fd77c1e
begin
	OVERVIEW_SEED = 307
	RUN_BENCHMARKS = false
	overview_rng(seed::Integer=OVERVIEW_SEED) = MersenneTwister(seed)

	function mean_ci(values; z=1.96)
		n = length(values)
		μ̂ = mean(values)
		se = n > 1 ? std(values) / sqrt(n) : 0.0
		return (mean=μ̂, se=se, lower=μ̂ - z * se, upper=μ̂ + z * se)
	end
end

# ╔═╡ 1f9f0785-abc5-406e-a517-32c218904e4c
md"""
# Simulation overview
In this last chapter, we will tackle the specific problem of queueing systems and approach it from different angles. Additionally, we'll discuss important factors to consider when developing and implementing simulations. 

The queuing theory part is inspired by:

*Shortle, J. F., Thompson, J. M., Gross, D., Harris, C. M. (2018). Fundamentals of Queueing Theory. Germany: Wiley.*

## General queuing systems
A general queuing system is depicted on the image below

$(LocalResource("./lectures/img/queueing_system.png", :width=>750))

We can identify the following components:
- "customer" arrivals
- a service facility comprised of:
  - a queue for the "customers"
  - different servers
- "customers" leaving

We can also observe different possible transitions, indicated by the arrows."""

# ╔═╡ ee7affdb-177e-4da9-abe5-fd7f23820ece
md"""

### Descriptors
In general, we can describe a queuing system by a set of metrics:

| Symbol            | Interpretation                                      |
|-------------------|-----------------------------------------------------|
| ``\lambda``       | Average arrival rate                                 |
| ``S``             | Random service time                                  |
| ``\mu \equiv 1/E[S]`` | Average service rate                           |
| ``c``             | Number of servers                                    |
| ``r \equiv \lambda/\mu`` | Offered load                                |
| ``\rho \equiv \lambda/c\mu`` | Traffic intensity or utilization        |
| ``T, T_q``        | Random time a customer spends in the system / queue  |
| ``W, W_q``        | Average time a customer spends in the system / queue |
| ``N, N_q``        | Random number of customers in the system / queue     |
| ``L, L_q``        | Average number of customers in the system / queue    |
| ``A^{(n)}``       | Arrival time customer ``n``         			   |
| ``D^{(n)}``       | Departure time customer ``n``  			           |
| ``P_{n}``       | Probability of ``n`` customers in the system          |






### Interest
Queuing models find applications in various fields, including:

* Telecommunications: Modeling call centers, network traffic, and server systems.
* Manufacturing: Analyzing production lines and inventory systems.
* Transportation: Studying traffic flow and congestion.
* Computer Science: Modeling computer systems and network performance.


Generally there are three types of system responses of interest: 
1. Some measure of the waiting time that a typical customer might endure.
2. Some measure of the number of customers that may accumulate in the queue or system. 
3. A measure of the idle time of the servers. 

Since most queueing systems have stochastic elements, these measures are often random variables, so their probability distributions – or at least their expected values – are sought.

The task of the queuing analyst is generally one of two things:
1. Determine some measures of effectiveness for a given process: here one must determine waiting delays and queue lengths from the given properties of the input stream and the service procedures
2. to design an “optimal” system according to some criterion: here one might want to balance customer-waiting time against the idle time of servers according to some cost structure. If the costs of waiting and idle service can be obtained directly, they can be used to determine the optimum number of servers. To design the waiting facility, it is necessary to have information regarding the possible size of the queue. There may also be a space cost that should be considered along with customer-waiting and idle-server costs to obtain the optimal system design. 

In any case, the analyst can first try to solve this problem by analytical means; if these fail, he or she may use simulation. Ultimately, the issue generally comes down to a trade-off between better customer service and the expense of providing more service capability, that is, determining the increase in investment of service for a corresponding decrease in customer delay.
"""

# ╔═╡ 256512c8-6b13-48fb-a5eb-9aefb241ce3a
md"""
### Little's law
Little's Law is a fundamental theorem in queueing theory that relates the average number of customers in a system to the average arrival rate and the average time a customer spends in the system.

The general form of Little's law is 
```math
\mathbb E\left[L\right]=\lambda\mathbb E\left[W\right]
```

with
* ``\mathbb E\left[L\right]``: expected number of customers in the system (both in the queue and being served).
*  ``\lambda``: average arrival rate of customers to the system.
* ``E\left[W\right]`` :  expected time a customer spends in the system.


There is also a specific form of Little's Law that applies just to the queue, rather than the entire system. This form relates the average number of customers in the queue to the average arrival rate and the average time a customer spends waiting in the queue:

```math
\mathbb E\left[L_Q\right]=\lambda\mathbb E\left[W_Q\right]
```

with
* ``\mathbb E\left[L_{Q}\right]``: expected number of customers in the queue.
*  ``\lambda``: average arrival rate of customers to the system.
* ``E\left[W_{Q}\right]`` : expected time a customer spends in the queue.

"""

# ╔═╡ 078324c1-128e-4805-813f-4da02b967d61
md"""
### Steady state probabilities
In the context of queueing theory, the steady state probabilities refer to the long-term probabilities of being in a particular state (e.g., having a certain number of customers in the system) once the system has reached equilibrium.

```math
P_n=\lim_{t\rightarrow\infty}\mathbb P\left\{L(t)=n\right\}
```

where
* ``P_n`` represents the steady state probability of having ``n`` customers in the system.
* ``\lim_{t\rightarrow\infty}\mathbb P\left\{L(t)=n\right\}`` is the probability that the number of customers ``L(t)`` in the system is ``n`` as time ``t`` approaches infinity.
"""

# ╔═╡ 3e361b9a-2ef9-46f1-8e64-127f0a53af42
md"""
### Stability
In queueing theory, stability is an important concept. A queueing system is stable if the service capacity is large enough that the number of customers in the system does not grow without bound. For an M/M/1 queue this means:
```math
\rho = \frac{\lambda}{\mu} < 1.
```
For ``c`` identical parallel servers this becomes ``\rho = \lambda/(c\mu) < 1``. In steady state, the long-run average departure rate equals the long-run average arrival rate, but that balance is a consequence of stability rather than the stability condition itself.

"""

# ╔═╡ 49b288bf-b0a2-4e29-bfc0-779bd80c0bc2
md"""
### Poisson Arrivals See Time Averages (PASTA)

The PASTA property is an important result in queueing theory which states that for a system with Poisson arrivals, the probability of an arrival seeing a particular state of the system is equal to the long-term time-average probability of the system being in that state:
```math
P\{L(A^-)=n\}=P_n
```

This equation says that arrivals "see" the same state distribution as an observer who samples the system at a random time. The property depends on the arrival process being Poisson; it does not generally hold for scheduled or state-dependent arrivals.
"""

# ╔═╡ 2e5e85ed-2234-48ee-a73d-33d73d06112a
md"""
## The M/M/1 queuing system

The M/M/1 queue is a fundamental model in queueing theory. The name of this model stems from its characteristics:

* M (Markovian arrival process): Customers arrive at the queue according to a Poisson process, meaning arrivals occur randomly and independently at a constant average rate (λ).
* M (Markovian service times): The service time for each customer follows an exponential distribution, meaning service times vary randomly but have a constant average rate (μ).
* 1 (Single server): There is only one server available to serve customers in the queue.

The figure below shows an illustration of such a queue: 

$(LocalResource("./lectures/img/MM1_queue.png"))

There are some assumptions associated with this model:
1. Infinite Capacity: The queue can hold an unlimited number of customers.
2. First-Come, First-Served (FCFS): Customers are served in the order they arrive.
3. Steady State: The system has reached a stable state where the arrival rate and service rate are constant over time.

While the M/M/1 model is a valuable tool, it has some limitations:
* Assumptions: The assumptions of Poisson arrivals and exponential service times may not always hold in real-world scenarios.
* Single Server: It only applies to systems with a single server. More complex models are needed for systems with multiple servers.

### Descriptives
It can be shown that the M/M/1 queueing model has the following properties when ``\lambda < \mu``:

| Metric                | Value             |
|------------------------------------------------------------------|----------------------------------------|
| ``\rho`` (utilization)                                           | `` \frac{\lambda}{\mu}`` |
| ``P_0`` (steady state probability for zero customers)            | ``1 - \frac{\lambda}{\mu}``                       |
| ``P_n`` (steady state probability for ``n`` customers)           | ``\left(1 - \frac{\lambda}{\mu}\right)\left(\frac{\lambda}{\mu}\right)^n \; (\forall n>0)`` |
| ``\mathbb{E}[L]`` (Expected number of customers in the system)   | ``\frac{\lambda}{\mu - \lambda}`` |
| ``\mathbb{E}[W]`` (Expected time a customer spends in the system)   | ``\frac{1}{\mu - \lambda}`` |
| ``\mathbb{E}[W_Q]`` (Expected time a customer spends waiting in the queue)   | ``\frac{\lambda}{\mu}\frac{1}{\mu - \lambda}`` |
| ``\mathbb{E}[L_Q]`` (Expected number of customers in the queue)   | ``\frac{\lambda^2}{\mu}\frac{1}{\mu - \lambda}`` |


"""

# ╔═╡ e3f8cfb6-f285-45f0-a551-6412e3b2f35c
md"""
### Simulation
A MM1 queuing system will be used to illustrate the three main simulation methodologies:
- time-stepping
- discrete-events processing
- process-driven simulation
"""

# ╔═╡ 98c7d5e9-0476-48f0-8dfc-21de440018b1
begin
	λ = 1.0
	μ = 2.0
end;

# ╔═╡ 7431f6ed-f69a-43ca-9200-0c4304357d7f
md"""
#### Time-stepping
A small value for the time increment ``\Delta t`` is chosen and every tick of the clock a function that mimics our queuing system is run.

For sufficiently small ``\Delta t``, we can approximate the event probabilities by ``P(\text{arrival})\approx\lambda\Delta t`` and ``P(\text{departure})\approx\mu\Delta t``. This is only an approximation: if ``\Delta t`` is too large, multiple arrivals or services can occur inside one tick, but the model below can record at most one of each.
"""

# ╔═╡ d1afab78-ed9f-401b-81ed-3a4131d619d1
Δt = 0.1

# ╔═╡ 1df06a1b-373f-4c47-a0a0-aa076905bafc
begin
	function time_step(rng::AbstractRNG, nr_in_system::Int)
	    if nr_in_system > 0
	        if rand(rng) < μ*Δt
	            nr_in_system -= 1
	        end
	    end
	    if rand(rng) < λ*Δt
	        nr_in_system += 1
	    end
	    nr_in_system
	end
	
	time_step(nr_in_system::Int) = time_step(Random.default_rng(), nr_in_system)
end

# ╔═╡ aa80bf93-fefe-4b80-87fa-a9cdc22b9778
let output = Int[], t = 0.0, tmax=10, rng = overview_rng(1_001)
	push!(output, 0)
	while t < tmax
		t += Δt
		result = time_step(rng, output[end])
		push!(output, result)
	end
	plot(range(0, tmax+Δt, step=Δt), output, line=:steppost, label="", xlabel="t", ylabel="N", marker=:cross, markeralpha=0.5)
end

# ╔═╡ 2d35b0cd-2820-4e85-b090-bb83e4e082af
md"""
We can make the following observations:
* This approach is very easy to implement for simple queuing systems, but becomes cumbersome if the system gets more complex (e.g. larger number of queues, additional interactions, other distributions, ...)
* When are we in steady-state? 
* How many samples of the system in steady-state are needed, to produce a useful average?
* How many runs do we need to quantify the variation around the average?

"""

# ╔═╡ 86d8fd3f-c588-4205-ab85-c19a131640b4
md"""
#### Discrete-event processing
Looking at the output of the time-stepping procedure, we can observe for a lot of the time-steps the state of our system (i.e. the number of clients in the system) does not change. So the procedure does a lot of processing for nothing.

To be more efficient, we can predict
- the next arrival of a client by sampling an exponential distribution with mean ``\frac{1}{\lambda}`` (i.e. rate ``\lambda``);
- the service time of a client by sampling an exponential distribution with mean ``\frac{1}{\mu}`` (i.e. rate ``\mu``).


Only during an arrival of a client or an end of service of a client, the state of the systems changes.
"""

# ╔═╡ dcee2831-3f71-4ea0-a124-401a4a93452e
begin
	interarrival_distribution = Exponential(1/λ)
	service_distribution = Exponential(1/μ)
end;

# ╔═╡ 07520778-2231-46d1-99a8-7db44b7491c4
function service(ev::AbstractEvent, times::Vector{Float64}, output::Vector{Int}, rng::AbstractRNG)
    sim = environment(ev)
    time = now(sim)
    push!(times, time)
    push!(output, output[end]-1)
    if output[end] > 0
        service_delay = rand(rng, service_distribution)
        @callback service(timeout(sim, service_delay), times, output, rng)
    end
end

# ╔═╡ b97beac5-fdf8-484a-89fc-f7421b6e9bd1
function arrival(ev::AbstractEvent, times::Vector{Float64}, output::Vector{Int}, rng::AbstractRNG)
    sim = environment(ev)
    time = now(sim)
    push!(times, time)
    push!(output, output[end]+1)
    if output[end] == 1
        service_delay = rand(rng, service_distribution)
        @callback service(timeout(sim, service_delay), times, output, rng)
    end
    next_arrival_delay = rand(rng, interarrival_distribution)
    @callback arrival(timeout(sim, next_arrival_delay), times, output, rng)
end

# ╔═╡ e4db485f-ef16-4d73-9787-7e89c9b056f7
let times = Float64[0.0], output = Int[0], sim = Simulation(), rng = overview_rng(2_001)
	next_arrival_delay = rand(rng, interarrival_distribution)
	@callback arrival(timeout(sim, next_arrival_delay), times, output, rng)
	run(sim, 10.0)
	plot(times, output, line=:steppost, label="", xlabel="t", ylabel="N", marker=:circle, markeralpha=0.8, markerfill=:lightblue)
end

# ╔═╡ d9d29b25-ab6e-4425-8f90-4901ddd9f763
md"""
We can make the following observations:
- Two callback functions describe completely what happens during the execution of an event.
- For complicated systems (network of queues, clients with priorities, other scheduling methods) working directly with discrete events in this way can result in spaghetti code.
- Code reuse is very limited. A lot of very different application domains can be modeled in a similar way.
"""

# ╔═╡ d2cb1cbb-cd2b-463d-8a39-376874c0d3d8
md"""#### Process-driven discrete-event simulation
We now come to the final approach, where we use process-driven discrete-event simulation. The advantage of this approach is that events and their callbacks are abstracted and the simulation creator only has to program the logic of the system. A process function describes what a specific entity (also called agent) is doing.

We can use `ConcurrentSim` to build a simulation of our M/M/1 system.

Generation process:
$(Markdown.parse(function_source_extractor(txt, "packet_generator(")))

Life cycle of a packet:
$(Markdown.parse(function_source_extractor(txt, "packet(")))

A single simulation:
$(Markdown.parse(function_source_extractor(txt, "MM1_queue_simulation")))
"""

# ╔═╡ fda9c83a-4c19-4cb2-9dfe-1760f287952d
MM1_queue_simulation(interarrival_distribution, service_distribution, 10; rng=overview_rng(3_001))

# ╔═╡ 70143d09-77ec-4bd5-b621-ec638fbfb000
let
	t,n,_ = MM1_queue_simulation(interarrival_distribution, service_distribution, 10; rng=overview_rng(3_002))
	plot(t, n, line=:steppost, label="", xlabel="t", ylabel="N", marker=:circle, markeralpha=0.8, markerfill=:lightblue)
end

# ╔═╡ 5500645f-67f0-486d-834b-a6aebbf74880
md"""
#### Monte Carlo approach
We now have an efficient method to obtain data from a single simulation. We can proceed to a Monte Carlo approach for a more robust analysis of the system.
"""

# ╔═╡ 9b3ec442-df47-4dce-8dc0-373d8737252b
begin
	RUNS = 30
	DURATION = 1000.0
end;

# ╔═╡ 5b9c83fd-8031-450a-8217-d8c6d1f884a6
md"""
We can try to retrieve the analytical descriptors using simulation

##### Estimating ``P_n``


**Note:** each state's probability must be weighted by the total time the system spends in that state (a time average), not by how many times the state is visited.
"""

# ╔═╡ bfd5a133-004d-4889-b541-f40e05b51e54
let
	N = range(0, 10)
	probmatrix = zeros(RUNS, maximum(N)+1)

	# First plot - overlap of the simulations
	P1 = plot([], [], label="Simulations", color=:red, alpha=0.2)
	
	for i in 1:RUNS
		Pₙ = Dict{Int, Float64}()
		times, clients, _ = MM1_queue_simulation(interarrival_distribution, service_distribution, DURATION; rng=overview_rng(4_000 + i))
		for (i,t) in enumerate(times[1:length(times)-1])
			duration = times[i+1] - t
			Pₙ[clients[i]] = get(Pₙ, clients[i],0) + duration	
		end
		Pₙ_sim = [get(Pₙ,n, 0) for n in N] ./ sum(values(Pₙ))

		# assign probability matrix
		for n in N
			probmatrix[i, n+1] = Pₙ_sim[n+1]
		end

		plot!(P1,N, Pₙ_sim, label="", color=:red, alpha=0.25)
	end
	
	
	Pₙ_th = [(1 - λ / μ) * (λ / μ)^n for n in N]
	plot!(P1,N, Pₙ_th, label="Theoretical",linestyle=:dash)
	plot!(P1,xlabel=L"n", ylabel=L"P_n", xticks=0:maximum(N), xlims=(0,maximum(N)), ylims=(0, 0.6), size=(300, 300), title="Individual simulations", titlefontsize=12)

	# boxplot of the simulations
	P2 = boxplot(N', probmatrix, color=:blue, label="", alpha=0.2)
	boxplot!([],[], color=:blue, label="Distribution", alpha=0.2)
	scatter!(P2, N, Pₙ_th, label="Theoretical",  color=:black, marker=:x)
	plot!(P2,xlabel=L"n", ylabel=L"\hat{P}_n", xticks=0:maximum(N), xlims=(-0.5,maximum(N)+0.5), ylims=(0, 0.6), size=(300, 300), title="Estimator distribution", titlefontsize=12)
	# combined plot
	subplots = plot(P1, P2, size=(800, 400))
	global_title = plot(title="M/M/1 - Simulation vs Theory", grid=false, showaxis=false, ticks=false, bottom_margin = -30Plots.px)
	plot(global_title, subplots, layout=@layout([A{0.01h}; B]), left_margin=15Plots.px, bottom_margin=2mm)
end

# ╔═╡ 8e02afc1-1471-4d03-9a37-2d82526e0e80
md"""
##### Estimating ``\mathbb{E}[W_Q]``
To get an estimate of the mean time spent waiting, we need to retrieve this information from our simulation.
"""

# ╔═╡ af159f28-a476-402f-9f96-123b2cbf5f8f
let
	waitmeans = Float64[]
	for i in 1:RUNS
		_,_,wait = MM1_queue_simulation(interarrival_distribution, service_distribution, DURATION; rng=overview_rng(5_000 + i))
		push!(waitmeans, mean(wait))
	end

	boxplot(waitmeans, fill=0.5, label="")
	scatter!([1], [λ / (μ * (μ - λ))], marker=:x, color=:black, label="Theoretical")
	plot!(xticks=false, xlims=(0,2), xlabel="", ylabel=L"\mathbb{E}[W_Q]", ylims=(0.2, 1.0), title="Mean waiting time distribution", size=(400, 400))
end

# ╔═╡ 0eaac249-2020-4264-a8d2-1a68eb1fe4dc
md"""
!!! info "Verification vs. validation"
	The boxplots above overlay the simulated descriptors (``\hat{P}_n``, ``\mathbb{E}[W_Q]``, and later ``\mathbb{E}[L]``) on their analytical M/M/1 values. Reproducing those curves is a **verification** check: it is evidence that our code implements the *intended* model correctly — the arrival and service streams, the single-server FCFS logic and the trace bookkeeping all behave as the M/M/1 equations predict.

	It is **not** a **validation** of the model. Validation asks whether M/M/1 is the *right* model for the real system under study. That requires confronting the simulation with real-world data and checking whether its assumptions — Poisson arrivals, exponential service times, FCFS discipline, a single server and an infinite waiting room — actually hold for that system. A simulation can agree perfectly with theory and still be the wrong model for the problem at hand.

	In the language of the M&S pipeline: matching the analytical descriptors answers *"did we build the model right?"* (verification), not *"did we build the right model?"* (validation).
"""

# ╔═╡ 3ddd4941-a578-4c1d-b42a-ed1e47e85f39
md"""
## Performance insight: making the M/M/1 simulation cheaper

The process-driven simulation above is already much better than stepping through every small time interval. Still, the way we collect and process data can dominate runtime when we repeat the simulation many times.

We will keep the same model and improve only the implementation details:
1. keep the original trace and analyse it afterwards;
2. use a local random-number generator and size hints for trace storage;
3. compute summary statistics online instead of storing every event;
4. preallocate many independent runs and dispatch them across threads.
"""

# ╔═╡ a874701c-f450-4016-bc37-46c7b7554dd0
struct MM1Summary
	mean_wait::Float64
	time_average_n::Float64
	service_starts::Int
	completed::Int
	max_n::Int
end

# ╔═╡ 15e9aff1-695e-4178-885a-3306d0367ed2
function summarize_trace(times::Vector{Float64}, output::Vector{Int}, wait_times::Vector{Float64}, max_time::Real)
	t_end = Float64(max_time)
	area_n = 0.0
	for i in 1:(length(times)-1)
		area_n += output[i] * (times[i+1] - times[i])
	end
	area_n += output[end] * max(t_end - times[end], 0.0)

	mean_wait = isempty(wait_times) ? NaN : mean(wait_times)
	completed = count(i -> output[i+1] < output[i], 1:(length(output)-1))
	return MM1Summary(mean_wait, area_n / t_end, length(wait_times), completed, maximum(output))
end

# ╔═╡ be35839a-c05f-4f4e-ab6b-fbe1f28b68d1
function MM1_trace_summary(interarrival_distribution::UnivariateDistribution, service_distribution::UnivariateDistribution, max_time::Real; seed::Int=7_000)
	times, output, wait_times = MM1_queue_simulation(interarrival_distribution, service_distribution, max_time; rng=overview_rng(seed))
	return summarize_trace(times, output, wait_times, max_time)
end

# ╔═╡ 19bdb483-7f93-4632-b94e-580886d2ced5
md"""
### Trace variant with local randomness and storage hints

The original version uses the global random-number generator and lets arrays grow as needed. For one small run that is perfectly fine. For thousands of replications it is better to make random streams explicit and give trace arrays a reasonable initial capacity.
"""

# ╔═╡ 8cb648c4-07a5-4746-999a-cd6140cb83b6
begin
	@resumable function packet_generator_trace!(sim::Simulation,
			rng::Random.AbstractRNG,
			interarrival_distribution::UnivariateDistribution,
			service_distribution::UnivariateDistribution,
			times::Vector{Float64},
			output::Vector{Int},
			wait_times::Vector{Float64})
		line = Resource(sim, 1)
		while true
			next_arrival_delay = rand(rng, interarrival_distribution)
			@yield timeout(sim, next_arrival_delay)
			@process packet_trace!(sim, rng, service_distribution, line, times, output, wait_times)
		end
	end

	@resumable function packet_trace!(sim::Simulation,
			rng::Random.AbstractRNG,
			service_distribution::UnivariateDistribution,
			line::Resource,
			times::Vector{Float64},
			output::Vector{Int},
			wait_times::Vector{Float64})
		time_in = now(sim)
		push!(times, time_in)
		push!(output, output[end] + 1)
		@yield request(line)
		push!(wait_times, now(sim) - time_in)
		@yield timeout(sim, rand(rng, service_distribution))
		push!(times, now(sim))
		push!(output, output[end] - 1)
		@yield release(line)
	end

	function MM1_queue_simulation_trace(interarrival_distribution::UnivariateDistribution,
			service_distribution::UnivariateDistribution,
			max_time::Real; seed::Int=7_000, max_events_hint::Int=10_000)
		sim = Simulation()
		rng = overview_rng(seed)
		times = Float64[now(sim)]
		output = Int[0]
		wait_times = Float64[]
		sizehint!(times, max_events_hint)
		sizehint!(output, max_events_hint)
		sizehint!(wait_times, max_events_hint ÷ 2)
		@process packet_generator_trace!(sim, rng, interarrival_distribution, service_distribution, times, output, wait_times)
		run(sim, max_time)
		return times, output, wait_times
	end
end

# ╔═╡ 6b95be91-2b47-49cb-82ff-2a548ba0b023
let
	times, output, wait_times = MM1_queue_simulation_trace(interarrival_distribution, service_distribution, 100.0; seed=7_000)
	summarize_trace(times, output, wait_times, 100.0)
end

# ╔═╡ ef46aded-d2ba-4a07-85e3-f2892f8048a7
md"""
### Online statistics

If we only need aggregate indicators, storing the complete event trace is wasteful. We can update the time-average number of customers and the waiting-time sum while the simulation runs.
"""

# ╔═╡ 955a6862-34f0-45d4-999b-cf51b73290ec
begin
	mutable struct MM1Accumulator
		last_time::Float64
		n::Int
		area_n::Float64
		wait_sum::Float64
		service_starts::Int
		completed::Int
		max_n::Int
	end

	function observe_n!(acc::MM1Accumulator, time::Float64, new_n::Int)
		acc.area_n += acc.n * (time - acc.last_time)
		acc.last_time = time
		acc.n = new_n
		acc.max_n = max(acc.max_n, new_n)
		return acc
	end

	function finish_summary(acc::MM1Accumulator, max_time::Real)
		t_end = Float64(max_time)
		area_n = acc.area_n + acc.n * max(t_end - acc.last_time, 0.0)
		mean_wait = acc.service_starts == 0 ? NaN : acc.wait_sum / acc.service_starts
		return MM1Summary(mean_wait, area_n / t_end, acc.service_starts, acc.completed, acc.max_n)
	end

	@resumable function packet_generator_online!(sim::Simulation,
			rng::Random.AbstractRNG,
			interarrival_distribution::UnivariateDistribution,
			service_distribution::UnivariateDistribution,
			acc)
		line = Resource(sim, 1)
		while true
			next_arrival_delay = rand(rng, interarrival_distribution)
			@yield timeout(sim, next_arrival_delay)
			@process packet_online!(sim, rng, service_distribution, line, acc)
		end
	end

	@resumable function packet_online!(sim::Simulation,
			rng::Random.AbstractRNG,
			service_distribution::UnivariateDistribution,
			line::Resource,
			acc)
		time_in = now(sim)
		observe_n!(acc, time_in, acc.n + 1)
		@yield request(line)
		acc.wait_sum += now(sim) - time_in
		acc.service_starts += 1
		@yield timeout(sim, rand(rng, service_distribution))
		observe_n!(acc, now(sim), acc.n - 1)
		acc.completed += 1
		@yield release(line)
	end

	function MM1_queue_summary(interarrival_distribution::UnivariateDistribution,
			service_distribution::UnivariateDistribution,
			max_time::Real; seed::Int=7_000)
		sim = Simulation()
		rng = overview_rng(seed)
		acc = MM1Accumulator(now(sim), 0, 0.0, 0.0, 0, 0, 0)
		@process packet_generator_online!(sim, rng, interarrival_distribution, service_distribution, acc)
		run(sim, max_time)
		return finish_summary(acc, max_time)
	end
end

# ╔═╡ 9f7e106a-f7a1-4837-b354-b58dfe6711fa
begin
	function MM1_many_runs_serial(nruns::Int, max_time::Real; seed::Int=7_000)
		summaries = Vector{MM1Summary}(undef, nruns)
		for i in eachindex(summaries)
			summaries[i] = MM1_queue_summary(interarrival_distribution, service_distribution, max_time; seed=seed+i)
		end
		return summaries
	end

	function MM1_many_runs_threaded(nruns::Int, max_time::Real; seed::Int=7_000)
		summaries = Vector{MM1Summary}(undef, nruns)
		Threads.@threads for i in eachindex(summaries)
			summaries[i] = MM1_queue_summary(interarrival_distribution, service_distribution, max_time; seed=seed+i)
		end
		return summaries
	end

	function summarize_runs(summaries::Vector{MM1Summary})
		return (
			mean_wait = mean(s.mean_wait for s in summaries),
			mean_time_average_n = mean(s.time_average_n for s in summaries),
			total_service_starts = sum(s.service_starts for s in summaries),
			total_completed = sum(s.completed for s in summaries),
			max_n = maximum(s.max_n for s in summaries),
		)
	end
end

# ╔═╡ c056fe7c-c760-4c07-83c1-56c3f7cc4c9d
let
	summaries = MM1_many_runs_threaded(12, 250.0; seed=7_000)
	summarize_runs(summaries)
end

# ╔═╡ fb0ff874-2683-4517-bf43-166b0187f848
md"""
### Warm-up deletion and batch means

Queueing simulations often start empty, while the formulas above describe steady-state behaviour. One simple output-analysis workflow is:
1. discard an initial warm-up period;
2. split the remaining trace into equal time batches;
3. treat the batch means as approximately independent observations.

This is not a magic guarantee of independence, but it is a useful practical diagnostic and a good first estimate of simulation uncertainty.
"""

# ╔═╡ 0ea46f55-5dcc-475c-9aba-8458e4f61a8a
begin
	function time_average_n_between(times::Vector{Float64}, output::Vector{Int}, start_time::Real, end_time::Real)
		t0 = Float64(start_time)
		t1 = Float64(end_time)
		t1 > t0 || throw(ArgumentError("end_time must be larger than start_time"))
		area = 0.0
		for i in eachindex(output)
			next_time = i < length(times) ? times[i + 1] : t1
			segment_start = max(times[i], t0)
			segment_end = min(next_time, t1)
			segment_end > segment_start && (area += output[i] * (segment_end - segment_start))
		end
		return area / (t1 - t0)
	end

	function batch_means_n(times::Vector{Float64}, output::Vector{Int}; warmup::Real, batch_length::Real, nbatches::Int)
		[
			time_average_n_between(
				times,
				output,
				warmup + (batch - 1) * batch_length,
				warmup + batch * batch_length,
			)
			for batch in 1:nbatches
		]
	end
end

# ╔═╡ a097fa63-d64f-46e9-99f6-2ddd7dfc7d98
let
	warmup = 200.0
	batch_length = 100.0
	nbatches = 8
	horizon = warmup + batch_length * nbatches
	times, output, _ = MM1_queue_simulation_trace(
		interarrival_distribution,
		service_distribution,
		horizon;
		seed=6_001,
		max_events_hint=round(Int, 2λ * horizon),
	)
	batches = batch_means_n(times, output; warmup, batch_length, nbatches)
	ci = mean_ci(batches)
	DataFrame(
		metric=["warm-up", "batch length", "batches", "mean batch L", "lower 95% CI", "upper 95% CI", "theoretical E[L]"],
		value=[warmup, batch_length, nbatches, ci.mean, ci.lower, ci.upper, λ / (μ - λ)],
	)
end

# ╔═╡ f32a8c75-6f1c-4872-9d1f-59c71ea9f0ef
md"""
### Small benchmark comparison

The exact speedups depend on your computer and on the number of Julia threads. The pattern to look for is more important than the absolute timing: avoid storing data you do not need, preallocate when the size is known, and parallelize independent replications.

Benchmarks are skipped by default to keep the notebook responsive. Set `RUN_BENCHMARKS = true` near the top of the notebook to run this comparison.
"""

# ╔═╡ da95e3bf-3ba0-496b-bb0e-34cf3eab9a3f
function benchmark_mm1_variants(; max_time::Float64=120.0, nruns::Int=4)
	variants = [
		("trace + posthoc", () -> MM1_trace_summary(interarrival_distribution, service_distribution, max_time; seed=7_000)),
		("local rng trace", () -> begin
			times, output, wait_times = MM1_queue_simulation_trace(interarrival_distribution, service_distribution, max_time; seed=7_000)
			summarize_trace(times, output, wait_times, max_time)
		end),
		("online summary", () -> MM1_queue_summary(interarrival_distribution, service_distribution, max_time; seed=7_000)),
		("serial replications", () -> MM1_many_runs_serial(nruns, max_time; seed=7_000)),
		("threaded replications", () -> MM1_many_runs_threaded(nruns, max_time; seed=7_000)),
	]

	names = String[]
	times_ms = Float64[]
	allocations = Int[]
	memory_kib = Float64[]
	for (name, f) in variants
		trial = @benchmark $f() samples=3 evals=1 seconds=0.25
		estimate = median(trial)
		push!(names, name)
		push!(times_ms, estimate.time / 1e6)
		push!(allocations, estimate.allocs)
		push!(memory_kib, estimate.memory / 1024)
	end

	baseline_time = first(times_ms)
	return DataFrame(
		variant = names,
		median_ms = round.(times_ms; digits=2),
		allocations = allocations,
		memory_kib = round.(memory_kib; digits=1),
		speedup_vs_baseline = round.(baseline_time ./ times_ms; digits=2),
	)
end

# ╔═╡ e2958e8e-a1b1-4f77-bb42-f3e62e9a77cc
if RUN_BENCHMARKS
	benchmark_mm1_variants()
else
	DataFrame(
		variant=["benchmarks skipped"],
		median_ms=[missing],
		allocations=[missing],
		memory_kib=[missing],
		speedup_vs_baseline=[missing],
		note=["Set RUN_BENCHMARKS = true to run this cell."],
	)
end

# ╔═╡ 1270f652-40b7-4088-b1a2-164decdf7f18
md"""
## Considerations
There are some things you should keep in mind when running simulations:

### Runtime
Runtime refers to the amount of time a simulation takes to execute. It encompasses the entire duration from the start of the simulation until it finishes, including all computations and processes involved in generating the results.

Long runtimes can be impractical, especially for complex models or those requiring numerous iterations to achieve statistical significance. Knowing the runtime helps in planning and allocating computational resources effectively.
It can also be used for comparing the efficiency of different simulation algorithms or models.

**Note**: You can often run simulations in parallel by dispatching independent replications to separate threads. This can substantially improve the total computation time.

### Number of Runs
The number of runs refers to the number of times a simulation is executed. Each run typically starts with different initial conditions or random seeds to ensure statistical validity and robustness of the results.

Multiple runs are necessary to obtain reliable and statistically significant results, reducing the impact of random variations. A higher number of runs allows for more accurate estimation of confidence intervals for the simulated metrics and it ensures that the simulation model's behavior is consistent and reproducible across different runs.


### Stationarity & Ergodicity 
A stationary system is one where its statistical properties (e.g., mean, variance) do not change over time. The behavior of the system remains consistent regardless of when you start observing it.

An ergodic system is one where time averages (averages taken over a single, long run) are equivalent to ensemble averages (averages taken across multiple independent runs at a specific time point). In other words, observing a single run for a long enough duration is sufficient to capture the full range of system behavior.

Why does it matter? If a system is both stationary and ergodic, it simplifies the interpretation of simulation results. A single long run can provide a reliable representation of the system's overall behavior. However, many real-world systems exhibit non-stationarity (e.g., due to changing customer arrival rates) or non-ergodicity (e.g., due to warm-up periods). In these cases, careful consideration is needed when designing experiments and analyzing simulation output.

Given the prevalence of non-stationary and non-ergodic systems in real-world scenarios, it is crucial to carefully assess these properties before designing and interpreting simulation experiments. Some things you can consider:
* Use statistical tests to assess stationarity (e.g., Augmented Dickey-Fuller test). If non-stationarity is detected, consider transforming the data or modeling the underlying trends to achieve stationarity (cf. time series analysis).
* Analyze simulation output to identify any initial warm-up periods where the system's behavior stabilizes. Discard data from this period to ensure subsequent analysis reflects steady-state behavior.
* Even if a system appears stationary, conduct multiple independent runs with different random number seeds. This helps assess the variability of results and provides a more comprehensive understanding of the system's behavior.
* For non-stationary systems, consider time-dependent analysis methods or techniques that account for trends and seasonality. For non-ergodic systems, focus on ensemble averages obtained from multiple runs, as time averages may not be representative.
* In complex systems, a combination of stationary and non-stationary analysis techniques might be necessary. For instance, you can model short-term dynamics as stationary while accounting for long-term trends through non-stationary methods.


### Regenerative approach
The regenerative approach is a technique for analyzing simulation output. It involves identifying "regeneration points" within a simulation run. These are time points where the system essentially "restarts" statistically, becoming independent of its past behavior. By dividing a long simulation run into these independent cycles, the regenerative approach allows for the calculation of more accurate confidence intervals for performance measures.

The regenerative approach helps address the issue of autocorrelation in simulation output. In many systems, events occurring close in time are not statistically independent. This autocorrelation can lead to underestimation of confidence intervals when using traditional statistical methods. The regenerative approach, by focusing on independent cycles, provides a more reliable way to estimate the variability of simulation results.
"""

# ╔═╡ Cell order:
# ╟─af43ec68-24a5-11ef-395c-f52d0ef97f09
# ╟─3ffef524-2386-4010-878c-c11c7e0515a8
# ╠═bad420d3-8971-4b03-816d-8be354f5009d
# ╠═dfe045a5-b5a4-4b98-aad8-668d2fd77c1e
# ╟─1f9f0785-abc5-406e-a517-32c218904e4c
# ╟─ee7affdb-177e-4da9-abe5-fd7f23820ece
# ╟─256512c8-6b13-48fb-a5eb-9aefb241ce3a
# ╟─078324c1-128e-4805-813f-4da02b967d61
# ╟─3e361b9a-2ef9-46f1-8e64-127f0a53af42
# ╟─49b288bf-b0a2-4e29-bfc0-779bd80c0bc2
# ╟─2e5e85ed-2234-48ee-a73d-33d73d06112a
# ╟─e3f8cfb6-f285-45f0-a551-6412e3b2f35c
# ╠═98c7d5e9-0476-48f0-8dfc-21de440018b1
# ╟─7431f6ed-f69a-43ca-9200-0c4304357d7f
# ╠═d1afab78-ed9f-401b-81ed-3a4131d619d1
# ╠═1df06a1b-373f-4c47-a0a0-aa076905bafc
# ╟─aa80bf93-fefe-4b80-87fa-a9cdc22b9778
# ╟─2d35b0cd-2820-4e85-b090-bb83e4e082af
# ╟─86d8fd3f-c588-4205-ab85-c19a131640b4
# ╠═dcee2831-3f71-4ea0-a124-401a4a93452e
# ╠═b97beac5-fdf8-484a-89fc-f7421b6e9bd1
# ╠═07520778-2231-46d1-99a8-7db44b7491c4
# ╟─e4db485f-ef16-4d73-9787-7e89c9b056f7
# ╟─d9d29b25-ab6e-4425-8f90-4901ddd9f763
# ╟─d2cb1cbb-cd2b-463d-8a39-376874c0d3d8
# ╠═fda9c83a-4c19-4cb2-9dfe-1760f287952d
# ╟─70143d09-77ec-4bd5-b621-ec638fbfb000
# ╟─5500645f-67f0-486d-834b-a6aebbf74880
# ╠═9b3ec442-df47-4dce-8dc0-373d8737252b
# ╟─5b9c83fd-8031-450a-8217-d8c6d1f884a6
# ╟─bfd5a133-004d-4889-b541-f40e05b51e54
# ╟─8e02afc1-1471-4d03-9a37-2d82526e0e80
# ╠═af159f28-a476-402f-9f96-123b2cbf5f8f
# ╟─0eaac249-2020-4264-a8d2-1a68eb1fe4dc
# ╟─3ddd4941-a578-4c1d-b42a-ed1e47e85f39
# ╠═a874701c-f450-4016-bc37-46c7b7554dd0
# ╠═15e9aff1-695e-4178-885a-3306d0367ed2
# ╠═be35839a-c05f-4f4e-ab6b-fbe1f28b68d1
# ╟─19bdb483-7f93-4632-b94e-580886d2ced5
# ╠═8cb648c4-07a5-4746-999a-cd6140cb83b6
# ╠═6b95be91-2b47-49cb-82ff-2a548ba0b023
# ╟─ef46aded-d2ba-4a07-85e3-f2892f8048a7
# ╠═955a6862-34f0-45d4-999b-cf51b73290ec
# ╠═9f7e106a-f7a1-4837-b354-b58dfe6711fa
# ╠═c056fe7c-c760-4c07-83c1-56c3f7cc4c9d
# ╟─fb0ff874-2683-4517-bf43-166b0187f848
# ╠═0ea46f55-5dcc-475c-9aba-8458e4f61a8a
# ╠═a097fa63-d64f-46e9-99f6-2ddd7dfc7d98
# ╟─f32a8c75-6f1c-4872-9d1f-59c71ea9f0ef
# ╠═da95e3bf-3ba0-496b-bb0e-34cf3eab9a3f
# ╠═e2958e8e-a1b1-4f77-bb42-f3e62e9a77cc
# ╟─1270f652-40b7-4088-b1a2-164decdf7f18
