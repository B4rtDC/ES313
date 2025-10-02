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

# ╔═╡ 590d74fd-3143-4676-92e8-5e9a24092c29
begin
	# Pkg needs to be used to force Pluto to use the current project instead of making an environment for each notebook
	using Pkg
	# this is redundant if you run it through start.jl, but to make sure...
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using PlutoUI
	PlutoUI.TableOfContents()
end

# ╔═╡ 85e6ee4c-db6e-45dd-a33f-30cd3c9c51e2
# dependencies
begin
	using Graphs
	using SimpleWeightedGraphs
	using GraphPlot
	using Plots
	using Printf   # for fancy text rendering
	using Random
	using LinearAlgebra
	using Statistics
end

# ╔═╡ c6fed3f2-dd79-4dcc-bce8-5c61b3dc9be4
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

# ╔═╡ 1b54ae03-10ec-44c7-bcee-99cceee0b1fc
md"""
# Agent-based modeling
## Principle
!!! info "Agent-based modeling (ABM)"
	A computational approach where you simulate a system by modeling its individual components (called "agents") and letting their interactions drive the overall behavior. 

	Each agent is a distinct entity with its own rules, traits, and decision-making logic, acting based on its local environment or neighbors.

Examples:
* A virtual ant colony, where each ant has simple instructions such as following pheromone trails when foraging. Although no explicit information is given related to pathfinding, organically, "ant highways" will arise.
* Traffic flows can also be studied in this framework: by imposing simple rules on accelaration, decelaration, and overtaking, realistic traffic jams will start to appear in the simulation.

"""

# ╔═╡ 62d79d46-149f-4261-9b5e-44deaee68828
Markdown.parse("""## Application - Flocking
!!! tip "Swarming model - Boids"
    The Boids model simulates flocking or swarming behavior seen in animals like birds or fish. It uses simple rules to mimic complex group dynamics. Each "boid" (agent) has a specific field of view, and follows three core rules:
	1. Cohesion: move toward the average position of nearby boids to stay with the group (avoids straying)
	2. Alignment: steer to match the average heading of nearby boids for coordinated movement
	3. Separation: avoid crowding by steering away from boids that are too close (avoids collisions)

    

	Illustration of the model's principles ([Wikipedia]("https://en.wikipedia.org/wiki/Boids")):
			   
	| Cohesion | Alignment | Separation |
	|:-------: | :--------:|	 :--------: | 
	| ![]($("https://upload.wikimedia.org/wikipedia/commons/2/2b/Rule_cohesion.gif"))  |  ![]($("https://upload.wikimedia.org/wikipedia/commons/e/e1/Rule_alignment.gif")) | ![]($("https://upload.wikimedia.org/wikipedia/commons/e/e1/Rule_separation.gif"))

	``\\Rightarrow`` These simple individual rules create realistic, complex group patterns without centralized control.
	
""")

# ╔═╡ 9905781e-6096-4a38-9923-96f027ec04e5
md"""
These rules cover basic aspects, but what else should we take into account when building this?
"""

# ╔═╡ 417abab7-568c-466a-a4f0-a69e03da1ace
# Code base for boid model
begin
	"""
		Boid

	Representation of a boid state
	"""
	struct Boid
	    position::Vector{Float64}
	    velocity::Vector{Float64}
	end

	Base.show(io::IO, b::Boid) = print(io, """🐦 @($(round(b.position[1], digits=2)), $(round(b.position[2], digits=2)) going ($(round(b.velocity[1], digits=2)), $(round(b.velocity[2], digits=2))) [m/s]""" )

	
	struct BoidSim
		num_boids::Int
		max_speed::Float64
	    field_of_view::Float64
	    cohesion_weight::Float64
	    alignment_weight::Float64
	    separation_weight::Float64
	    separation_dist::Float64
	    box_size::Float64 			     # size of the box		
		boids::Vector{Boid} 			 # holds the boids
		velocity_buffer::Matrix{Float64} # buffer to hold updated velocities of the birds
		@doc"""
    BoidSim(num_boids::Int=10, max_speed=1., field_of_view=5., cohesion_weight=1., alignment_weight=1., separation_weight=1.,  separation_dist=1., box_size=100., seed=161)
	
Representation of a boid simulation state with reflective boundaries.
		"""
		function BoidSim(; num_boids::Int=10, max_speed=1., field_of_view=5., cohesion_weight=1., alignment_weight=1., separation_weight=1.,  separation_dist=field_of_view/3, box_size=100., seed=161)
			# initiate random number generator (for reproducibility)
			rng = Random.MersenneTwister(42)
			boids = Vector{Boid}(undef, num_boids)
			for i in 1:num_boids
				# generate random position in box
				pos = rand(rng, Float64, 2) .* box_size
				# generate random velocity
				vel = (rand(rng, Float64, 2) .- 0.5) .* max_speed
				# store boid in array
				boids[i] = Boid(pos, vel)
			end
			velocity_buffer = zeros(Float64, 2, num_boids)

			return new(num_boids, max_speed, field_of_view, cohesion_weight, alignment_weight, separation_weight,  separation_dist, box_size, boids, velocity_buffer)
			
		end
	end

	Base.show(io::IO, sim::BoidSim) = print(io,"Boid model sim with $(sim.num_boids) boids")

	"""
		update_boids!(s::BoidSim)

	Run a single step update of the `BoidSim`. Modifies the boids in place
	"""
	function update_boids!(s::BoidSim)
		# reset velocity buffer
		s.velocity_buffer .= hcat([b.velocity for b in s.boids]...)

		# initialize accumulators for the three rules and neighbor count (vectors)
		cohesion = zeros(2)    # sum of neighbor positions (for cohesion)
		alignment = zeros(2)   # sum of neighbor velocities (for alignment)
		separation = zeros(2)  # sum of avoidance vectors (for separation)
		
		# loop over each boid to compute new velocity based on Boids rules
    	for i in eachindex(s.boids)
			# reset acumulators
			cohesion .= zero(eltype(cohesion))
			alignment .= zero(eltype(alignment))
			separation .= zero(eltype(separation))
			num_neighbors = 0      # count of neighbors within field of view
			
			# get current position and velocity of boid i
	        pos_i = s.boids[i].position
	        vel_i = s.boids[i].velocity

			# check all other boids as potential neighbors and compute velocity updates according to the rules
	        for j in eachindex(s.boids)
	            if i == j
	                continue  # skip self
	            end
	            pos_j = s.boids[j].position
	            # only consider neighbors withing field of view
	            if sum((pos_i .- pos_j) .^ 2) < s.field_of_view ^2
					# add counter for neighbor
					num_neighbors += 1
					# cohesion: add neighbor's position to sum
					cohesion .+= pos_j
					# alignment: add neighbor's velocity to sum
					alignment .+= s.boids[j].velocity
					# separation: if too close, compute avoidance vector
					if norm(pos_i .- pos_j) < s.separation_dist
						diff = pos_i .- pos_j
						diff ./= (norm(pos_i .- pos_j) + 1e-6) # Normalize, avoid division by zero
						separation .+= diff
					end
	            end
			end

			# update velocity buffer
			new_vel = @view s.velocity_buffer[:, i]
			
			if num_neighbors > 0
				# Cohesion: steer toward average neighbor position
				cohesion ./= num_neighbors      # average position of neighbors
				cohesion .-= pos_i              # vector toward average (removing own position)
				new_vel .+= s.cohesion_weight .* cohesion # update
				# Alignment: match average neighbor velocity
				alignment ./= num_neighbors     # average velocity
				new_vel .+= s.alignment_weight .* alignment
				# Separation: steer away from close neighbors
				new_vel .+= s.separation_weight .* separation

				# avoid having infinite velocities
				if norm(new_vel) > s.max_speed
					new_vel .*= s.max_speed / norm(new_vel)
				end
			end

			# update position with new velocity, account for potential collisions (reflective boundaries)
        	s.boids[i].position .+= new_vel
			# x-coordinate
        	if s.boids[i].position[1] < 0
            	s.boids[i].position[1] = -s.boids[i].position[1]         	# reflect back
            	new_vel[1] = -new_vel[1]                               		# reverse x-velocity
        	elseif s.boids[i].position[1] > s.box_size
            	s.boids[i].position[1] = 2 * s.box_size - s.boids[i].position[1]  # reflect back
            	new_vel[1] = -new_vel[1]                               			  # reverse x-velocity
        	end
	        # y-coordinate
	        if s.boids[i].position[2] < 0
	            s.boids[i].position[2] = -s.boids[i].position[2]           	# reflect back
	            new_vel[2] = -new_vel[2]                               		# reverse y-velocity
	        elseif s.boids[i].position[2] > s.box_size
	            s.boids[i].position[2] = 2 * s.box_size - s.boids[i].position[2]  	# reflect back
	            new_vel[2] = -new_vel[2]                               				# reverse y-velocity
	        end
        
        	# update velocity with final new_vel (post-reflection)
        	s.boids[i].velocity .= new_vel
		end

		return s
	end

	
	"""
		draw_boids(b::BoidSim)

	Helper function to show the boids and their velocities
	"""
	function draw_boids(b::BoidSim, scale_factor=10; draw_los::Bool=false, np=23)
		box_size = b.box_size
	    x = [boid.position[1] for boid in b.boids]
	    y = [boid.position[2] for boid in b.boids]
	    u = [boid.velocity[1] for boid in b.boids]
	    v = [boid.velocity[2] for boid in b.boids]

		# plot position
	    p = scatter(x, y, markersize=4, label="boid", color=:blue, marker=:circle, alpha=0.5,
	                xlim=(0, box_size), ylim=(0, box_size),
	                title="Boids Simulation (Step)",
	                xlabel="X", ylabel="Y", aspect_ratio=:equal)

		# plot velocities (scaled)
	    quiver!(p, x, y, quiver=(u .* scale_factor, v .* scale_factor), color=:red, label="")
		plot!(p,[],[], color=:red, label="velocity")

		# add line-of-sight if required
		if draw_los
			for boid in b.boids
				x = boid.position[1] .+ b.field_of_view .* cos.(range(0, 2*π, length=np+1))
				y = boid.position[2] .+ b.field_of_view .* sin.(range(0, 2*π, length=np+1))
				plot!(p, x,y, color=:green, alpha=0.5, label="")
			end
			plot!(p,[],[], color=:green, alpha=0.5, label="line-of-sight")
		end

		plot!(p, legendposition=:outertopright, legendfontsize=14, size=(800,500))

		annotate!(p, b.box_size * 1.25, 0.5 * b.box_size, text("""Settings\n------------\nN: $(b.num_boids)\nv_max:$(round(b.max_speed, digits=2))
    FoV=$(round(b.field_of_view, digits=2))
    w_coh=$(round(b.cohesion_weight, digits=3))
    w_align=$(round(b.alignment_weight, digits=3))
    w_sep=$(round(b.separation_weight, digits=3))
    sep_dist=$(round(b.separation_dist, digits=2))""", :left, 10, :black))
	    return p
	end

	md"""
	`Code base for Boid model`
	"""
end

# ╔═╡ 6d2d08c4-f506-40a9-8263-58dbd4e31e3e
begin
	# initial configuration
	sim = BoidSim(num_boids=20, field_of_view=10.)
	p = draw_boids(sim, draw_los=true)
	plot!(p, title="Boids Simulation (Initial)")
end

# ╔═╡ ed837bfb-169c-4aa6-8521-e471611f87f4
@bind step_boid html"<input type=button value='next iteration'>"

# ╔═╡ a1f16676-3f6e-4518-bbbd-42b99edc4f70
if step_boid === "next iteration"
	update_boids!(sim)
	draw_boids(sim, draw_los=true)
end

# ╔═╡ 4a6608bf-bd15-4005-bbc8-488afc65dcee
let
	# initial configuration
	sim = BoidSim(num_boids=20, field_of_view=10)
	anim = @animate for step in 1:800
		draw_boids(sim, draw_los=true)
		update_boids!(sim)
	end

	gif(anim,"./lectures/img/boids_animation.gif", fps=30)	
end

# ╔═╡ 1f0ea6ed-93f5-49ba-ac1e-b2e38370f3c8
md"""
**Note** 

There even exists an entire Julia package focussing entirely on Agent Based Models: [Agents.jl](https://juliadynamics.github.io/Agents.jl/stable/)

![](https://github.com/JuliaDynamics/JuliaDynamics/blob/master/videos/agents/agents4_logo.gif?raw=true)
"""

# ╔═╡ 42bc0402-149f-11f0-22d3-295f5dfa2ca9
md"""# Networks and graphs
Many real-world systems can be represented as (potentially different) entities that are connected in some way to one another. We often call this a network. Examples include social networks, transportation networks, computer networks, biological networks.

!!! info "Network"
	While often used interchangeably with "graph", it typically refers to a real-world system of interacting entities
    

!!! info "Graph"
	Abstract mathematical structure consisting of vertices (or nodes) and edges (or links) connecting pairs of vertices. Representation of a real-world network (potentially simplified).
    
	Notation: ``G = (V, E)`` where ``V`` is the set of vertices and ``E`` is the set of edges.

Graphs basics:
* A graph can also be represented by its adjacency matrix ``A``, where a non-zero value ``a_{ij}`` represents that a connection from node ``i`` to ``j`` is present (note how this implies that a graph can be directional). 
* Edges can also have weights (typically positive weights, altough negative weighted graphs are definined, but handling these is not straightforward)

Some examples:
"""

# ╔═╡ d01f1f2e-af33-417f-b6cc-894d95f56c15
let
	# example
	A = [0 1 1 0; 
		 0 0 0 0;
		 1 1 0 1;
		 0 0 1 0]
	G = DiGraph(A)
	msg =  join(["$(row)" for row in eachrow(A)],"\n")
	@info "Adjacency matrix: \n$(msg)" 
	
	gplot(G, nodelabel = 1:nv(G), background_color="white", plot_size=(10cm,10cm), title="directed, unweighted graph",edgestrokec="black", nodefillc=colorant"rgba(50,50,250,0.4)")
end

# ╔═╡ 44b81a7f-a7b7-4a2f-8c55-3c495cb5a9cc
let
	# example
	Aw = [0 3 2 0; 
		 0 0 0 0;
		 1 5 0 1;
		 0 0 4 0]
	Gw = SimpleWeightedDiGraph(Aw)
	E = edges(Gw)
	Ew = [e.weight for e in E]
	msgw =  join(["$(row)" for row in eachrow(Aw)],"\n")
	@info "Adjacency matrix (weighted): \n$(msgw)" 
	
	gplot(Gw, nodelabel = 1:nv(Gw), background_color="white", plot_size=(10cm,10cm), 
		  title="directed, weighted graph", linetype="curve", edgelinewidth=Ew,
		 edgestrokec="black", nodefillc=colorant"rgba(50,50,250,0.4)")
	
end

# ╔═╡ 1b303b0a-b9e7-453f-b2aa-2e395fd37619
md"""
## Graph metrics
Graph metrics are values we can compute on node, meso, or graph level that allow us to describe a graph and and its nodes. 

!!! note "Degree"
	Quantifies the connectivity of individual nodes
	
	* Undirected graph : the degree ``k_i`` of a node ``i`` is the number of edges connected to it. It's the count of its neighbors.
    * Directed graph:
        *   In-degree, ``k_{in}``: number of edges pointing to the node.
        *   Out-degree, ``k_{out}``: number of edges pointing away from the node.
        *   Total degree: ``k = k_{in} + k_{out}``



"""

# ╔═╡ 295b1f30-641a-4941-863d-854acd2a27c7
let
	A = vcat([0, 1, 1, 1]',[0, 0, 1, 1]',[1, 0, 0, 0]',[0, 0, 0, 0]')
	G = SimpleDiGraph(A)
	node_size_both = degree(G) ./ maximum(degree(G))
	node_size_out = outdegree(G) ./ maximum(degree(G))
	node_size_in = indegree(G) ./ maximum(degree(G))

	@info """Adjacency matrix (directed): \n$(join(["$(row)" for row in eachrow(adjacency_matrix(G))],"\n"))"""
	
	locx, locy =  spring_layout(G);
	gplot(G, locx, locy, nodelabel = 1:nv(G), background_color="white", plot_size=(8cm,8cm),  
		  title="undirected version, total degree", linetype="curve", edgelinewidth=1.,
		 edgestrokec="black", nodefillc=colorant"rgba(50,50,250,0.4)", nodesize=node_size_both),
	
	gplot(G, locx, locy, nodelabel = 1:nv(G), background_color="white", plot_size=(8cm,8cm), 
		  title="undirected version, outdegree", linetype="curve", edgelinewidth=1.,
		 edgestrokec="black", nodefillc=colorant"rgba(50,50,250,0.4)", nodesize=node_size_out),
	gplot(G, locx, locy, nodelabel = 1:nv(G), background_color="white", plot_size=(8cm,8cm), 
		  title="undirected version, indegree", linetype="curve", edgelinewidth=1.,
		 edgestrokec="black", nodefillc=colorant"rgba(50,50,250,0.4)", nodesize=node_size_in)
end

# ╔═╡ a94dfec9-4f6d-4ac1-b639-4f3403e0fb7f
md"""
!!! note "Path"
	A path in a graph is a sequence of vertices where each consecutive pair is connected by an edge. Formally, given a graph `` G = (V, E) ``, a path from vertex `` v_0`` to vertex `` v_k`` is a sequence of vertices ``v_0, v_1, \dots, v_k `` such that ``\forall i = 0, 1, \dots, k-1: (v_i, v_{i+1}) \in E``. 

	* A path can be directed and has a length, defined as the number of edges.
	* A cycle is a path where the start and end vertices are the same .
	* A simple path has no repeated vertices (except possibly the start and end in a cycle).
	


!!! note "Component"
	A component in a graph is a maximal connected subgraph, meaning a subset of vertices and edges where every pair of vertices is connected by at least one path, and no additional vertices or edges can be added while maintaining this connectivity. Formally, in an undirected graph `` G = (V, E) ``, a component is a subset `` C \subseteq V `` such that: (1) there exists a path between any pair of vertices in `` C `` and (2) `` C `` is maximal, i.e., no vertex outside `` C `` is connected to any vertex in `` C `` by an edge.

	- In a connected graph, there is exactly one component (the entire graph), whereas in a disconnected graph, there are multiple components, each isolated from the others.
	- In directed graphs, components are often defined as strongly connected components (where there is a directed path from any vertex to any other in the component) or weakly connected components (connected when ignoring edge directions).


"""

# ╔═╡ 571b3127-defa-410a-a3ac-0cb140df033b
let
	my_colors = [
		colorant"rgba(50,50,250,0.4)";
		colorant"rgba(50,150,50,0.4)";
		colorant"rgba(150,50,150,0.4)";
	]
	
	edge_list = Edge.([(1, 2), (2, 3), (3, 1), (4, 5), (5, 6), (5, 4)])
	# undirected version
	G = Graphs.SimpleGraphFromIterator(edge_list)
	comps = connected_components(G)
	node_colors = zeros(eltype(my_colors), nv(G))
	for i in eachindex(comps)
		for v in comps[i]
			node_colors[v] = my_colors[i]
		end
	end
	
	# directed version
	G_d =Graphs.SimpleDiGraphFromIterator(edge_list)
	comps_dw = weakly_connected_components(G_d)
	comps_ds = strongly_connected_components(G_d)
	node_colors_dw = zeros(eltype(my_colors), nv(G))
	for i in eachindex(comps_dw)
		for v in comps_dw[i]
			node_colors_dw[v] = my_colors[i]
		end
	end
	node_colors_ds = zeros(eltype(my_colors), nv(G))
	for i in eachindex(comps_ds)
		for v in comps_ds[i]
			node_colors_ds[v] = my_colors[i]
		end
	end

	@info """Adjacency matrix (directed): \n$(join(["$(row)" for row in eachrow(adjacency_matrix(G_d))],"\n"))"""
	
	locx, locy =  spring_layout(G);
	gplot(G, locx, locy, nodelabel = 1:nv(G), background_color="white", plot_size=(8cm,8cm), 
		  title="undirected version, components", linetype="curve", edgelinewidth=10,
		 edgestrokec="black", nodefillc=node_colors, nodesize=2.),
	gplot(G_d, locx, locy, nodelabel = 1:nv(G_d), background_color="white", plot_size=(8cm,8cm), 
		  title="directed version, weak components", linetype="curve", edgelinewidth=10,
		 edgestrokec="black", nodefillc=node_colors_dw, nodesize=2.),
	gplot(G_d, locx, locy, nodelabel = 1:nv(G_d), background_color="white", plot_size=(8cm,8cm), 
		  title="directed version, strong components", linetype="curve", edgelinewidth=10,
		 edgestrokec="black", nodefillc=node_colors_ds, nodesize=2.)
end

# ╔═╡ 3098c8fe-4ba7-4290-ae2f-118d9e50fa9d
md"""
!!! note "Betweennes Centrality"
	Betweenness centrality measures the importance of a vertex (or edge) in a graph based on how often it lies on the shortest paths between pairs of other vertices. It quantifies the extent to which a vertex acts as a "bridge" in the network.

	Formally, for a vertex `` v `` in a graph `` G = (V, E) `` the betweenness centrality `` C_B(v) `` is defined as:

	```math
	C_B(v) = \sum_{s \neq t \neq v \in V} \frac{\sigma_{st}(v)}{\sigma_{st}},
	```
	where `` \sigma_{st} `` represents the total number of shortest paths from vertex `` s `` to vertex `` t ``, and ``\sigma_{st}(v) `` represents the  number of those shortest paths that pass through vertex ``v.`` The sum is taken over all pairs of vertices `` s, t \in V `` (excluding `` v ``).

	- High betweenness centrality indicates a vertex is critical for connecting different parts of the graph. When evaluating node importance using this metric, you implicitely assume that the shortest path will be used to travel between nodes, which is not necessarily true in all applications.
	- It applies to both undirected and directed graphs, and can be computed for edges as well.
	- For disconnected, directed graphs: betweenness only reflects intra-component paths, ignoring the broader network. This can lead to a situation where high betweenness in one component might dwarf scores in another. Misinterpreting betweenness without considering connectivity could lead to overlooking key nodes or bottlenecks in specific subnetworks.
"""

# ╔═╡ 04b96931-2140-42d5-8e93-0ebd9e835e91
let
	G = wheel_graph(10)
	bc = betweenness_centrality(G)
	@info "betweenness_centrality:\n$(bc)"
	gplot(G, nodelabel = 1:nv(G), background_color="white", plot_size=(8cm,8cm), 
		  title="wheel graph, betweenness", linetype="straight", edgelinewidth=0.1,
		 edgestrokec="black", nodefillc=colorant"rgba(50,50,250,0.4)", nodesize=bc .* 3)
	
end

# ╔═╡ 556daa75-47ca-4e71-abac-4610ec9cf8b8
md"""
## Graph models
There are many approaches to building a network, and some of these models are detailed below
!!! tip "Barabási–Albert model"
	Underlying principle: grow the network through preferential attachment, i.e. a new node always has $m$ neighbors. The neigbors are chosen at random, but proportional to the node's degree
	```math
	p_i = \frac{d_i}{\sum_j d_j}
	```

	It can be shown that the degree distribution of such a network follows a power law with coeffient ``\alpha = 3``

	This network model has been used to explain real world processes and model the internet.

Illustration of the Barabási–Albert model ([source](https://networksciencebook.com/chapter/5#growth)):
$(LocalResource("./lectures/img/barabasi_albert_growth.jpg"))

"""

# ╔═╡ ad23fe31-c3a1-4537-8613-f40e9aefddf5
md"""
While we will not go into detail on the theoretical aspect of the power law, we can try to confirm it through an experiment.

Our starting hypothesis is that the degree distribution of out Barabási–Albert graph follows a power law, i.e. ``p(x=k) = C x^{-\alpha}``


In the example below, we proceed as follows:
1. we generate a random Barabási–Albert graph
2. we compute the ccdf of the degree distribution
3. we fit a regression line on the tail of the ccdf (in log transform, which also follows a power law with exponent ``\alpha - 1`` (see [Newman's work](https://arxiv.org/pdf/cond-mat/0412004) for the derivation)
"""

# ╔═╡ 071809df-ba36-4e88-b958-b3ca160e04f0
let
	G = barabasi_albert(200000, 2)
	d = degree(G)
	# finding the scale-free property
	sorted_d = sort(d)
	unique_d = sort(unique(sorted_d))
	n_d = length(sorted_d)
	P_greater_d = Float64[]
	# durations part
	for x in unique_d[1:end-1]
		push!(P_greater_d, sum(unique_d .> x) / n_d)
	end
	
	# fit regression type x^(-\alpha) line for durations larger than 10^2
    mask = unique_d[1:end-1] .> 100
    x_fit = unique_d[1:end-1][mask]
    y_fit = P_greater_d[mask]
    # Simple linear regression in log-log space: log(y) = -α * log(x) + c
	X = [log10.(x_fit) .^0 log10.(x_fit)]
	Y = log10.(y_fit)
	b = (X' * X) \  (X' * Y)
	
	scatter(unique_d[1:end-1], P_greater_d, xscale=:log10, yscale=:log10, label="ccdf(degree)")
	plot!(x_fit, 10 .^(b[2] .* log10.(x_fit) .+ b[1]), color=:blue, alpha=0.5, label=@sprintf("power law fit (α = %.2f)",-(b[2]-1)), legendposition=:bottomleft)
	ylims!(1e-5, 1e-3)
	xlabel!("degree")
	ylabel!("P(D<d)")
	title!("barabasi-albert network\n(200,000 nodes, 2 preferential attachments)")
end

# ╔═╡ 6b93d24f-eefd-488c-b181-61aaec36c506
md"""

!!! tip "Erdős-Rényi model"
	Underlying principle: we have a network of size ``n``, every possible edge in the network is either present or not with a probability ``p``.

	*Note: there is also a version where the number of nodes and the number of edges is fixed.*

!!! tip "Configuration model"
	This random graph model that allows to create a graph that hase the same degree sequence as an observed graph. In practice this is done by switching edges.

	*Note: there is a risk of having the same edge occur twice, or having a self-edge.*

There are many other graph models (such as the [stochastic block model](https://en.wikipedia.org/wiki/Stochastic_block_model) used below), and many extensions exist for directed and weighted graphs.
"""

# ╔═╡ 378ceb57-6639-4e3c-b9e3-886df99ff735
md"""
# ABM on networks - epidemic spreading

## Epidemic spreading (SIR)
Epidemic spreading models how diseases propagate through a population or network. For this application we will use the SIR model, which is a foundational model for this kind of applications. 

!!! note "SIR model"
	In an SIR model, the population members (agents), can be in one of three states:
	- S (Susceptible): individuals who can contract the disease.
	- I (Infected): individuals who have the disease and can spread it.
	- R (Recovered: individuals who have recovered and are immune (or removed, e.g., deceased).
	
	The model allows for the following transitions: 
	- Infection process: ``S \mapsto I``.
	- Recovery process: ``I \mapsto R``.

## SIR model on networks
A network can be used to model the structure of real-world interactions between people (social network).
So infections will occur along edges between nodes, reflecting contact patterns.
In the SIR model on a network:
- Each node represents an individual in one of the states (S, I, or R).
- Edges represent potential transmission pathways.
- Parameters:
  - Infection rate ``\beta``: probability an infected node infects a susceptible neighbor per time step.
  - Recovery rate ``\gamma``: probability an infected node recovers per time step.

The dynamics evolve in discrete time steps:
1. Infected nodes attempt to infect susceptible neighbors with probability `` \beta ``
2. Infected nodes recover with probability `` \gamma ``
3. The process continues until no infected nodes remain or a set number of steps is reached.

## Implementation principles
- Synchronous updates: all state changes (infections and recoveries) are computed based on the current state and applied simultaneously, avoiding order-dependent artifacts.
- The graph structure determines who can infect whom, capturing realistic contact patterns .
- Using random numbers (`rand() < β` and `rand() < γ`) introduces stochastic behavior, reflecting real-world variability.

"""

# ╔═╡ 050f4689-51f9-4f3a-aec6-8627a223a29a
begin
	G = barabasi_albert(100, 3, seed=161)
	d = degree(G)

	# get postitions
	locs_x, locs_y = spring_layout(G)
	gplot(G, locs_x, locs_y, background_color="white", plot_size=(25cm,25cm), 
		  title="Topology", linetype="line",nodesize=sqrt.(d) .* 2,
		 edgestrokec=colorant"rgba(0,0,0,0.1)", nodefillc=colorant"rgba(50,50,250,0.4)")
end

# ╔═╡ 3a45995d-ce17-4264-b2f5-631f00231421
@doc raw"""
	sir_network(g, β::Float64, γ::Float64, steps::Int, patient_zero::Int,states = fill('S', n) )

Models a SIR infection process on a graph `g` for a number of `steps`, starting with a single `patient_zero`. The parameters ``\beta`` and ``\gamma`` represent the infection and recovery probabilities respectively. The function returns a count vector at each time step for each of the states. By default, all nodes start susceptible (except for patient zero).
"""
function sir_network(g, β::Float64, γ::Float64, steps::Int, patient_zero::Int, states = fill('S', nv(g)) )
    n = nv(g)  					# Number of nodes
	states[patient_zero] = 'I' 	# patient zero is the only infected person
	outstates = fill(' ', n, steps+1)
	outstates[:, 1] .= states
    
    # get counts
    S_count = [count(==('S'), states)]
    I_count = [count(==('I'), states)]
    R_count = [count(==('R'), states)]
    
    for t in 1:steps
        new_states = copy(states)
        for i in 1:n
            if states[i] == 'I' 
				# Infected node tries to spread
                for j in neighbors(g, i)
                    if states[j] == 'S' && rand() < β
						# Infection succeeds
                        new_states[j] = 'I'  
                    end
                end
				# Infected node has a recovery probability
                if rand() < γ  
                    new_states[i] = 'R'
                end
            end
        end
        states .= new_states
        push!(S_count, count(==('S'), states))
        push!(I_count, count(==('I'), states))
        push!(R_count, count(==('R'), states))
		outstates[:, t+1] .= states
    end
	
    return S_count, I_count, R_count, outstates
end

# ╔═╡ d87a2a77-b1a8-4c30-bae4-46577c69c238
md"""
## Small examples
"""

# ╔═╡ 36ee5b02-1f3c-4feb-be5c-54fb3c98c69c
md"""Evolution over time:"""

# ╔═╡ 65a3f3c7-af4b-4998-a5f7-067b1bef14cc
begin
	S,I,R, states = sir_network(G, 0.2, 0.2, 30, 1)
	plot(S,label="Susceptible",linetype=:steppost)
	plot!(I, label="Infected",linetype=:steppost)
	plot!(R, label="Recovered",linetype=:steppost)
	xlabel!("Iteration")
	ylabel!("Counts")
	title!("Proportions over time")
end

# ╔═╡ 89803b38-2d6b-474e-ad23-e3ea515b4a1c
md"""Evolution from a network perspective"""

# ╔═╡ 22bca145-f783-48e2-b83f-4d3d9842a5fc
begin
	# colormap
	state_colors = Dict('S' => colorant"rgba(0,0,200,0.9)", # blue
						'I' => colorant"rgba(200,0,0,0.9)", # red
						'R' => colorant"rgba(0,200,0,0.9)") # green


	# start situation
	p_start = gplot(G, locs_x, locs_y, background_color="white", plot_size=(15cm,15cm), 
		  title="Start (Patient zero)", linetype="line",nodesize=sqrt.(d) .* 2,
		 edgestrokec=colorant"rgba(0,0,0,0.1)", nodefillc=[state_colors[s] for s in states[:,1]])

	# all other situations
	(p_start, (gplot(G, locs_x, locs_y, background_color="white", plot_size=(15cm,15cm), 
		  title="t = $(j-1)", linetype="line",nodesize=sqrt.(d) .* 2,
		 edgestrokec=colorant"rgba(0,0,0,0.1)", nodefillc=[state_colors[s] for s in states[:,j]]) for j in 2:31)...)
end

# ╔═╡ 748fca52-aad0-4411-a510-b080a1a24c67
md"""
## Analysis
Now that we can run a single simulation, we can have a look at how some aspects modify the behavior. We will consider the following:
1. The impact of patient zero on the peak infection count.
2. The impact of vaccinating some people on the peak infection count.
"""

# ╔═╡ c8be9549-f8de-4a07-8d4f-6cd51a0d45f0
md"""
### Impact of patient zero
 
> Experiment:
> 1. Make every node in the graph patient zero for ``m`` times.
> 2. Consider the median peak infection level for each node.
> 3. Draw up a conclusion
 
"""

# ╔═╡ 24dbd835-d044-40ff-bef1-380745f8266c
let
	G = stochastic_block_model([5 1 2;0 4 1; 0 0 10], [300; 200; 100])
	m = 10
	β = 0.1
	γ = 0.5
	n = 100
	infected_counts = zeros(Int, nv(G), m)
	Threads.@threads for i in 1:nv(G)
		for j = 1:m
			SC,IC,RC = sir_network(G, β, γ, n, i)
			infected_counts[i, j] = maximum(IC)
		end
	end
	infected_median = median(infected_counts, dims=2) 

	plot(scatter(betweenness_centrality(G), infected_median, xlabel="Betweenness centrality", ylabel="Median peak infection", label="" ), 
		 scatter(degree(G), infected_median, xlabel="Degree", ylabel="Median peak infection", label=""),
		size=(800,400))
end

# ╔═╡ c6cc5a17-6775-4df5-8d6b-a1646ad69a25
md"""
### Impact of vaccination
> Experiment:
> 1. Vaccinate nodes, i.e. make them start in state ``R``.
> 2. Consider the peak infection value using the same patient zero each time
> 3. Start vaccination with the node with the highest degree or betweenness centrality, and increase the number of vaccinated people
"""

# ╔═╡ b562447b-7350-4c30-82cd-66dd410852af
begin
	GG = stochastic_block_model([5 1 2;0 4 1; 0 0 10], [300; 200; 100])
	# determine order for vaccinating
	cent_vals = betweenness_centrality(GG)
	vaccination_prio_list = sortperm(cent_vals, rev=true)
	max_vaccination = nv(GG)÷3 * 2
	patient_zero = vaccination_prio_list[max_vaccination + 1] # to avoid having patient zero being vaccinated

	# other settings
	β = 0.5
	γ = 0.05
	n = 1000
	m = 30 # numer of runs per setting
	infected_counts = zeros(Int, max_vaccination+1, m)
	# no vaccination
	for j = 1:m
		SC,IC,RC = sir_network(GG, β, γ, n, patient_zero)
		infected_counts[1, j] = maximum(IC)
	end
	
	# increasing number of vaccinations
	Threads.@threads for i in 1:max_vaccination
		states = fill('S', nv(GG))
		states[vaccination_prio_list[1:i]] .= 'R'
		for j = 1:m
			SC,IC,RC = sir_network(GG, β, γ, n, patient_zero, states)
			infected_counts[i+1, j] = maximum(IC)
		end
	end
	infected_mean = vec(mean(infected_counts, dims=2) )

	# illustration
	scatter( (0:max_vaccination) ./ nv(GG) , infected_mean ./ nv(GG), xlabel="Proportion of vaccinated people", ylabel="Peak infection level\n[proportion of population]", ylims=(0, 0.04), label="", xlims=(0, 0.75), alpha=0.5, title="Vaccination based on betweenness similarity")
end

# ╔═╡ Cell order:
# ╟─590d74fd-3143-4676-92e8-5e9a24092c29
# ╟─c6fed3f2-dd79-4dcc-bce8-5c61b3dc9be4
# ╠═85e6ee4c-db6e-45dd-a33f-30cd3c9c51e2
# ╟─1b54ae03-10ec-44c7-bcee-99cceee0b1fc
# ╟─62d79d46-149f-4261-9b5e-44deaee68828
# ╟─9905781e-6096-4a38-9923-96f027ec04e5
# ╟─417abab7-568c-466a-a4f0-a69e03da1ace
# ╟─6d2d08c4-f506-40a9-8263-58dbd4e31e3e
# ╟─ed837bfb-169c-4aa6-8521-e471611f87f4
# ╟─a1f16676-3f6e-4518-bbbd-42b99edc4f70
# ╠═4a6608bf-bd15-4005-bbc8-488afc65dcee
# ╟─1f0ea6ed-93f5-49ba-ac1e-b2e38370f3c8
# ╟─42bc0402-149f-11f0-22d3-295f5dfa2ca9
# ╟─d01f1f2e-af33-417f-b6cc-894d95f56c15
# ╟─44b81a7f-a7b7-4a2f-8c55-3c495cb5a9cc
# ╟─1b303b0a-b9e7-453f-b2aa-2e395fd37619
# ╟─295b1f30-641a-4941-863d-854acd2a27c7
# ╟─a94dfec9-4f6d-4ac1-b639-4f3403e0fb7f
# ╟─571b3127-defa-410a-a3ac-0cb140df033b
# ╟─3098c8fe-4ba7-4290-ae2f-118d9e50fa9d
# ╟─04b96931-2140-42d5-8e93-0ebd9e835e91
# ╟─556daa75-47ca-4e71-abac-4610ec9cf8b8
# ╟─ad23fe31-c3a1-4537-8613-f40e9aefddf5
# ╟─071809df-ba36-4e88-b958-b3ca160e04f0
# ╟─6b93d24f-eefd-488c-b181-61aaec36c506
# ╟─378ceb57-6639-4e3c-b9e3-886df99ff735
# ╟─050f4689-51f9-4f3a-aec6-8627a223a29a
# ╠═3a45995d-ce17-4264-b2f5-631f00231421
# ╟─d87a2a77-b1a8-4c30-bae4-46577c69c238
# ╟─36ee5b02-1f3c-4feb-be5c-54fb3c98c69c
# ╟─65a3f3c7-af4b-4998-a5f7-067b1bef14cc
# ╟─89803b38-2d6b-474e-ad23-e3ea515b4a1c
# ╟─22bca145-f783-48e2-b83f-4d3d9842a5fc
# ╟─748fca52-aad0-4411-a510-b080a1a24c67
# ╟─c8be9549-f8de-4a07-8d4f-6cd51a0d45f0
# ╠═24dbd835-d044-40ff-bef1-380745f8266c
# ╟─c6cc5a17-6775-4df5-8d6b-a1646ad69a25
# ╠═b562447b-7350-4c30-82cd-66dd410852af
