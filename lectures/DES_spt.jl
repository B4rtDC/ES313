# dependencies
using ResumableFunctions
using ConcurrentSim
using Logging
using Distributions
using Random

# ------------------------------ #
# ResumableFunctions basics
# ------------------------------ #

@resumable function fibonacci(n::Int) :: Int
    a = 0
    b = 1
    for i in 1:n
        @yield a
        a, b = b, a+b
    end
end

# ------------------------------ #
# First process demo
# ------------------------------ #
@resumable function car(env::Environment)
    while true
        @info("Start parking at $(now(env))")
        parking_duration = 5
        @yield timeout(env, parking_duration)
        @info("Start driving at $(now(env))")
        trip_duration = 2
        @yield timeout(env, trip_duration)
    end
end

# ------------------------------ #
# Process interaction demo
# ------------------------------ #

@resumable function charge(env::Environment, duration::Number)
    @yield timeout(env, duration)
end

@resumable function car2(env::Environment)
    while true
        @info("Start parking and charging at $(now(env))")
        charge_duration = 5
        charge_process = @process charge(env, charge_duration)
        @yield charge_process
        println("Start driving at $(now(env))")
        trip_duration = 2
        @yield timeout(env, trip_duration)
    end
end

@resumable function driver(env::Environment, car_process::Process)
    @yield timeout(env, 3)
    @yield interrupt(car_process)
end

@resumable function car3(env::Environment)
    while true
        @info("Start parking and charging at $(now(env))")
        charge_duration = 5
        charge_process = @process charge(env, charge_duration)
        try
            @yield charge_process
        catch exc
            exc isa ConcurrentSim.InterruptException || rethrow(exc)
            @info("Was interrupted. Hopefully, the battery is full enough ...")
        end
        @info("Start driving at $(now(env))")
        trip_duration = 2
        @yield timeout(env, trip_duration)
    end
end

# ------------------------------ #
# Shared resources demo
# ------------------------------ #

@resumable function car4(env::Environment, name::Int, bcs::Resource, driving_time::Number, charge_duration::Number)
    @yield timeout(env, driving_time)
    @info("$name arriving at $(now(env))")
    @yield request(bcs)
    @info("$name starting to charge at $(now(env))")
    @yield timeout(env, charge_duration)
    @info("$name leaving the bcs at $(now(env))")
    @yield release(bcs)
end

@resumable function resource_user(sim::Simulation, name::Int, res::Resource, wait::Float64, prio::Int)
    @yield timeout(sim, wait)
    @info("$name Requesting at $(now(sim)) with priority=$prio")
    @yield request(res, priority=prio)
    @info("$name got resource at $(now(sim))")
    @yield timeout(sim, 3.0)
    @yield release(res)
end

struct GasStation
    fuel_dispensers :: Resource
    gas_tank :: Container{Float64}
    function GasStation(env::Environment)
        gs = new(Resource(env, 2), Container(env, 1000.0, level=100.0))
        return gs
    end
end

@resumable function monitor_tank(env::Environment, gs::GasStation)
    while true
        if gs.gas_tank.level < 100.0
        @info("Calling tanker at $(now(env))")
        @process tanker(env, gs)
        end
        @yield timeout(env, 15.0)
    end
end

@resumable function tanker(env::Environment, gs::GasStation)
    @yield timeout(env, 10.0)
    @info("Tanker arriving at $(now(env))")
    amount = gs.gas_tank.capacity - gs.gas_tank.level
    @yield put(gs.gas_tank, amount)
end

@resumable function car5(env::Environment, name::Int, gs::GasStation)
    @info("Car $name arriving at $(now(env))")
    @yield request(gs.fuel_dispensers)
    @info("Car $name starts refueling at $(now(env))")
    @yield get(gs.gas_tank, 40.0)
    @yield timeout(env, 15.0)
    @yield release(gs.fuel_dispensers)
    @info("Car $name done refueling at $(now(env))")
end

@resumable function car_generator(env::Environment, gs::GasStation)
    for i = 0:3
      @process car5(env, i, gs)
      @yield timeout(env, 5.0)
    end
end

@resumable function producer(env::Environment, sto::Store)
    for i = 1:100
      @yield timeout(env, 2.0)
      @yield put(sto, "spam $i")
      @info("Produced spam at $(now(env))")
    end
end

@resumable function consumer(env::Environment, name::Int, sto::Store)
    while true
      @yield timeout(env, 1.0)
      @info("$name requesting spam at $(now(env))")
      item = @yield get(sto)
      @info("$name got $item at $(now(env))")
    end
end

struct Machine
    size :: Int
    duration :: Float64
end

@resumable function user(env::Environment, name::Int, sto::Store, size::Int)
    machine = @yield get(sto, (mach::Machine)->mach.size == size)
    @info("$name got $machine at $(now(env))")
    @yield timeout(env, machine.duration)
    @yield put(sto, machine)
    @info("$name released $machine at $(now(env))")
end

@resumable function machineshop(env::Environment, sto::Store)
    m1 = Machine(1, 2.0)
    m2 = Machine(2, 1.0)
    @yield put(sto, m1)
    @yield put(sto, m2)
end


# ------------------------------ #
# Repair problem
# ------------------------------ #

@resumable function machine(sim::Simulation, repair_facility::Resource, spares::Store{Process}, F, G, rng::AbstractRNG)
    while true
        try
            @yield timeout(sim, Inf)
        catch exc
            exc isa ConcurrentSim.InterruptException || rethrow(exc)
        end
        @info "At time $(now(sim)): $(active_process(sim)) starts working."
        @yield timeout(sim, rand(rng, F))
        @info "At time $(now(sim)): $(active_process(sim)) stops working."
        get_spare = get(spares)
        @yield get_spare | timeout(sim, 0.0)
        if state(get_spare) != ConcurrentSim.idle
            interrupt(value(get_spare))
        else
            throw(ConcurrentSim.StopSimulation("No more spares!"))
        end
        @yield request(repair_facility)
        @info "At time $(now(sim)): $(active_process(sim)) repair starts."
        @yield timeout(sim, rand(rng, G))
        @yield release(repair_facility)
        @info "At time $(now(sim)): $(active_process(sim)) is repaired."
        @yield put(spares, active_process(sim))
    end
end

@resumable function start_sim(  sim::Simulation, repair_facility::Resource, spares::Store{Process}, 
                                N::Int, S::Int, F::UnivariateDistribution, G::UnivariateDistribution,
                                rng::AbstractRNG)
    procs = Process[]
    for i=1:N
        push!(procs, @process machine(sim, repair_facility, spares, F, G, rng))
    end
    @yield timeout(sim, 0.0)
    for proc in procs
        interrupt(proc)
    end
    for i=1:S
        @yield put(spares, @process machine(sim, repair_facility, spares, F, G, rng))
    end
end

function sim_repair(N::Int, S::Int, F::UnivariateDistribution, G::UnivariateDistribution; rng::AbstractRNG=Random.default_rng())
    sim = Simulation()
    repair_facility = Resource(sim)
    spares = Store{Process}(sim)
    @process start_sim(sim, repair_facility, spares, N, S, F, G, rng)
    msg = run(sim)
    stop_time = now(sim)
    @info "At time $stop_time: $msg" maxlog=100 # limit number of log messages
    stop_time
end

# ------------------------------ #
# M/M/1 queue simulation
# ------------------------------ #

@resumable function packet_generator(sim::Simulation, 
                                     interarrival_distribution::UnivariateDistribution, 
                                     service_distribution::UnivariateDistribution, 
                                     times::Vector{Float64}, output::Vector{Int},
                                     wait_times::Vector{Float64},
                                     rng::AbstractRNG)
    line = Resource(sim, 1)
    while true
        next_arrival_delay = rand(rng, interarrival_distribution)
        @yield timeout(sim, next_arrival_delay)
        @process packet(sim, service_distribution, line, times, output, wait_times, rng)
    end
end

@resumable function packet( sim::Simulation, 
                            service_distribution::UnivariateDistribution, 
                            line::Resource, 
                            times::Vector{Float64}, output::Vector{Int},
                            wait_times::Vector{Float64},
                            rng::AbstractRNG)
    time_in = now(sim)
    push!(times, time_in)
    push!(output, output[end]+1)
    @yield request(line)
    time_service_start = now(sim)
    wait_time = time_service_start - time_in
    push!(wait_times, wait_time)
    service_delay = rand(rng, service_distribution)
    @yield timeout(sim, service_delay)
    time = now(sim)
    push!(times, time)
    push!(output, output[end]-1)
    @yield release(line)
end

function MM1_queue_simulation(interarrival_distribution::UnivariateDistribution, service_distribution::UnivariateDistribution, max_time; rng::AbstractRNG=Random.default_rng())
    sim = Simulation()
    times = Float64[now(sim)]
    wait_times = Float64[]
    output = Int[0]
    @process packet_generator(sim, interarrival_distribution, service_distribution, times, output, wait_times, rng)
    run(sim, max_time)
    
    return times, output, wait_times
end
