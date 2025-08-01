### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ 08173290-6242-11f0-004a-97a043c49b5d
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

# ╔═╡ ea86ea4b-4c53-4103-a4cc-18c6a99659ce
# Dependencies
begin
	using Graphs
	using SimpleWeightedGraphs
	using GraphPlot
	using Plots
	using Printf
	using Random
	using LinearAlgebra
	using Statistics
end

# ╔═╡ 8fc1c404-1b58-43e6-b5d2-01e831c16952
md"""
# Phase transition in networks
## Generalities - Networks

The concept of graphs has been introduced in the lectures. In what follows we will give a brief recapitulation:

!!! info "Graph"
	Abstract mathematical structure consisting of vertices (or nodes) and edges (or links) connecting pairs of vertices. Representation of a real-world network (potentially simplified).
    
	Notation: ``G = (V, E)`` where ``V`` is the set of vertices and ``E`` is the set of edges.

In the following, we will only consider undirected networks i.e. if node $i$ is connected to node $j$, then node $j$ is automatically connected to node $i$ (as is the case with Facebook friendships). For unweighted networks of $N$ nodes, the network structure can be represented by an $N \times N$ adjacency matrix $A$:

```math
a_{i,j} = \left\{
                \begin{array}{ll}
                  1 & \text{if there is an edge from node $i$ to node $j$}\\
                  0 & \text{otherwise}\\
                \end{array}
                \right.
```
The degree of a node $i$ is the number of connections it has. In terms of the adjacency matrix
$A$, the degree of node $i$ is the sum of the i$^{\text{th}}$ row of $A$:
$$k_i = \sum_{j=1}^{N}a_{i,j}$$

The average node degree $\langle k \rangle$ is then given by: $$\langle k \rangle = \frac{1}{N} \sum_{i=1}^{N}k_{i}$$


## Erdös-Rényi random graph model
One of the simplest graph models is the Erdös-Rényi random graph model, denoted by $\mathcal{G}(N,p)$ with $N$ being the amount of nodes and $p$ being the probability that a link exists between two nodes. Self-loops are excluded. The value of $p$ is typically small (this is to avoid that the average degree $\langle k \rangle$ depends on $N$, cf. specialised literature for more details). When studying random graph model models, a major aim is to predict the average behaviour of certain network metrics and, if possible, their variance.



The Erdös-Rényi random graph  exhibits a phase transition. Let us consider the size (i.e., number of nodes) of the largest connected component in the network as a function of the mean degree ⟨k⟩. When ⟨k⟩ = 0, the network is trivially composed of N disconnected nodes. In the other extreme of ⟨k⟩ = N − 1, each node pair is adjacent such that the network is trivially connected. Between the two extremes, the network does not change smoothly in terms of the largest component size. Instead, a giant component, i.e., a component whose size is the largest and proportional to N, suddenly appears as ⟨k⟩ increases, marking a phase transition. The goal of this application is to determine this value by simulation.

## Problem solution
Resolve the problem and find the phase transition.
!!! tip "Subproblems"
	* generating a random graph
	* determine the average degree
	* identifying the size of the largest connected component
	* visualising the result
	* determine the critical value

"""

# ╔═╡ Cell order:
# ╟─08173290-6242-11f0-004a-97a043c49b5d
# ╠═ea86ea4b-4c53-4103-a4cc-18c6a99659ce
# ╟─8fc1c404-1b58-43e6-b5d2-01e831c16952
