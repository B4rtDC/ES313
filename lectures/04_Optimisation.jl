### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ a76ef974-2046-11f0-240d-e5aa708db0e9
begin
	# Pkg needs to be used to force Pluto to use the current project instead of making an environment for each notebook
	using Pkg
	# this is redundant if you run it through start.jl, but to make sure...
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using PlutoUI
	PlutoUI.TableOfContents(depth=5)
end

# ╔═╡ 27e916ea-958c-4df8-b861-b2674798cee9
# dependencies
begin
	using Plots, LaTeXStrings, Measures, StatsPlots
	using JuMP
	using GLPK, Tulip
	using Optim
	using Ipopt
	using BenchmarkTools
	using Distributions
end

# ╔═╡ ddac3c21-7ac9-4295-aeca-a8f460c1f3b1
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

# ╔═╡ 7f3b10fe-8a8e-49ba-a468-a7fa0cb8c17d
md"""# Optimisation
In this chapter we wil have a look at some optimisation methods, and their applications. Depending on your future needs, you might even need more advanced or niche solvers. In that case, the following references can be of help:
* [Algorithms for Optimization, by Mykel J. Kochenderfer and Tim A. Wheeler](https://algorithmsbook.com/optimization/)
* [Optimization.jl](https://docs.sciml.ai/Optimization/stable/) package, which not only provides a unified interface to many optimisation package, but can also serve as a starting point to find the tool suited for the job.
* [NLOpt](https://nlopt.readthedocs.io/en/latest/), an open-source library for nonlinear optimization.


## Introduction
!!! info "Optimisation"
	The process of making a system, design, or decision as effective or functional as possible. It involves finding the best solution from a set of feasible solutions. It typically be described in a more formal way by the following components:
	- Objective function: the function that needs to be maximised or minimised.
	- Decision variables: the variables that influence the outcome of the objective function.
	- Constraints: restrictions or limitations on the decision variables (if applicable).

	Formally:
	```math
	\min_{\vec{x} \in \Omega } f(\vec{x}) \text{ subject to } \cases{\vec{h}(\vec{x}) = \vec{0}\\ \vec{g}(\vec{x}) \leq \vec{0}}
	```
	where 
	```math
	\begin{array}
	\vec{x} \in \mathbb{R}^n,\\ 
	\Omega \subseteq \mathbb{R}^n,\\  
	f : \mathbb{R}^n \mapsto \mathbb{R},\\ 
	\vec{h} :  \mathbb{R}^n \mapsto \mathbb{R}^m \; (m\leq n),\\
	\vec{g} :  \mathbb{R}^n \mapsto \mathbb{R}^p.
	\end{array}
	```


!!! danger "Heads up!"
	1. You have already encountered this type of problems in your (vector) analysis courses.

	2. For real world problems, properly defining the objective function, the variables, their domains, and all of the constraints not only is critical for a decent solution, but it is typically experienced as being one of the most difficult steps.


!!! info "Classification"

	| Dimension | Possibilities |
	| :-- | :-- |
	| Objective type | linear, nonlinear, black-box |
	| Constraints | none, equalities``^*``, inequalities``^*``, integer values, boolean values |
	| Determinism | deterministic ``\leftrightarrow`` stochastic |
	| Convexity| convex, non-convex |
	
	
	``^*``these constraints can also be linear or not, which in turn has an impact on suited algorithms.


Optimisation is a critical tool used across various fields to improve efficiency and outcomes. Being able to formulate a real-world application as an optimisation problem and knowing what is the most appropriate technique to solve it, is a very valuable and an indispensable skill for engineers.

"""

# ╔═╡ 19bc12c5-2d3c-46dc-bb9b-02efe0882295
md"""
## Unconstrained optimisation
!!! info "Setting"
	Suppose we are dealing with an objective function that is (non)linear, without any imposed constraints. The solution of the unconstrained optimization problem
	
	```math
	\min f\left(\vec x\right)
	```
	
	can often be found by finding a critical point $\vec{x}^*$, such that the first order necessary condition holds:
	
	```math
	\nabla f\left(\vec x^\star\right) = \vec 0\,.
	```
	
	This point may be a local minimum, maximum or a saddle point. If ``f`` is twice differentiable, and the Hessian, $\mathcal{H}f(\vec{x}^*$), is positive definite, then $\vec{x}^*$ is a local minimum (second order sufficient condition). Additionally, if ``f`` is convex, any local minimum is also a global minimum (cf. analysis courses). For strictly convex functions, the global minimum is unique.




!!! danger "Heads up!"
	1. In order to be able to apply this, we need to have a function that in continuous, which may not always be the case!

	    To apply gradient-based methods, the function ``f`` must be differentiable at ``\vec{x}^*``. For the Hessian test, it must be twice differentiable. If ``f`` is not differentiable, alternative methods are needed. Additionally, linear functions may not have critical points unless, and thus may not have a finite minimum in unconstrained optimization.

	2. These methods require an initial point. When multiple local minima exist, the initial point will have an impact on the result.

We can distinguish different optimization methods based on the number of derivatives used:
* Zeroth-order methods: use only function evaluations;
* First-order methods: use the gradient;
* Second-order methods: use the Hessian. 



"""

# ╔═╡ 3e7cdf87-e064-4746-abd3-8ca6a702a0fe
md"""
### Zeroth-order methods
!!! info "Nelder-Mead simplex algorithm"
	Nelder-Mead is a derivative-free optimizer of a function in ``n`` variables that keeps a simplex of ``n + 1`` points moving over the objective surface. At each step it ranks the points by their function value, tosses out the worst one, and tries four rules in order:
	- reflection (flip it through the centroid)
	- expansion (push farther if it improved)
	- contraction (pull back if it got worse)
	- shrink (tighten the whole tent if nothing helped). 
	The simplex keeps reshaping itself until its size or the spread in function values falls below a tolerance, giving a local minimum. This methods works fairly well for a limited number of variables (<=10)
"""

# ╔═╡ 561c3509-a1d4-43f4-a1ba-a55dbdfb0620
begin
simplex_basics_content = md"""
A simplex is a geometric object determined by an assembly of $n+1$ points, $\vec{p}_{0},\vec{p}_{1},\dots,\vec{p}_{n}$, in the n-dimensional space such that

```math
\det\begin{bmatrix}
\vec{p}_{0} & \vec{p}_{1} & \cdots & \vec{p}_{n}\\
1 & 1 & \cdots & 1
\end{bmatrix}\neq0\,.
```

This condition ensures that two points in $\mathbb R$ do not coincide, three points in $\mathbb R^{2}$ are not collinear, four points in $\mathbb R^{3}$ are not coplanar, and so on. Thus, a simplex in $\mathbb R$ is a line segment, in $\mathbb R^{2}$ it is a triangle, while a simplex in $\mathbb R^{3}$ is a tetrahedron; in each case it encloses a finite $n$-dimensional volume.
"""
simplex_basics = PlutoUI.details("Simplex definition", simplex_basics_content,open=false)

initial_simplex_content = md"""
Suppose that we wish to minimize $f\left(\vec{x}\right),\,\vec{x}\in\mathbb R^{n}$.
To start the algorithm, we initialize a simplex of $n+1$ points.
A possible way to set up a simplex is to start with an initial point
$\vec{x}^{\left(0\right)}=\vec{p}_{0}$ and generate the remaining
points of the initial simplex as follows:

```math
\vec{p}_{i}=\vec{p}_{0}+\lambda_{i}\vec{e}_{i},\quad i=1,2,\dots,n\:,
```

where the $\vec{e}_{i}$ are unit vectors constituting the natural
basis of $\mathbb R^{n}$. The positive constant coefficients $\lambda_{i}$
are selected in such a way that their magnitudes reflect the length
scale of the optimization problem.

Our objective is to modify the initial simplex stage by stage so that
the resulting simplices converge toward the minimizer. At each iteration
we evaluate the function $f$ at each point of the simplex. In the
function minimization process, the point with the largest function
value is replaced with another point. The process for modifying the
simplex continues until it converges toward the function minimizer.
"""
initial_simplex = PlutoUI.details("Initial simplex construction", initial_simplex_content,open=false)

simplex_updates_content = md"""
To understand the rules for modifying the simplex stage by stage, we use a two-dimensional example. 
We begin by selecting the initial set of $n+1$ points
that are to form the initial simplex. We next evaluate $f$ at each
point and order the $n+1$ vertices to satisfy

```math
f\left(\vec{p}_{0}\right)\leq f\left(\vec{p}_{1}\right)\leq\cdots\leq f\left(\vec{p}_{n}\right)\,.
```

For the two-dimensional case we let $\vec{p}_{l}$, $\vec{p}_{n}$
and $\vec{p}_{s}$ denote the points of the simplex for which $f$
is largest, next largest and smallest. We next compute $\vec{p}_{g}$,
the _centroid_ (center of gravity) of the best $n$ points:

```math
\vec{p}_{g}=\frac{1}{n}\sum_{i=0}^{n-1}\vec{p}_{i}\,.
```

We then reflect the worst vertex, $\vec{p}_{n}$, in $\vec{p}_{g}$
using a _reflection coefficient_ $\rho>0$ to obtain the reflection
point

```math
\vec{p}_{r}=\vec{p}_{g}+\rho\left(\vec{p}_{g}-\vec{p}_{n}\right)\,.
```

A typical value is $\rho=1$. 

We proceed to evaluate $f$ at $\vec{p}_{r}$. If $f\left(\vec{p}_{0}\right)\leq f\left(\vec{p}_{r}\right)<f\left(\vec{p}_{n-1}\right)$,
then the point $\vec{p}_{r}$ replaces $\vec{p}_{l}$ to form a new
simplex and we terminate the iteration. We proceed to repeat the process.

If , however, $f\left(\vec{p}_{r}\right)<f\left(\vec{p}_{0}\right)$,
so that the point $\vec{p}_{r}$ yields the smallest function value
among the points of the simplex, we argue that this direction is a
good one. In this case we increase the distance traveled using an
_expansion coefficient_ $\chi>1$, e.g. $\chi=2$, to obtain

```math
\vec{p}_{e}=\vec{p}_{g}+\chi\left(\vec{p}_{r}-\vec{p}_{g}\right)\,.
```

This operation yields a new point on the line $\vec{p}_{n}\vec{p}_{g}\vec{p}_{r}$
extend beyond $\vec{p}_{r}$. If $f\left(\vec{p}_{e}\right)<f\left(\vec{p}_{r}\right)$,
the expansion is declared a success and $\vec{p}_{e}$ replaces $\vec{p}_{n}$
in the next simplex. If, on the other hand, $f\left(\vec{p}_{e}\right)\geq f\left(\vec{p}_{r}\right)$,
the expansion is a failure and $\vec{p}_{r}$ replaces $\vec{p}_{n}$.

Finally, if $f\left(\vec{p}_{r}\right)\geq f\left(\vec{p}_{n-1}\right)$,
the reflected point $\vec{p}_{r}$ would constitute the point with
the largest function value in the new simplex. Then in the next step
it would be reflected in $\vec{p}_{g}$, probably an unfruitful operation.
Instead, this case is dealt with by a _contraction_ operation
in one of two ways. First, if $f\left(\vec{p}_{r}\right)<f\left(\vec{p}_{n}\right)$,
then we contract $\left(\vec{p}_{r}-\vec{p}_{g}\right)$ with a _contraction
coefficient_ $0<\gamma<1$, e.g. $\gamma=\frac{1}{2}$, to obtain
```math
\vec{p}_{c}=\vec{p}_{g}+\gamma\left(\vec{p}_{r}-\vec{p}_{g}\right)\,.
```

We refer to this operation as the _outside contraction_. If,
on the other hand, $f\left(\vec{p}_{r}\right)\geq f\left(\vec{p}_{n}\right)$,
then $\vec{p}_{l}$ replaces $\vec{p}_{r}$ in the contraction operation
and we get

```math
\vec{p}_{c}=\vec{p}_{g}+\gamma\left(\vec{p}_{l}-\vec{p}_{g}\right)\,.
```

This operation is referred to as the _inside contraction_.

If , in either case, $f\left(\vec{p}_{c}\right)\leq f\left(\vec{p}_{n}\right)$,
the contraction is considered a success, and we replace $\vec{p}_{n}$
with $\vec{p}_{c}$ in the new simplex. If, however, $f\left(\vec{p}_{c}\right)>f\left(\vec{p}_{n}\right)$,
the contraction is a failure, and in this case a new simplex can be
formed by retaining $\vec{p}_{0}$ only and halving the distance from
$\vec{p}_{0}$ to every point in the simplex. We can refer to this
event as a _shrinkage operation_. In general, the shrink step
produces the $n$ new vertices of the new simplex according to the
formula

```math
\vec{v}_{i}=\vec{p}_{0}+\sigma\left(\vec{p}_{i}-\vec{p}_{0}\right)\,,\quad i=1,2,\dots,n\,,
```


where $\sigma=\frac{1}{2}$. Hence, the vertices of the new simplex
are $\vec{p}_{0},\vec{v}_{1},\dots,\vec{v}_{n}$.

When implementing the simplex algorithm, we need a tie-breaking rule
to order points in the case of equal function values. Often, the highest
possible index consistent with the relation

```math
f\left(\vec{p}_{0}\right)\leq f\left(\vec{p}_{1}\right)\leq\cdots\leq f\left(\vec{p}_{n}\right)
```

is assigned to the new vertex.

The [wikipedia page](https://en.wikipedia.org/wiki/Nelder–Mead_method) also provides a nice overview. This [simple video](https://www.youtube.com/watch?v=j2gcuRVbwR0) should also help you grasp a better understanding.
"""
simplex_updates = PlutoUI.details("Simplex update rules", simplex_updates_content)
	
PlutoUI.details("Deep dive",[simplex_basics; initial_simplex; simplex_updates], open=true)
end

# ╔═╡ a0c4e07f-504d-426e-8d9f-7a212855888f
md"""
### First-order methods

!!! info "Gradient-descent algorithm"
	Gradient descent is the simplest first-order optimizer for a smooth function in ``n`` variables.  
	At each iteration it  
	- computes the gradient ``gₖ = ∇f(xₖ)``  
	- steps downhill by ``xₖ₊₁ = xₖ − αₖ gₖ``, where the step size ``αₖ`` is chosen by a fixed “learning rate” or a line-search rule  
	The process repeats until the gradient norm (or successive position change) falls below a tolerance.  
	It needs only gradients and 𝒪(n) memory, but convergence can be slow or unstable if ``αₖ`` is poorly tuned and the objective landscape is badly scaled.

!!! info "Conjugate-gradient (CG) algorithm"
	Conjugate gradient is a memory-lean, first-order optimizer that turns plain steepest-descent into Hessian-aware progress without ever storing the Hessian. It was inspired by methods to minimise quadratic functions, but can be applied to non-quadratic functions as well.
	Starting with ``p₀ = −g₀`` (the negative gradient), at each iteration it

	- does a line-search  ``xₖ₊₁ = xₖ + αₖ pₖ``  
	- computes the new gradient ``gₖ₊₁ = ∇f(xₖ₊₁)``  
	- does direction mixing ``βₖ = (gₖ₊₁ᵀ(gₖ₊₁−gₖ)) / (gₖᵀ gₖ)`` (Polak–Ribière update)  
	- determines the new direction: ``pₖ₊₁ = −gₖ₊₁ + βₖ pₖ``  

	The formula makes successive ``p``-vectors conjugate (orthogonal in the Hessian metric), so for a true quadratic CG reaches the minimizer in ``\le n`` steps for quadratic functions.


!!! warning "Info on line seach"
	Linesearch routines attempt to locate quickly an approximate minimizer of the univariate function

	```math
	\alpha \rightarrow f\left(\vec x + \alpha \vec g\right)\,,
	```

	where $\vec g$ is the descent direction computed by the algorithm. They vary in how accurate this minimization is. Two good linesearches are BackTracking and HagerZhang, the former being less stringent than the latter. For well-conditioned objective functions and methods where the step is usually well-scaled (such as L-BFGS or Newton), a rough linesearch such as BackTracking is usually the most performant. For badly behaved problems or when extreme accuracy is needed (gradients below the square root of the machine epsilon, about ``10^{−8}`` with Float64), the HagerZhang method proves more robust. An exception is the conjugate gradient method which requires an accurate linesearch to be efficient, and should be used with the HagerZhang linesearch.

!!! warning "Info on gradient computation"
	In both first and second order methods, we need the gradient. This can be obtained in different ways:
	- analytically (cf. symbolic computation)
	- using finite differences (cf. numerical analysis course)
	- using [automatic differentiation](https://arxiv.org/pdf/1502.05767)

	All of the above can be used in `Optim.jl`.

"""

# ╔═╡ f195819d-4ca2-4f57-8fe9-17d0b57d477a
md"""
### Implementations
Within Julia, the [`Optim`](https://github.com/JuliaNLSolvers/Optim.jl) package contains a lot of different optimisation routines.

The package is very generic, and provides a unified interface:
```julia
optimize(f, x₀, Method())
```
where ```Method()``` indicates one of the available optimisation methods.

"""

# ╔═╡ 13707c2b-6eb9-4a5d-885e-39d48b3c9bae
md"""
### Second-order methods
!!! info "Newton’s method"
	Newton’s method is a second-order optimizer that uses the full curvature (Hessian) of a smooth function in ``n`` variables to jump straight toward a stationary point. At each iteration it

	- computes the gradient ``gₖ = ∇f(xₖ)`` and the Hessian ``Hₖ = ∇²f(xₖ)``  
	- solves the Newton system ``Hₖ pₖ = −gₖ`` for the search direction ``pₖ``
	- updates the parameters ``xₖ₊₁ = xₖ + αₖ pₖ``, with ``αₖ = 1`` for pure Newton or reduced by a line search/trust-region when the Hessian is indefinite or far from the minimum  

	The method obtains quadratic convergence once near the solution, so it is far faster than first-order methods. But the computation of the Hessian can be costly (or infeasible for large problems).

!!! info "BFGS"
	BFGS (Broyden–Fletcher–Goldfarb–Shanno) is a gradient-based quasi-Newton optimizer that iteratively builds up an estimate of the inverse Hessian (curvature) while it searches for a minimum of a smooth function in ``n`` variables.  
	At each iteration it

	- computes the gradient ``gₖ`` and proposes a search direction ``pₖ = −Hₖ gₖ`` using its current inverse-Hessian guess ``Hₖ``;
	- line-searches along ``pₖ`` until an Armijo/Wolfe condition is met;
	- updates curvature with the rank-two BFGS formula using  
	  ``sₖ = xₖ₊₁ − xₖ`` and ``yₖ = gₖ₊₁ − gₖ``  
	  so the next ``Hₖ₊₁`` stays positive-definite.

	This self-correcting Hessian gives nearly Newton-level steps without ever forming the true Hessian, so convergence is super-linear on smooth problems. The method needs gradient evaluations and ``𝒪(n²)`` memory, which is fine up to a few thousands of variables.


!!! info "L-BFGS"
	L-BFGS (Limited-Memory BFGS) keeps the same quasi-Newton idea but trims the storage.  
	Instead of holding the full ``n × n`` inverse-Hessian, it retains only the **last m pairs** of displacement/gradient vectors ``(sᵢ, yᵢ)`` (typically ``m = 5–20``):

	- a compact two-loop recursion reconstructs the action of ``Hₖ`` on the current gradient, yielding the search direction with just ``𝒪(n m)`` work  
	- the same line-search and vector update rules as full BFGS apply  

	The trade-off: memory and CPU scale linearly in ``n`` (making it suitable for millions of variables), but curvature information is less complete, so it may take more iterations to converge. 

	In practice L-BFGS is the default large-scale optimizer for engineering, scientific computing, and machine-learning tasks where gradients are available but forming or storing the full Hessian is impossible.




"""

# ╔═╡ 0ea96b49-8bd4-49fe-834a-b93865f5541b
md"""

### Example
!!! tip "Rosenbrock function minimisation"
	To illustrate the package's functionality, we minimize the Rosenbrock function, a classical test problem for numerical optimization, using different optimisation methods.

	```math
	\min f(\vec{x}) = (1 - x_1)^2 + 100(x_2 - x_1^2)^2
	```


"""

# ╔═╡ b1144ca2-087c-4ba7-ae77-ae9b6073a642
begin
	# function definition
	f(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2;

	# gradient
	function g!(G, x)
	    G[1] = -2.0 * (1.0 - x[1]) - 400.0 * (x[2] - x[1]^2) * x[1]
	    G[2] = 200.0 * (x[2] - x[1]^2)
	end

	# hessian
	function h!(H, x)
	    H[1, 1] = 2.0 - 400.0 * x[2] + 1200.0 * x[1]^2
	    H[1, 2] = -400.0 * x[1]
	    H[2, 1] = -400.0 * x[1]
	    H[2, 2] = 200.0
	end
end

# ╔═╡ cec44eec-ac69-47ac-9ad3-bfb58fc0a0ec
begin
	x, y, z = let
		x = -1:0.007:2
		y = -1:0.007:2
		z = Surface((x,y)->log10.(f([x,y])), x, y)
		x, y, z
	end;
	contour(x,y,z, xlabel=L"x_1", ylabel=L"x_2", title="Rosenbrock function")
end

# ╔═╡ 102e0051-dbfb-45e0-871d-db0a0d07abb1
begin
	# initial point
	x₀ = [0.0, 0.0]; 
	# try different methods
	for method in [NelderMead(), GradientDescent(), ConjugateGradient()]
		res = optimize(f, x₀, method)
		@info "Method:\n$(method)"
		@info res
	end
end

# ╔═╡ 86e70877-1f9c-4634-9f5a-94659bfab519
begin
	# perfomance assesment
	suite = BenchmarkGroup()
	suite["NelderMead"] = 				@benchmarkable optimize(f, x₀, $(NelderMead()))
	suite["GradientDescent"] = 			@benchmarkable optimize(f, x₀, $(GradientDescent()))
	suite["GradientDescent_gradient"] = @benchmarkable optimize(f, g!, x₀, $(GradientDescent()))
	suite["ConjugateGradient"] = 		@benchmarkable optimize(f, x₀, $(ConjugateGradient()))
	suite["ConjugateGradient_gradient"] = @benchmarkable optimize(f, g!, x₀, $(ConjugateGradient()))
	suite["Newton"] = 					@benchmarkable optimize(f, x₀, $(Newton()))
	suite["Newton_gradient"] = 			@benchmarkable optimize(f, g!, x₀, $(Newton()))
	suite["Newton_gradient_hessian"] = 	@benchmarkable optimize(f, g!, h!, x₀, $(Newton()))
	suite["BFGS"] = 					@benchmarkable optimize(f, x₀, $(BFGS()))
	suite["BFGS_gradient"] = 			@benchmarkable optimize(f, g!, x₀, $(BFGS()))
	suite["LBFGS"] = 					@benchmarkable optimize(f, x₀, $(LBFGS()))
	suite["LBFGS_gradient"] = 			@benchmarkable optimize(f, g!, x₀, $(LBFGS()))
	# setup the benchmark
	tune!(suite)
	# run the benchmark
	benchresult = run(suite);
	nothing
	for res in benchresult
		@info res
	end
end


# ╔═╡ d4b05c5e-ac08-4a69-b54c-5d825d864bfa
md"""
## Constrained optimisation
We now turn to constrained optimisation. In this case we have a function that needs to be minimised. Depending on the nature of the function and the constraints, we can use specific numerical solvers.

Recall from your courses in analysis that we can transform a function subject to constraint into a Lagrangian, which adds an additional unknown per equality constraint.
"""

# ╔═╡ 1450d898-5e03-4b54-a1ba-bf3d0f659d25
md"""
### Linear programming
!!! info "Definition"
	A linear program is an optimization problem of the form:
	
	```math
	\min_{\vec{x} \in \Omega } \vec{c}^\mathsf{T}\vec{x} \; \text{ subject to } 
	\cases{
	\mathbf{A}\vec x=\vec b\\
	\vec x\ge\vec 0}
	```
	where $\vec c\in\mathbb R^n$, $\vec b\in\mathbb R^m$ and $\mathbf A \in \mathbb R^{m\times n}$. 

The name "linear programming" stems from the contraints and the objective function being represented by linear relationships, so it can be considered as a special case of the more general family of optimisation problems. 
The vector inequality $\vec x\ge\vec 0$ means that each component of $\vec x$ is nonnegative. Several variations of this problem are possible; e.g. instead of minimizing, we can maximize, or the constraints may be in the form of inequalities, such as $\mathbf A\vec x\ge \vec b$ or $\mathbf A\vec x\le\vec b$. These variations can all be rewritten into the standard form by introducing slack variables.

!!! tip "Example"
	```math
	\min_{\vec{x}} x_1 +5 x_2 \; \text{ subject to } 
	\cases{
	5x_1 + 6x_2 \leq 30\\
	2x_1 + 2x_2 \leq 12\\
	x_1 \ge 0\\
	x_2 \ge 0}
	```

$(let
	x = -2:6
	p = plot(size=(400,400))
	plot!(p, x, (30 .- 5 .* x) ./ 6, linestyle=:dash, label=L"5x_1+6x_2=30")
	plot!(x, (12 .- 3 .* x) ./ 2, linestyle=:dash, label=L"3x_1+2x_2=12")
	plot!([0,4,1.5,0,0],[0,0,3.75,5,0], linewidth=2, fill=(0, :lightgreen, 0.25), label="Feasible region")
	plot!(x, -x ./ 5, line=:dash, color=:black, label=L"f\left(x_1,x_2\right)=x_1+5x_2=0")
	plot!(x, (25 .- x) ./ 5, line=:dot, color=:black, label=L"f\left(x_1,x_2\right)=x_1+5x_2=25")
end)
"""

# ╔═╡ 9e9a1b5c-a78f-414c-b99e-328e96061542
md"""
#### Simplex method

!!! info "Simplex method (for linear programming)"
	The simplex algorithm solves linear programs by moving from vertex to vertex along edges of the feasible polytope, improving (or at least not worsening) the objective each step.
	The method is guaranteed to arrive at an optimal solution if the problem is feasible and bounded.

	

	**Notes:** 
	1. For this to work, every inequality must be transformed into an equality by adding so-called slack variables. The method then starts from abasic feasible solution (a corner of the polytope).
	2. Memory and work per pivot are ``𝒪(m n)`` with dense tableaus, but sparse and revised variants scale to huge engineering and operations-research problems (with ``m`` being the number of constraints and ``n`` the number of variables).


	

"""

# ╔═╡ ff3de131-b74b-4924-aa3f-4954f4b0ecca
begin 
	simplex_detail = md"""
	The simplex method solves linear programming (LP) problems, by optimizing a linear objective function subject to linear equality and inequality constraints by moving along the boundaries (vertices) of the feasible region. For a standard LP problem:
	
	```math
	\min_{\vec{x} \in \Omega } \vec{c}^\mathsf{T}\vec{x} \; \text{ subject to } 
	\cases{
	\mathbf{A_{eq}}\vec x =  \vec b_{eq}\\
	\mathbf{A_{in}}\vec x \le \vec b_{in}\\
	\vec x\ge\vec 0}
	```
	
	where `c` is the cost vector, `A_eq` and `A_in` are constraint matrices, and `b_eq` and `b_in` are right-hand side vectors, the method proceeds as follows:
	
	1. Convert the problem into standard form by introducing slack variables for inequalities (e.g., `A_in x + s = b_in`, where `s ≥ 0`) and select an initial basic feasible solution (e.g., setting non-basic variables to 0 and solving for basic variables).
	
	2. At each step:
	   - Identify the entering variable (non-basic variable with negative reduced cost to improve the objective).
	   - Determine the leaving variable (basic variable to replace via the minimum ratio test, `b[i] / A[i,j]` where `A[i,j] > 0`).
	   - Update the basis by pivoting to reflect the new basic feasible solution.
	
	3. Continues until no entering variable reduces the objective (all reduced costs non-negative), indicating an optimal solution, or detects unboundedness if no leaving variable exists.
	

	"""
PlutoUI.details("""Deep dive - simplex method""", simplex_detail,open=false)
end

# ╔═╡ 110a345d-70dd-40eb-bc1f-1a4d4c9c1926
md"""
#### Interior point methods for linear programming
!!! info "Interior-point methods (linear programming)"
	Interior-point (IP) methods solve a linear program by "travelling through the interior" of the feasible polytope instead of walking its edges like the simplex method.  
	These methods are sometimes referred to as barrier methods, because they involve the use of a barrier function that ensures that the search points always remain feasible. 

	This barrier function needs to be continuous, nonnegative in the feasible region, and approach infinity as ``x`` approaches any constraint boundary.


"""

# ╔═╡ 22915619-cd8f-4fef-a328-3cb7ba999946
begin
	IP_for_LP = md"""
In the 1980s it was discovered that many large linear programs could
be solved efficiently by using formulations and algorithms from nonlinear
programming. One characteristic of these methods was that they required
all iterates to satisfy the inequality constraints in the problem
strictly, so they became known as _interior-point methods_. In
the 1990s, a subclass of interior-point methods known as _primal-dual
methods_ had distinguished themselves as the most efficient practical
approaches, and proved to be strong competitors to the _simplex
method_ on large problems. Recently, it has been shown that
interior-point methods are as successful for nonlinear optimization
as for linear programming. General primal-dual interior point methods
are the focus of this section.


For simplicity, we restrict our attention to convex quadratic programs,
which we write as follows:
```math
\begin{aligned}
\min_{\vec{x}}\, & f\left(\vec{x}\right)\overset{\vartriangle}{=}\frac{1}{2} \vec{x}^\mathsf{T}Q\vec{x}- \vec{c}^\mathsf{T}\vec{x}\\
\textrm{subject to}\, & \begin{cases}
A_{\textrm{eq}}\vec{x}=\vec{b}_{\textrm{eq}}\,,\\
A_{\textrm{in}}\vec{x}\leq\vec{b}_{\textrm{in}}\,,
\end{cases}
\end{aligned}
```
where ``Q`` is a symmetric and positive semidefinite ``n\times n`` matrix,
``\vec{c}\in\mathbb{R}^{n}``, ``A_{\textrm{eq}}`` is a ``m\times n`` matrix,
``\vec{b}_{\textrm{eq}}\in\mathbb{R}^{m}``, ``A_{\textrm{in}}`` is a ``p\times n``
matrix and ``\vec{b}_{\textrm{in}}\in\mathbb{R}^{p}``. Rewriting the KKT
conditions in this notation, we obtain
```math
\begin{aligned}
\vec{\mu} & \geq\vec{0}\,,\\
Q\vec{x}+ A_{\textrm{eq}}^\mathsf{T}\vec{\lambda}+ A_{\textrm{in}}^\mathsf{T}\vec{\mu}-\vec{c} & =\vec{0}\,,\\
\left(A_{\textrm{in}}\vec{x}-\vec{b}_{\textrm{in}}\right)_{j}\mu_{j} & =0\,,\quad j=1,\dots,p\,,\\
A_{\textrm{eq}}\vec{x} & =\vec{b}_{\textrm{eq}}\,,\\
A_{\textrm{in}}\vec{x} & \leq\vec{b}_{\textrm{in}}\,.
\end{aligned}
```
By introducing the slack vector ``\vec{y}\geq\vec{0}``, we can rewrite
these conditions as
```math
\begin{aligned}
\left(\vec{\mu},\vec{y}\right) & \geq\vec{0}\,,\\
Q\vec{x}+ A_{\textrm{eq}}^\mathsf{T}\vec{\lambda}+ A_{\textrm{in}}^\mathsf{T}\vec{\mu}-\vec{c} & =\vec{0}\,,\\
y_{j}\mu_{j} & =0\,,\quad j=1,\dots,p\,,\\
A_{\textrm{eq}}\vec{x}-\vec{b}_{\textrm{eq}} & =\vec{0}\,,\\
A_{\textrm{in}}\vec{x}-\vec{b}_{\textrm{in}}+\vec{y} & =\vec{0}\,.
\end{aligned}
```
Since we assume that ``Q`` is positive semidefinite, these KKT conditions
are not only necessary but also sufficient, so we can solve the convex
quadratic program by finding solutions of this system.

Primal-dual methods generate iterates that satisfy the bounds strictly; that is, ``\vec{y}>0``
and ``\vec{\mu}>0``. This property is the origin of the term interior-point.
By respecting these bounds, the methods avoid spurious solutions,
points that satisfy the system but not the bounds. Spurious solutions
abound, and do not provide useful information about real solutions,
so it makes sense to exclude them altogether. Given a current iterate
``\left(\vec{x}^{\left(k\right)},\vec{y}^{\left(k\right)},\vec{\lambda}^{\left(k\right)},\vec{\mu}^{\left(k\right)}\right)``
that satisfies ``\left(\vec{\mu}^{\left(k\right)},\vec{y}^{\left(k\right)}\right)>0``,
we can define a _complementary measure_
```math
\nu_{k}=\frac{ \left(\vec{y}^{\left(k\right)}\right)^\mathsf{T}\vec{\mu}^{\left(k\right)}}{p}\,.
```
This measure gives an indication of the desirability of the couple
``\left(\vec{\mu}^{\left(k\right)},\vec{y}^{\left(k\right)}\right)``.

We derive a path-following, primal-dual method by considering the
perturbed KKT conditions by
```math
\vec{F}\left(\vec{x}^{\left(k+1\right)},\vec{y}^{\left(k+1\right)},\vec{\lambda}^{\left(k+1\right)},\vec{\mu}^{\left(k+1\right)},\sigma_{k}\nu_{k}\right)=\begin{pmatrix}Q\vec{x}^{\left(k+1\right)}+ A_{\textrm{eq}}^\mathsf{T}\vec{\lambda}^{\left(k+1\right)}+ A_{\textrm{in}}^\mathsf{T}\vec{\mu}^{\left(k+1\right)}-\vec{c}\\
Y_{k+1}M_{k+1}\vec{1}-\sigma_{k}\nu_{k}\vec{1}\\
A_{\textrm{eq}}\vec{x}^{\left(k+1\right)}-\vec{b}_{\textrm{eq}}\\
A_{\textrm{in}}\vec{x}^{\left(k+1\right)}-\vec{b}_{\textrm{in}}+\vec{y}^{\left(k+1\right)}
\end{pmatrix}=\vec{0}\,,
```
where
```math
Y_{k+1}=\begin{pmatrix}y_{1}^{\left(k+1\right)} & 0 & \cdots & 0\\
0 & y_{2}^{\left(k+1\right)} & \ddots & 0\\
\vdots & \ddots & \ddots & 0\\
0 & 0 & 0 & y_{p}^{\left(k+1\right)}
\end{pmatrix}\,,\quad M_{k+1}=\begin{pmatrix}\mu_{1}^{\left(k+1\right)} & 0 & \cdots & 0\\
0 & \mu_{2}^{\left(k+1\right)} & \ddots & 0\\
\vdots & \ddots & \ddots & 0\\
0 & 0 & 0 & \mu_{p}^{\left(k+1\right)}
\end{pmatrix}\,,
```
and ``\sigma\in\left[0,1\right]`` is the reduction factor that we wish
to achieve in the complementary measure on one step. We call ``\sigma``
the _centering parameter_. The solution of this system for all
positive values of ``\sigma`` and ``\nu`` define the _central path_,
which is a trajectory that leads to the solution of the quadratic
program as ``\sigma\nu`` tends to zero.

By fixing ``\sigma_{k}`` and applying Newton's method to the system,
we obtain the linear system
```math
\begin{pmatrix}Q & 0 &  A_{\textrm{eq}}^\mathsf{T} &  A_{\textrm{in}}^\mathsf{T}\\
0 & M_{k} & 0 & Y_{k}\\
A_{\textrm{eq}} & 0 & 0 & 0\\
A_{\textrm{in}} & I & 0 & 0
\end{pmatrix}\begin{pmatrix}\vec{d}_{\vec{x}}^{\left(k\right)}\\
\vec{d}_{\vec{y}}^{\left(k\right)}\\
\vec{d}_{\vec{\lambda}}^{\left(k\right)}\\
\vec{d}_{\vec{\mu}}^{\left(k\right)}
\end{pmatrix}=-\begin{pmatrix}Q\vec{x}^{\left(k\right)}+ A_{\textrm{eq}}^\mathsf{T}\vec{\lambda}^{\left(k\right)}+ A_{\textrm{in}}^\mathsf{T}\vec{\mu}^{\left(k\right)}-\vec{c}\\
Y_{k}M_{k}\vec{1}-\sigma_{k}\nu_{k}\vec{1}\\
A_{\textrm{eq}}\vec{x}^{\left(k\right)}-\vec{b}_{\textrm{eq}}\\
A_{\textrm{in}}\vec{x}^{\left(k\right)}-\vec{b}_{\textrm{in}}+\vec{y}^{\left(k\right)}
\end{pmatrix}\,.
```
We obtain the next iterate by setting
```math
\begin{pmatrix}\vec{x}^{\left(k+1\right)}\\
\vec{y}^{\left(k+1\right)}\\
\vec{\lambda}^{\left(k+1\right)}\\
\vec{\mu}^{\left(k+1\right)}
\end{pmatrix}=\begin{pmatrix}\vec{x}^{\left(k\right)}\\
\vec{y}^{\left(k\right)}\\
\vec{\lambda}^{\left(k\right)}\\
\vec{\mu}^{\left(k\right)}
\end{pmatrix}+\alpha_{k}\begin{pmatrix}\vec{d}_{\vec{x}}^{\left(k\right)}\\
\vec{d}_{\vec{y}}^{\left(k\right)}\\
\vec{d}_{\vec{\lambda}}^{\left(k\right)}\\
\vec{d}_{\vec{\mu}}^{\left(k\right)}
\end{pmatrix}\,,
```
where ``\alpha_{k}`` is chosen to retain the bounds ``\left(\vec{\mu}^{\left(k+1\right)},\vec{y}^{\left(k+1\right)}\right)>0``
and possibly to satisfy various other conditions.

The choices of centering parameter ``\sigma_{k}`` and step-length ``\alpha_{k}``
are crucial for the performance of the method. Techniques for controlling
these parameters, directly and indirectly, give rise to a wide variety
of methods with diverse properties. One option is to use equal step
length for the primal and dual updates, and to set ``\alpha_{k}=\min\left\{ \alpha_{k}^{\textrm{pri}},\alpha_{k}^{\textrm{dual}}\right\} ``,
where
```math
\begin{aligned}
\alpha_{k}^{\textrm{pri}} & =\max\left\{ \alpha\in\left\{ 0,1\right\} :\vec{y}^{\left(k\right)}+\alpha\vec{d}_{\vec{y}}^{\left(k\right)}\geq\left(1-\tau\right)\vec{y}^{\left(k\right)}\right\} \,,\\
\alpha_{k}^{\textrm{dual}} & =\max\left\{ \alpha\in\left\{ 0,1\right\} :\vec{\mu}^{\left(k\right)}+\alpha\vec{d}_{\vec{\mu}}^{\left(k\right)}\geq\left(1-\tau\right)\vec{\mu}^{\left(k\right)}\right\} \,,
\end{aligned}
```
the parameter ``\tau\in\left]0,1\right[`` controls how far we back
off from the maximum step for which the conditions ``\vec{y}^{\left(k\right)}+\alpha\vec{d}_{\vec{y}}^{\left(k\right)}\geq\vec{0}``
and ``\vec{\mu}^{\left(k\right)}+\alpha\vec{d}_{\vec{\mu}}^{\left(k\right)}\geq\vec{0}``
are satisfied. A typical value of ``\tau=0.995`` and we can choose
``\tau_{k}`` to approach ``1`` as the iterates approach the solution,
to accelerate the convergence.

The most popular interior-point method for convex QP is based on Mehrotra's
predictor-corrector. First we compute an affine scaling step ``\left(\vec{d}_{\vec{x},\textrm{aff}},\vec{d}_{\vec{y},\textrm{aff}},\vec{d}_{\vec{\lambda},\textrm{aff}},\vec{d}_{\vec{\mu},\textrm{aff}}\right)``
by setting ``\sigma_{k}=0``. We improve upon this step by computing
a corrector step. Next, we compute the centering parameter ``\sigma_{k}``
using following heuristic
```math
\sigma_{k}=\left(\frac{\nu_{\textrm{aff}}}{\nu_{k}}\right)^{3}\,,
```
where ``\nu_{\textrm{aff}}=\frac{ \left(\vec{y}_{\textrm{aff}}\right)^\mathsf{T}\left(\vec{\mu}_{\textrm{aff}}\right)}{p}``.
The total step is obtained by solving the following system
```math
\begin{pmatrix}Q & 0 &  A_{\textrm{eq}}^\mathsf{T} &  A_{\textrm{in}}^\mathsf{T}\\
0 & M_{k} & 0 & Y_{k}\\
A_{\textrm{eq}} & 0 & 0 & 0\\
A_{\textrm{in}} & I & 0 & 0
\end{pmatrix}\begin{pmatrix}\vec{d}_{\vec{x}}^{\left(k\right)}\\
\vec{d}_{\vec{y}}^{\left(k\right)}\\
\vec{d}_{\vec{\lambda}}^{\left(k\right)}\\
\vec{d}_{\vec{\mu}}^{\left(k\right)}
\end{pmatrix}=-\begin{pmatrix}Q\vec{x}^{\left(k\right)}+ A_{\textrm{eq}}^\mathsf{T}\vec{\lambda}^{\left(k\right)}+ A_{\textrm{in}}^\mathsf{T}\vec{\mu}^{\left(k\right)}-\vec{c}\\
Y_{k}M_{k}\vec{1}+\Delta Y_{\textrm{aff}}\Delta M_{\textrm{aff}}\vec{1}-\sigma_{k}\nu_{k}\vec{1}\\
A_{\textrm{eq}}\vec{x}^{\left(k\right)}-\vec{b}_{\textrm{eq}}\\
A_{\textrm{in}}\vec{x}^{\left(k\right)}-\vec{b}_{\textrm{in}}+\vec{y}^{\left(k\right)}
\end{pmatrix}\,,
```
where
```math
\Delta Y_{\textrm{aff}}=Y_{\textrm{aff}}-Y_{k}\,,\quad\Delta M_{\textrm{aff}}=M_{\textrm{aff}}-M_{k}\,.
```
	"""
	PlutoUI.details("""Deep dive - interior point method""", IP_for_LP, open=false)
end

# ╔═╡ a768a6d1-b9af-4c42-877b-9eb55cdee7d8
md"""
#### Implementations
In Julia, the [`JuMP package`](https://jump.dev/JuMP.jl/stable/) is a domain-specific modeling language for mathematical optimization. It supports different open-source and commercial solvers for a variety of problem classes, including linear, mixed-integer, second-order conic, semidefinite, and nonlinear programming. This allows you to use the same overal interface to solve different kinds of problems or even to try different solvers on the same problem without having to change the problem's syntax.
"""

# ╔═╡ 65ad9943-df85-43b2-aa28-f6e91da11e83
md"""
!!! tip "Example"
	Suppose we want to solve the following problem
	```math
	\min -4x_1 - 2x_2 \; \text{ subject to } \; 
	\cases{
	x_1 + x_2 \le 5 \\
	2x_1 + x_2/2 \le 8 \\
	x_1 \ge 0 \\
	x_2 \ge 0
	}
	```

	**Note**: you don't need to transform the problem into the standard form, JuMP takes care of that for you.
"""

# ╔═╡ b0d7d73b-49ba-45f6-9547-72b47c1f51ba
# Create the plot
let
	x = 0:6
    # Plot constraint lines
    p = plot(x, 5 .- x, linestyle=:dash, label=L"x_1 + x_2 = 5")
    plot!(x, 16 .- 4 .* x, linestyle=:dash, label=L"2x_1 + \frac{x_2}{2} = 8")
    
    # Plot feasible region (vertices: (0,0), (0,5), (11/3,4/3), (4,0))
    plot!([0, 0, 11/3, 4, 0], [0, 5, 4/3, 0, 0], fill=(0, :lightgreen, 0.25), label="Feasible Region", linewidth=2)
    
    # Plot objective function level curves (z = -10, z = -20)
    plot!(x, (4 .* x .- 10) ./ (-2), line=:dot, color=:black, label=L"z : -4x_1 - 2x_2 = -10")
    plot!(x, (4 .* x .- 20) ./ (-2), line=:dash, color=:black, label=L"z = -4x_1 - 2x_2 = -20")

	scatter!([3.66666],[1.33333], marker=:circle, markerfillalpha=0.0,label="Optimum", markercolor=RGBA(1, 1, 1, 0))
    # Add formatting
    plot!(xlabel=L"x_1", ylabel=L"x_2", title="")
    plot!(xlims=(-0.1, 6), ylims=(-0.1, 6), aspect_ratio=:equal, legend=:outertopright, legendfontsize=10)
    p
end

# ╔═╡ 1af7b9e6-43e0-4f32-b0bc-2bd5edd52c8a
md"""
##### Simplex method-based solver

The [GLPK solver](https://www.gnu.org/software/glpk/) is an open-source solver that can solve large-scale linear programming problems. It can use the simplex method (among others) that was mentioned before. In Julia, this solver is made available through the [`GLPK.jl`](https://github.com/jump-dev/GLPK.jl) package, which simply acts as a wrapper for the GLPK solver (which is written in C).
"""

# ╔═╡ 8784b29e-52be-4233-aec7-109e3233fecb
begin
	m = let
	# define a JuMP model that will use the GLPK optimizer, which by default uses the simplex method
	model = Model(GLPK.Optimizer)
	# define our variables
	@variable(model, x1 >= 0)
	@variable(model, x2 >= 0)
	# define the objective function
	@objective(model, Min, -4*x1 -2*x2)
	# add the constraints
	@constraint(model, con1, x1 + x2 <= 5)
	@constraint(model, con2, 2*x1 + 0.5*x2 <= 8)
	# show the model
	@info "Our model:\n $(model)"
	# determine the solution
	optimize!(model)
	# why did the solver stop?
	@info termination_status(model)
	# what is the objective function's value?
	@info "Objective function value: $(objective_value(model))"
	# show the solution
	@info "Solution:\n - x₁ : $(value(x1))\n - x₂ : $(value(x2))	"
	model
end
	nothing
end

# ╔═╡ 84d6d961-d5a7-4ebb-a1f5-f79f4dad19a4
md"""
##### Interior point-based solver

The Julia package [`Tulip`](https://github.com/ds4dm/Tulip.jl) is an interior-point solver that can be used for linear programming problems.
"""

# ╔═╡ f827a728-8111-4b7e-a8b0-821dc6454688
let
	m_ip = let
	# define a JuMP model that will use the GLPK optimizer, which by default uses the simplex method
	model = Model(Tulip.Optimizer)
	# define our variables
	@variable(model, x1 >= 0)
	@variable(model, x2 >= 0)
	# define the objective function
	@objective(model, Min, -4*x1 -2*x2)
	# add the constraints
	@constraint(model, con1, x1 + x2 <= 5)
	@constraint(model, con2, 2*x1 + 0.5*x2 <= 8)
	# show the model
	@info "Our model:\n $(model)"
	# determine the solution
	optimize!(model)
	# why did the solver stop?
	@info termination_status(model)
	# what is the objective function's value?
	@info "Objective function value: $(objective_value(model))"
	# show the solution
	@info "Solution:\n - x₁ : $(value(x1))\n - x₂ : $(value(x2))	"
	model
end
	nothing
end

# ╔═╡ 1e31e88d-265f-4de6-bd98-8465ddb5cb5a
md"""
#### Example applications
##### Economy

A manufacturer produces  four different  products  $X_1$, $X_2$, $X_3$ and $X_4$. There are three inputs to this production process:

- labor in man weeks,  
- kilograms of raw material A, and 
- boxes  of raw  material  B.

Each product has different input requirements. In determining each  week's production schedule, the manufacturer cannot use more than the available amounts of  manpower and the two raw  materials:

|Inputs|$X_1$|$X_2$|$X_3$|$X_4$|Availabilities|
|------|-----|-----|-----|-----|--------------|
|Person-weeks|1|2|1|2|20|
|Kilograms of material A|6|5|3|2|100|
|Boxes of material B|3|4|9|12|75|
|Production level|$x_1$|$x_2$|$x_3$|$x_4$| |

These constraints can be written in mathematical form

```math
\begin{aligned}
x_1+2x_2+x_3+2x_4\le&20\\
6x_1+5x_2+3x_3+2x_4\le&100\\
3x_1+4x_2+9x_3+12x_4\le&75
\end{aligned}
```

Because negative production levels are not meaningful, we must impose the following nonnegativity constraints on the production levels:

```math
x_i\ge0,\qquad i=1,2,3,4
```

Now suppose that one unit of product $X_1$ sells for €6 and $X_2$, $X_3$ and $X_4$ sell for €4, €7 and €5, respectively. Then, the total revenue for any production decision $\left(x_1,x_2,x_3,x_4\right)$ is

```math
f\left(x_1,x_2,x_3,x_4\right)=6x_1+4x_2+7x_3+5x_4
```

The problem is then to maximize $f$ subject to the given constraints.
"""

# ╔═╡ 12bfc573-4b38-499f-89c0-49e6ea70759f
let
	model = Model(GLPK.Optimizer)
	@variable(model, 0 <= x1, Int)
	@variable(model, 0 <= x2, Int)
	@variable(model, 0 <= x3, Int)
	@variable(model, 0 <= x4, Int)
	@objective(model, Max, 6*x1 + 4*x2 + 7*x3 + 5*x4)
	@constraint(model, con1,   x1 + 2*x2 +   x3 +  2*x4 <= 20)
	@constraint(model, con2, 6*x1 + 5*x2 + 3*x3 +  2*x4 <= 100)
	@constraint(model, con3, 3*x1 + 4*x2 + 9*x3 + 12*x4 <= 75)
	optimize!(model)
	termination_status(model), primal_status(model), [value(x1), value(x2), value(x3), value(x4)], objective_value(model)
end

# ╔═╡ 484fd731-6add-4f8f-a897-0f0b5d48d7aa
md"""##### Manufacturing

A manufacturer produces two different products $X_1$ and $X_2$ using three machines $M_1$, $M_2$, and $M_3$. Each machine can be used only for a limited amount of time. Production times of each product on each machine are given by 

|Machine|Production time $X_1$|Production time $X_2$|Available time|
|-------|---------------------|---------------------|--------------|
|$M_1$  |1                    |1                    |8             |
|$M_2$  |1                    |3                    |18            |
|$M_3$  |2                    |1                    |14            |
|Total  |4                    |5                    |              |

The objective is to maximize the combined time of utilization of all three machines.

Every production decision must satisfy the constraints on the available time. These restrictions can be written down using data from the table.

```math
\begin{aligned}
x_1+x_2&\le8\,,\\
x_1+3x_2&\le18\,,\\
2x_1+x_2&\le14\,,
\end{aligned}
```

where $x_1$ and $x_2$ denote the production levels. The combined production time of all three machines is

```math
f\left(x_1,x_2\right)=4x_1+5x_2\,.
```"""

# ╔═╡ 232fc07c-ed6d-4287-8dac-a0f7e10756fc
let
	model = Model(GLPK.Optimizer)
	@variable(model, 0 <= x1)
	@variable(model, 0 <= x2)
	@objective(model, Max, 4*x1 + 5*x2)
	@constraint(model, con1,   x1 +   x2 <= 8)
	@constraint(model, con2,   x1 + 3*x2 <= 18)
	@constraint(model, con3, 2*x1 +   x2 <= 14)
	optimize!(model)
	termination_status(model), primal_status(model), [value(x1), value(x2)], objective_value(model)
end

# ╔═╡ c09cb716-15b6-41d1-a016-cf76b5b7efaf
md"""##### Transportation

A manufacturing company has plants in cities A, B, and C. The company produces and distributes its product to dealers in various cities. On a particular day, the company has 30 units of its product in A, 40 in B, and 30 in C. The company plans to ship 20 units to D, 20 to E, 25 to F, and 35 to G, following orders received from dealers. The transportation costs per unit of each product between the cities are given by

|From|To D|To E|To F|To G|Supply|
|----|----|----|----|----|------|
|A   |7   |10  |14  |8   |30    |
|B   |7   |11  |12  |6   |40    |
|C   |5   |8   |15  |9   |30    |
|Demand|20|20  |25  |35  |100   |

In the table, the quantities supplied and demanded appear at the right and along the bottom of the table. The quantities to be transported from the plants to different destinations are represented by the decision variables.

This problem can be stated in the form:

```math
\min 7x_{AD}+10x_{AE}+14x_{AF}+8x_{AG}+7x_{BD}+11x_{BE}+12x_{BF}+6x_{BG}+5x_{CD}+8x_{CE}+15x_{CF}+9x_{CG}
```

subject to

```math
\begin{aligned}
x_{AD}+x_{AE}+x_{AF}+x_{AG}&=30\\
x_{BD}+x_{BE}+x_{BF}+x_{BG}&=40\\
x_{CD}+x_{CE}+x_{CF}+x_{CG}&=30\\
x_{AD}+x_{BD}+x_{CD}&=20\\
x_{AE}+x_{BE}+x_{CE}&=20\\
x_{AF}+x_{BF}+x_{CF}&=25\\
x_{AG}+x_{BG}+x_{CG}&=35
\end{aligned}
```

In this problem, one of the constraint equations is redundant because it can be derived from the rest of the constraint equations. The mathematical formulation of the transportation problem is then in a linear programming form with twelve (3x4) decision variables and six (3 + 4 - 1) linearly independent constraint equations. Obviously, we also require nonnegativity of the decision variables, since a negative shipment is impossible and does not have any valid interpretation."""

# ╔═╡ 12699940-fa1c-454a-9692-11f5c3e97909
let
	model = Model(GLPK.Optimizer)
	@variable(model, 0 <= x[1:3,1:4])
	@objective(model, Min, 7x[1,1]+10x[1,2]+14x[1,3]+8x[1,4]+7x[2,1]+11x[2,2]+12x[2,3]+6x[2,4]+5x[3,1]+8x[3,2]+15x[3,3]+9x[3,4])
	@constraint(model, con1, sum(x[1,j] for j in 1:4) == 30)
	@constraint(model, con2, sum(x[2,j] for j in 1:4) == 40)
	@constraint(model, con3, sum(x[3,j] for j in 1:4) == 30)
	@constraint(model, con4, sum(x[i,1] for i in 1:3) == 20)
	@constraint(model, con5, sum(x[i,2] for i in 1:3) == 20)
	@constraint(model, con6, sum(x[i,3] for i in 1:3) == 25)
	@constraint(model, con7, sum(x[i,4] for i in 1:3) == 35)
	optimize!(model)
	termination_status(model), primal_status(model), value.(x), objective_value(model)
end

# ╔═╡ 5f685c6b-6177-4992-86aa-f788d2727217
md"""This problem is an _integer linear programming_ problem, i.e. the solution components must be integers.

We can use the simplex method to find a solution to an ILP problem if the $m\times n$ matrix $A$ is unimodular, i.e. if all its nonzero $m$th order minors are $\pm 1$.

Should this not be the case, you can always impose a constraint on `x` to be integer. In doing so, you will (unkowingly) select a different solver for the problem.
"""

# ╔═╡ 242719f3-2191-4e7f-878b-5fc7fe6f5080
let
	model = Model(GLPK.Optimizer)
	# specify that we need integer values
	@variable(model, 0 <= x[1:3,1:4], Int)
	@objective(model, Min, 7x[1,1]+10x[1,2]+14x[1,3]+8x[1,4]+7x[2,1]+11x[2,2]+12x[2,3]+6x[2,4]+5x[3,1]+8x[3,2]+15x[3,3]+9x[3,4])
	@constraint(model, con1, sum(x[1,j] for j in 1:4) == 30)
	@constraint(model, con2, sum(x[2,j] for j in 1:4) == 40)
	@constraint(model, con3, sum(x[3,j] for j in 1:4) == 30)
	@constraint(model, con4, sum(x[i,1] for i in 1:3) == 20)
	@constraint(model, con5, sum(x[i,2] for i in 1:3) == 20)
	@constraint(model, con6, sum(x[i,3] for i in 1:3) == 25)
	@constraint(model, con7, sum(x[i,4] for i in 1:3) == 35)
	optimize!(model)
	termination_status(model), primal_status(model), value.(x), objective_value(model)
end

# ╔═╡ 1a29e47e-8495-4eca-95ea-971661fc615b
md"""##### Electricity

An electric circuit is designed to use a 30 V source to charge 10 V, 6 V, and 20 V batteries connected in parallel. Physical constraints limit the currents $I_1$, $I_2$, $I_3$, $I_4$, and $I_5$ to a maximum of 4 A, 3 A, 3 A, 2 A, and 2 A, respectively. In addition, the batteries must not be discharged, that is, the currents $I_1$, $I_2$, $I_3$, $I_4$, and $I_5$ must not be negative. We wish to find the values of the currents $I_1$, $I_2$, $I_3$, $I_4$, and $I_5$ such that the total power transferred to the batteries is maximized.

The total power transferred to the batteries is the sum of the powers transferred to each battery, and is given by $10I_2 + 6I_4 + 20I_5$ W. From the circuit, we observe that the currents satisfy the constraints $I_1 = I_2 + I_3$, and $I_3 = I_4 + I_5$. Therefore, the problem can be posed as the following linear program:

```math
\max 10I_2+6I_4+20I_5
```

subject to

```math
\begin{aligned}
I_1 &= I_2 + I_3\\
I_3 &= I_4 + I_5\\
I_1 &\le 4\\
I_2 &\le 3\\
I_3 &\le 3\\
I_4 &\le 2\\
I_5 &\le 2
\end{aligned}
```

"""

# ╔═╡ dc757906-2b34-4341-96ad-237a3cfcbfeb
let
	model = Model(GLPK.Optimizer)
	@variable(model, 0 <= I[1:5])
	@objective(model, Max, 10*I[2]+6*I[4]+20I[5])
	@constraint(model, con1, I[1] == I[2] + I[3])
	@constraint(model, con2, I[3] == I[4] + I[5])
	@constraint(model, con3, I[1] <= 4)
	@constraint(model, con4, I[2] <= 3)
	@constraint(model, con5, I[3] <= 3)
	@constraint(model, con6, I[4] <= 2)
	@constraint(model, con7, I[5] <= 2)
	optimize!(model)
	termination_status(model), primal_status(model), value.(I), objective_value(model)
end

# ╔═╡ b3fd0b39-ca17-49e5-adec-552a69e386f8
md"""
##### Other
Resource allocations problems typically can be written as a linear programming problem (e.g. exam roster planning, timetable planning, room allocations...)

The main challenge often is getting a full understanding of the situation, including all implicit constraints.
"""

# ╔═╡ ce5cea4c-17a0-4c12-b2f0-3b2ba705954e
md"""
### Quadratic progamming
!!! info "Quadratic progam"
	An optimization problem with a quadratic objective function and linear
	constraints is called a _quadratic program_. Problems of this
	type are important in their own right, and they also arise a subproblems
	in methods for general constrained optimization such as sequential
	quadratic programming and interior-point methods.
	
	The general quadratic program can be stated as
	
	```math
	\begin{aligned}
	\min_{\vec{x}}\, & f\left(\vec{x}\right)\overset{\vartriangle}{=}\frac{1}{2}\vec{x}^\mathsf{T}Q\vec{x}-\vec{c}^\mathsf{T}\vec{x}\\
	\textrm{subject to}\, & \begin{cases}
	A_{\textrm{eq}}\vec{x}=\vec{b}_{\textrm{eq}}\,,\\
	A_{\textrm{in}}\vec{x}\leq\vec{b}_{\textrm{in}}\,,
	\end{cases}
	\end{aligned}
	```
	
	where $Q$ is a symmetric $n\times n$ matrix, $\vec{c}\in\mathbb R^{n}$,
	$A_{\textrm{eq}}$ is a $m\times n$ matrix, $\vec{b}_{\textrm{eq}}\in\mathbb R^{m}$,
	$A_{\textrm{in}}$ is a $p\times n$ matrix and $\vec{b}_{\textrm{in}}\in\mathbb R^{p}$.
	If the Hessian matrix $Q$ is positive semidefinite, we have a convex
	quadratic program. Non-convex quadratic programs, in which $Q$ is
	an indefinite matrix, can be more challenging because they have several
	stationary points and local minima.
"""

# ╔═╡ 5819029f-796f-43ff-a079-5fa95b3fb011
begin
	QP_EC = md"""
We consider the following equality-constrained quadratic problem:
```math
\begin{aligned}
\min_{\vec{x}}\, & f\left(\vec{x}\right)\overset{\vartriangle}{=}\frac{1}{2} \vec{x}^\mathsf{T}Q\vec{x}- \vec{c}^\mathsf{T}\vec{x}\\
\textrm{subject to}\, & A\vec{x}=\vec{b}\,,\nonumber 
\end{aligned}
```
where $A$ is the $m\times n$ Jacobian of constraints and $\vec{b}\in\mathbb R^{m}$.
We assume that $A$ has rank $m$ so that the constraints are consistent.

The First Order Necessary Condition (FONC) uses the Langrangian function
```math
\mathcal L\left(\vec x, \vec \lambda\right)=\vec{x}^\mathsf{T}Q\vec{x}- \vec{c}^\mathsf{T}\vec{x} + \vec\lambda^\mathsf{T} \left(A\vec{x}-\vec{b}\right)
```
and gives the following condition
```math
\begin{aligned}
\nabla_{\vec x}\mathcal L\left(\vec x ^\star, \vec \lambda ^\star\right)&=\vec 0\,,\\
\nabla_{\vec \lambda}\mathcal L\left(\vec x ^\star, \vec \lambda ^\star\right)&=\vec 0\,,
\end{aligned}
```
So the FONC for $\vec{x}^{\star}$ to be a solution of the quadratic
problem yields a vector $\vec{\lambda}^{\star}$ such
that the following system of equations is satisfied:
```math
\begin{pmatrix}Q & A^\mathsf{T}\\
A & 0
\end{pmatrix}\begin{pmatrix}\vec{x}^{\star}\\
\vec{\lambda}^{\star}
\end{pmatrix}=\begin{pmatrix}\vec{c}\\
\vec{b}
\end{pmatrix}\,.
```
This system can be solved directly by factorization. An alternative
is to use an iterative method.

**Example**
Consider the quadratic programming problem

```math
\begin{aligned}
\min_{\vec{x}}\, & \frac{1}{2} \vec{x}^\mathsf{T}\begin{pmatrix}6 & 2 & 1\\
2 & 5 & 2\\
1 & 2 & 4
\end{pmatrix}\vec{x}- \begin{pmatrix}8\\
3\\
3
\end{pmatrix}^\mathsf{T}\vec{x}\\
\textrm{subject to}\, & \begin{pmatrix}1 & 0 & 1\\
0 & 1 & 1
\end{pmatrix}\vec{x}=\begin{pmatrix}3\\
0
\end{pmatrix}\,.
\end{aligned}
```
		
```julia
let
	Q = [6 2 1
     	 2 5 2
         1 2 4]
	c = [8, 3, 3]
	A = [1 0 1
		 0 1 1]
	b = [3, 0]
	sol = [Q transpose(A)
		   A zeros(2,2)] \ [c; b]
	@info \"\"\"solution 
	 - x: $(sol[1:3]), 
	 - λ: $(sol[4:5])
	 - f: $(1/2 * sol[1:3]' * Q * sol[1:3] - c' * sol[1:3] )\"\"\"
end
```
```
solution 
- x: [2.0, -1.0, 1.0000000000000002], 
- λ: [-3.0000000000000004, 1.9999999999999996]
- f: -3.4999999999999982
```
"""
	PlutoUI.details("""Deep dive - equality constraints""", [QP_EC],open=false)
end

# ╔═╡ c0d3cda6-2506-40be-8fa1-51c604d7f548
md"""
When dealing with inequality constraints, we can use active-set methods: these find a step from one iterate to the next by solving a quadratic subproblem in which some of the inequality constraints, and all the equality constraints are imposed as equalities. 

"""

# ╔═╡ 5ec1071f-cfaf-404a-a468-efd0f76d709e
begin
	QP_AS_Ex = PlutoUI.details("Detailed example", md"""
We apply the active-set method to the following problem:
```math
\begin{aligned}
\min_{\vec{x}}\, & f\left(\vec{x}\right)=\left(x_{1}-1\right)^{2}+\left(x_{2}-2.5\right)^{2}\\
\textrm{subject to}\, & \begin{cases}
-x_{1}+2x_{2}-2\leq0\,,\\
x_{1}+2x_{2}-6\leq0\,.\\
x_{1}-2x_{2}-2\leq0\,,\\
-x_{1}\leq0\,,\\
-x_{2}\leq0\,.
\end{cases}
\end{aligned}
```
```julia
begin
	# identifying the problem's characteristic elements
	Q = Float64[2 0
                0 2]
	c = Float64[2, 5]
	A = Float64[-1  2
				 1  2
				 1 -2
				-1  0
				 0 -1]
	b = Float64[2, 6, 2, 0, 0]
	nothing
end
```
An illustration of the function values and the feasible domain is shown below:
						   
$(let
# identifying the problem's characteristic elements
Q = Float64[2 0
0 2]
c = Float64[2, 5]
A = Float64[-1  2
1  2
1 -2
-1  0
0 -1]
b = Float64[2, 6, 2, 0, 0]

# Plot				
x = -1:0.05:5
y = -1:0.05:5
z = Surface((x,y)->(0.5 .* [x y]*Q*[x;y] .- transpose(c)*[x;y] .+ 0.5 .* transpose(c)*Q*c)[1], x, y)
contour(x, y, z, levels=35)
plot!(x, (2 .+ x) ./ 2, linestyle=:dash, label=L"-x_1+2x_2-2≤ 0")
plot!(x, (6 .- x) ./ 2, linestyle=:dash, label=L"x_1+2x_2-6≤ 0")
plot!(x, (2 .- x) ./ -2, linestyle=:dash, label=L"x_1-2x_2-2≤ 0")
plot!([0,2,4,2,0,0],[0,0,1,2,1,0], linewidth=2, label="feasible domain", xlabel=L"x_1", ylabel=L"x_2", title=L"f : (x_1 - 1)^2 + (x_2 - 2.5)^2")
end)


We refer the constraints, in order, by indices ``1`` through ``5``.

For this problem it is easy to determine a feasible initial point;
say ``\vec{x}^{\left(0\right)}=\begin{pmatrix}2 & 0\end{pmatrix}^{\mathsf{T}}``.

Constraints ``3`` and ``5`` are active at this point, and we set ``W_{0}=\left\{ 3,5\right\} ``.
Note that we could just as validly have chosen ``W_{0}=\left\{ 5\right\} ``
or ``W_{0}=\left\{ 3\right\} `` or even ``W_{0}=\emptyset``. Each choice
would lead the algorithm to perform somewhat differently.

```julia
x₀ = [2, 0]
let x = x₀
	g = Q*x - c
	ain = [reshape(A[3,:], 1, 2); reshape(A[5,:], 1, 2)]
	sol = [Q transpose(ain)
		   ain zeros(2,2)] \ [-g; 0; 0]
end					   
```

Since ``\vec{x}^{\left(0\right)}`` lies on a vertex of the feasible
region, it is obviously a minimizer of the objective function ``f``
with respect to the working set ``W_{0}``; that is, the solution of
the subproblem with ``k=0`` is ``\vec{d}^{\left(0\right)}=\vec{0}``.
We can then find the multipliers ``\mu_{3}^{\circ}`` and ``\mu_{5}^{\circ}``
associated with the active constraints. Substitution of the data from
our problem yields
```math
\begin{pmatrix}-1\\
2
\end{pmatrix}\lambda_{3}^{\circ}+\begin{pmatrix}0\\
1
\end{pmatrix}\lambda_{5}^{\circ}=\begin{pmatrix}2\\
-5
\end{pmatrix}\,,
```
which has solution ``\lambda_{3}^{\circ}=-2`` and ``\lambda_{5}^{\circ}=-1``. 

We now remove constraint ``3`` from the working set, because it has
the most negative multiplier, and set ``W_{1}=\{5\}``.

```julia
sol₁ = let x = x₀
	g = Q*x - c
	ain = reshape(A[5,:], 1, 2)
	sol = [Q transpose(ain)
		   ain zeros(1,1)] \ [-g; 0]
end
```
```
sol₁ = [-1.2, 0.0, -5.0]
```

We begin iteration ``1`` by finding the solution of the subproblem for ``k=1``, which is
``\vec{d}^{\left(1\right)}= \begin{pmatrix}-1 & 0\end{pmatrix}^\mathsf{T}``.

```julia
α₁, d₁ = let x = x₀
	d = sol₁[1:2]
	α = min(1.0, [(reshape(A[j,:], 1, 2) * d)[1,1] ≤ 0 ? 1.0 : ((b[j] .- reshape(A[j,:], 1, 2) * x) / (reshape(A[j,:], 1, 2) * d))[1,1] for j in (1,2,3,4)]...)
	α, d
end
```			
```
(1.0, [-1.0, 0.0])
```


The step-length formula yields ``\alpha_{1}=1``, and the new iterate
is ``\vec{x}^{\left(2\right)}=\begin{pmatrix}1 & 0\end{pmatrix}^\mathsf{T}``. There are no blocking constraints, so that ``W_{2}=W_{1}=\left\{ 5\right\}``

```julia
x₁ = x₀ + α₁ .* d₁ # [1.0, 0.0]
sol₂ = let x = x₁
	g = Q*x - c
	ain = reshape(A[5,:], 1, 2)
	sol = [Q transpose(ain)
		   ain zeros(1,1)] \ [-g; 0]
end						   
```		
```
sol₂ = [0.0, 0.0, -5.0]
```

We find at the start of iteration ``2`` that the solution of the
subproblem is ``\vec{d}^{\left(2\right)}=\vec{0}``. We deduce that
the Lagrange multiplier for the lone working constraint is ``\lambda_{5}^{\circ}=-5``,
so we drop the working set to obtain ``W_{3}=\emptyset``.						   

```julia
x₂ = x₁ # [1.0, 0.0]
sol₃ = let x = x₂
	g = Q*x - c
	sol = Q \ (-g)
end				   
```		
```
sol₃ = [-0.0, 2.5]
```				

Iteration ``3`` starts by solving the unconstrained problem, to obtain
the solution ``\vec{d}^{\left(3\right)}=\begin{pmatrix}0 & 2.5\end{pmatrix}^\mathsf{T}``.	

```julia
α₃, d₃ = let x = x₂
	d = sol₃[1:2]
	α = min(1.0, [(reshape(A[j,:], 1, 2) * d)[1,1] ≤ 0 ? 1.0 : ((b[j] .- reshape(A[j,:], 1, 2) * x) / (reshape(A[j,:], 1, 2) * d))[1,1] for j in (1,2,3,4,5)]...)
	α, d
end
```						   
```
(0.6, [-0.0, 2.5])
```
The step-length formula yields a step length of ``\alpha_{3}=0.6``
and a new iterate ``\vec{x}^{\left(4\right)}=\begin{pmatrix}1 & 1.5\end{pmatrix}^\mathsf{T}``. There
is a single blocking constraint (constraint ``1``), so we obtain ``W_{4}=\left\{ 1\right\}``.						   

```julia
x₃ = x₂ + α₃ .* d₃ # [1.0, 1.5]
sol₄ = let x=x₃
	g = Q*x - c
	ain = reshape(A[1,:], 1, 2)
	sol = [Q transpose(ain)
		   ain zeros(1,1)] \ [-g; 0]
end
```						   
```
[0.4, 0.2, 0.8]
```
The solution of the subproblem for ``k=4`` is then ``\vec{d}^{\left(4\right)}=\begin{pmatrix}0.4 & 0.2\end{pmatrix}^\mathsf{T}``.						   

```julia
α₄, d₄ = let x = x₃
	d = sol₄[1:2]
	α = min(1.0, [(reshape(A[j,:], 1, 2) * d)[1,1] ≤ 0 ? 1.0 : ((b[j] .- reshape(A[j,:], 1, 2) * x) / (reshape(A[j,:], 1, 2) * d))[1,1] for j in (2,3,4,5)]...)
	α, d
end						   
```						   
```
(1.0, [0.4, 0.2])
```
The new step-length is ``1``. There are no blocking constraints
on this step, so the next working set in unchanged: ``W_{5}=\left\{ 1\right\} ``. The new iterate is ``\vec{x}^{\left(5\right)}=\begin{pmatrix}1.4 & 1.7\end{pmatrix}^\mathsf{T}``.	

```julia
x₄ = x₃ + α₄ .* d₄ # [1.4, 1.7]
sol₅ = let x = x₄
	g = Q*x - c
	ain = reshape(A[1,:], 1, 2)
	sol = [Q transpose(ain)
		   ain zeros(1,1)] \ [-g; 0]
end
```						   
```
[0.0, 0.0, 0.8]
```						   
						   	
Finally, we solve the subproblem for ``k=5`` to obtain a solution ``\vec{d}^{\left(5\right)}=\vec{0}``.
We find a multiplier ``\mu_{1}^{\circ}=0.8``, so we have found the
solution. Wet set ``\vec{x}^{\star}=\begin{pmatrix}1.4 & 1.7\end{pmatrix}^\mathsf{T}``
and terminate.

The figure below illustrates the iterative process:
						   
$(let
Q = Float64[2 0
0 2]
c = Float64[2, 5]
A = Float64[-1  2
1  2
1 -2
-1  0
0 -1]
b = Float64[2, 6, 2, 0, 0]
	x = -1:0.05:5
	y = -1:0.05:5
	z = Surface((x,y)->(0.5 .* [x y]*Q*[x;y] .- transpose(c)*[x;y] .+ 0.5 .* transpose(c)*Q*c)[1], x, y)
	contour(x, y, z, levels=35)
	plot!(x, (2 .+ x) ./ 2, linestyle=:dash, label=L"-x_1 + 2x_2 - 2 ≤ 0")
	plot!(x, (6 .- x) ./ 2, linestyle=:dash, label=L" x_1 + 2x_2 - 6 ≤ 0")
	plot!(x, (2 .- x) ./ -2, linestyle=:dash, label=L"x_1 - 2x_2 - 2 ≤ 0")
	plot!([0,2,4,2,0,0],[0,0,1,2,1,0], linewidth=2, label="feasible domain")
	plot!([2,2,1,1,1,1.4], [0,0,0,0,1.5,1.7], linewidth=2, label="iterations", color=:red, markershape=:circle, xlabel=L"x_1", ylabel=L"x_2", title=L"f : (x_1 - 1)^2 + (x_2 - 2.5)^2")
end
)
""", open=false)
	
	QP_AS = md"""
We consider only
the convex case, in which the matrix ``Q`` is positive semidefinite.

If the contents of the optimal active set ``J\left(\vec x^\star\right)`` were known in advance, we could find the solution ``\vec{x}^{\star}``
by applying the technique for equality constrained quadratic programs
to the problem
```math
\begin{aligned}
\min_{\vec{x}}\, & f\left(\vec{x}\right)\overset{\vartriangle}{=}\frac{1}{2} \vec{x}^\mathsf{T}Q\vec{x}- \vec{c}^\mathsf{T}\vec{x}\\
\textrm{subject to}\, & \begin{cases}
A_{\textrm{eq}}\vec{x}=\vec{b}_{\textrm{eq}}\,,\\
 \vec{a}_{\textrm{in},j}^\mathsf{T}\vec{x}=b_{\textrm{in},j}\,, & \forall j\in J\left(\vec{x}^{\star}\right)\,,
\end{cases}
\end{aligned}
```
where ``\vec{a}_{\textrm{in},j}`` is the ``j``th row in the matrix ``A_{\textrm{in}}``
and ``b_{\textrm{in},j}`` is the ``j``th element of the vector ``\vec{b}_{\textrm{in}}``.
Of course, we usually do not have prior knowledge of ``J\left(\vec{x}^{\star}\right)``
and determination of this set is the main challenge facing algorithms
for inequality-constrained quadratic programs.

Active-set methods find a step from one iterate to the next by solving
a quadratic subproblem in which some of the inequality constraints,
and all the equality constraints are imposed as equalities. This subset
is referred to as the _working set_ and is denoted at the ``k``th
iterate by ``W_{k}``. An important requirement we impose on ``W_{k}``
is that the gradients ``\vec{a}_{\textrm{eq},i}``, ``i=1,\dots,m`` and
``\vec{a}_{\textrm{in},j}``, ``j\in W_{k}`` are linearly independent,
even when the full set of active constraints at that point has linearly
dependent gradients.

Given an iterate ``\vec{x}^{\left(k\right)}`` and the working set ``W_{k}``,
we first check whether ``\vec{x}^{\left(k\right)}`` minimizes the quadratic
function ``f`` in the subspace defined by the working set. If not,
we compute a step ``\vec{d}^{\left(k\right)}`` by solving an equality-constrained
quadratic subproblem in which the inequality constraints corresponding
to the working set ``W_{k}`` are regarded as equalities and the other
inequality constraints are temporarily disregarded. To express this
subproblem in terms of the step ``\vec{d}^{\left(k\right)}``, we define
```math
\vec{d}^{\left(k\right)}=\vec{x}^{\left(k+1\right)}-\vec{x}^{\left(k\right)}\,,\quad\vec{g}_{k}=Q\vec{x}^{\left(k\right)}-\vec{c}\,.
```
By substituting for ``\vec{x}^{\left(k+1\right)}`` into the objective
function, we find that
```math
f\left(\vec{x}^{\left(k+1\right)}\right)=f\left(\vec{x}^{\left(k\right)}+\vec{d}^{\left(k\right)}\right)=\frac{1}{2}\left(\vec{d}^{\left(k\right)}\right)^\mathsf{T}Q\vec{d}^{\left(k\right)}+\vec{g}_{k}^\mathsf{T}\vec{d}^{\left(k\right)}+\rho_{k}\,,
```
where ``\rho_{k}=\frac{1}{2} \left(\vec{x}^{\left(k\right)}\right)^\mathsf{T}Q\vec{x}^{\left(k\right)}- \vec{c}^\mathsf{T}\vec{x}^{\left(k\right)}``
is independent of ``\vec{d}^{\left(k\right)}``. Since we can drop ``\rho_{k}``
from the objective function without changing the solution of the problem,
we can write the subproblem to be solved at the ``k``th iteration as
follows
```math
    \min_{\vec{d}^{\left(k\right)}} \frac{1}{2} \left(\vec{d}^{\left(k\right)}\right)^\mathsf{T}Q\vec{d}^{\left(k\right)}+ \vec{g}_{k}^\mathsf{T}\vec{d}^{\left(k\right)} \text{ subject to}
    \begin{cases}
        A_{\text{eq}}\vec{d}^{\left(k\right)}=\vec{0} \\
        \vec{a}_{\textrm{in},j}^\mathsf{T}\vec{d}^{\left(k\right)}=0
    \end{cases}
    , \forall j\in W_{k}
```


Note that for each ``j\in W_{k}``, the value of `` \vec{a}_{\textrm{in},j}^\mathsf{T}\vec{x}^{\left(k\right)}``
does not change as we move along ``\vec{d}^{\left(k\right)}``, since
we have `` \vec{a}_{\textrm{in},j}^\mathsf{T}\left(\vec{x}^{\left(k\right)}+\alpha\vec{d}^{\left(k\right)}\right)= \vec{a}_{\textrm{in},j}^\mathsf{T}\vec{x}^{\left(k\right)}=b_{\textrm{in},j}``
for all ``\alpha``. Since the constraints in ``W_{k}`` were satisfied
at ``\vec{x}^{\left(k\right)}``, they are also satisfied at ``\vec{x}^{\left(k\right)}+\alpha\vec{d}^{\left(k\right)}``,
for any value of ``\alpha``.

Supposing for the moment that the optimal ``\vec{d}^{\left(k\right)}``
is nonzero, we need to decide how far to move along this direction.
If ``\vec{x}^{\left(k\right)}+\vec{d}^{\left(k\right)}`` is feasible
with respect to all the constraints, we set ``\vec{x}^{\left(k+1\right)}=\vec{x}^{\left(k\right)}+\vec{d}^{\left(k\right)}``.
Otherwise, we set
```math
\vec{x}^{\left(k+1\right)}=\vec{x}^{\left(k\right)}+\alpha_{k}\vec{d}^{\left(k\right)}\,,
```
where the step-length parameter ``\alpha_{k}`` is chosen to be the
largest value in the range ``\left[0,1\right]`` for which all constraints
are satisfied. We can derive an explicit definition of ``\alpha_{k}``
by considering what happens to the constraints ``j\notin W_{k}``, since
the constraints ``j\in W_{k}`` will certainly be satisfied regardless
of the choice of ``\alpha_{k}``. If `` \vec{a}_{\textrm{in},j}^\mathsf{T}\vec{d}^{\left(k\right)}\leq0``
for some ``j\notin W_{k}``, then for all ``\alpha_{k}\geq0``, we have
`` \vec{a}_{\textrm{in},j}^\mathsf{T}\left(\vec{x}^{\left(k\right)}+\alpha_{k}\vec{d}^{\left(k\right)}\right)\leq \vec{a}_{\textrm{in},j}^\mathsf{T}\vec{x}^{\left(k\right)}\leq b_{\textrm{in},j}``.
Hence, constraint ``j`` will be satisfied for all nonnegative choices
of the step-length parameter. Whenever `` \vec{a}_{\textrm{in},j}^\mathsf{T}\vec{d}^{\left(k\right)}>0``
for some ``j\notin W_{k}``, however, we have that `` \vec{a}_{\textrm{in},j}^\mathsf{T}\left(\vec{x}^{\left(k\right)}+\alpha_{k}\vec{d}^{\left(k\right)}\right)\leq b_{\textrm{in},j}``
only if
```math
\alpha_{k}\leq\frac{b_{\textrm{in},j}- \vec{a}_{\textrm{in},j}^\mathsf{T}\vec{x}^{\left(k\right)}}{ \vec{a}_{\textrm{in},j}^\mathsf{T}\vec{d}^{\left(k\right)}}\,.
```
To maximize the decrease in ``f``, we want ``\alpha_{k}`` to be as large
as possible in ``\left[0,1\right]`` subject to retaining feasibility,
so we obtain the following definition
```math
\alpha_{k}\overset{\textrm{def}}{=}\min\left\{ 1,\min_{j\notin W_{k}, \vec{a}_{\textrm{in},j}^\mathsf{T}\vec{d}^{\left(k\right)}>0}\frac{b_{\textrm{in},j}- \vec{a}_{\textrm{in},j}^\mathsf{T}\vec{x}^{\left(k\right)}}{ \vec{a}_{\textrm{in},j}^\mathsf{T}\vec{d}^{\left(k\right)}}\right\} \,.
```
We call the constraints ``j`` for which this minimum is achieved the
_blocking constraints_. Note that it is quite possible for ``\alpha_{k}``
to be zero, because we could have `` \vec{a}_{\textrm{in},j}^\mathsf{T}\vec{d}^{\left(k\right)}>0``
for some constraint ``j`` that is active at ``\vec{x}^{\left(k\right)}``
but not a member of the current working set ``W_{k}``.

If ``\alpha_{k}<1``, that is, the step along ``\vec{d}_{k}`` was blocked
by some constraint not in ``W_{k}``, a new working set ``W_{k+1}`` is
constructed by adding one of the blocking constraints to ``W_{k}``.
We continue to iterate in this manner, adding constraints to the working
set until the subproblem has solution ``\vec{d}^{\circ}=\vec{0}``.
Since ``\vec{d}^{\circ}=\vec{0}`` satisfy the optimality condition, we have that
```math
\sum_{i=1}^{m}\lambda_{i}^{\circ}\vec{a}_{\textrm{eq},i}+\sum_{j\in W^{\circ}}\mu_{j}^{\circ}\vec{a}_{\textrm{in},j}=-\vec{g}^{\circ}=-Q\vec{x}^{\circ}+\vec{c}\,,
```
for some Lagrange multipliers ``\lambda_{i}^{\circ}``, ``i=1,\dots,m``
and ``\mu_{j}^{\circ}``, ``j\in W^{\circ}``. It follows that ``\vec{x}^{\circ}``,
``\vec{\lambda}^{\circ}`` and ``\vec{\mu}^{\circ}`` satisfy the second
KKT condition, if we define the multipliers corresponding to the inequality
constraints not in the working set to be zero. Because of the control
imposed on the step length, ``\vec{x}^{\circ}`` is also feasible with
respect to all the constraints, so the third, fourth and fifth KKT
conditions are satisfied at this point.

We now examine the signs of the KKT multipliers in the working set,
that is, the indices ``j\in W^{\circ}``. If these conditions are all
nonnegative, the first KKT condition is also satisfied, so we conclude
that ``\vec{x}^{\circ}`` is a KKT point for the original problem. In
fact, since ``Q`` is positive semidefinite, we have that ``\vec{x}^{\circ}``
is a global minimum.

If, on the other hand, on or more of the multipliers ``\mu_{j}^{\circ}``,
``j\in W^{\circ}``, are negative, the first KKT condition is not satisfied
and the objective function ``f`` may be decreased by dropping one of
these constraints. Thus, we remove an index ``j`` corresponding to
one of the negative multipliers from the working set and solve a new
subproblem for the next step. While any index ``j`` for which ``\mu_{j}^{\circ}<0``
usually will yield in a direction ``\vec{d}`` along which the algorithm
can make progress, the most negative multiplier is often chosen in
practice. This choice is motived by a sensitivity analysis, which
shows that the rate of decrease in the objective function when one
constraint is removed, is proportional to the magnitude of the Lagrange
multiplier for that constraint.
"""
	PlutoUI.details("""Deep dive - active set methods for inequality constraints""", [QP_AS;QP_AS_Ex], open=false)
end

# ╔═╡ c06bd9c8-f489-42a4-8a6d-162f4864ba19
md"""
### General constrained optimisation
We can now return to the general optimisation problem from the introduction:
```math
\begin{aligned}
\min\, & f\left(\vec{x}\right)\\
\textrm{subject to} & \begin{cases}
\vec{h}\left(\vec{x}\right)=\vec{0}\\
\vec{g}\left(\vec{x}\right)\leq\vec{0}
\end{cases}
\end{aligned}
```
where $f:\mathbb{R}^{n}\rightarrow\mathbb{R}$, $\vec{h}:\mathbb{R}^{n}\rightarrow\mathbb{R}^{m}$,
$m\leq n$, and $\vec{g}:\mathbb{R}^{n}\rightarrow\mathbb{R}^{p}$.

!!! info "Sequential quadratic programming (SQP)"
	The idea behind the this approach is to model the general problem at the current iterate ``\vec{x}^{\left(k\right)}`` by a quadratic programming subproblem, then use the minimizer of this subproblem to define a new iterate ``\vec{x}^{\left(k+1\right)}``. 

The challenge is to design the quadratic subproblem so that it yields a good step for the general optimization problem.

"""

# ╔═╡ b5c4010d-f373-4a5b-8e14-275fb45c5292
PlutoUI.details("deep dive - SQP", md"""We know that the extended Lagrangian function for this problem is

```math
\mathcal{L}\left(\vec{x},\vec{\lambda},\vec{\mu}\right)=f\left(\vec{x}\right)+\vec{\lambda}^\mathsf{T}\vec{h}\left(\vec{x}\right)+\vec{\mu}^\mathsf{T}\vec g\left(\vec{x}\right)\,.
```

Applying Newton's method to the Lagrangian function and linearizing
both the equality and the inequality constraints yields the following
subproblem
```math
\begin{aligned}
\min_{\vec{d}^{\left(k\right)}}\, & \frac{1}{2}\left(\vec{d}^{\left(k\right)}\right)^\mathsf{T} \mathsf{H} \mathcal{L}\left(\vec{x}^{\left(k\right)},\vec{\lambda}^{\left(k\right)},\vec{\mu}^{\left(k\right)}\right)\vec{d}^{\left(k\right)}+ \mathsf{D} \mathcal{L}\left(\vec{x}^{\left(k\right)},\vec{\lambda}^{\left(k\right)},\vec{\mu}^{\left(k\right)}\right)\vec{d}^{\left(k\right)}\\
\textrm{subject to}\, & \begin{cases}
 \mathsf{J}\vec{h}\left(\vec{x}^{\left(k\right)}\right)\vec{d}^{\left(k\right)}=-\vec{h}\left(\vec{x}^{\left(k\right)}\right)\\
 \mathsf{D} g_{j}\left(\vec{x}^{\left(k\right)}\right)\vec{d}^{\left(k\right)}=-g_{j}\left(\vec{x}^{\left(k\right)}\right)\,, & j\in W_{k}\,,
\end{cases}
\end{aligned}
```

where $\mu_{j}^{\left(k\right)}=0$, for all
$j\notin W_{k}$. We can use the active-set method for quadratic programming
to solve this subproblem. The new iterate is given by $\vec{x}^{\left(k+1\right)}$,
$\vec{\lambda}^{\left(k+1\right)}$, $\vec{\mu}^{\left(k+1\right)}$
and $W_{k+1}$.

If the SQP method is able to identify the optimal active set then
it will act like a Newton method for equality-constrained optimization
and will converge rapidly.

It is also remarkable that, far from the solution, the SQP approach
is usually able to improve the estimate of the active set and guide
the iterates towards a solution.

Non-quadratic objective functions, however, can impede progress of
the SQP algorithm, a phenomenon known as the Maratos effect. Steps
that make good progress toward a solution are rejected and the algorithm
fails to converge rapidly. These difficulties can be overcome by means
of a _second-order correction_.""")

# ╔═╡ afb498db-dc05-49c3-baad-d4bca7d2cc27
md"""
!!! info "Interior point methods"
	This is the same family of methods we used to solve linear programming problems. It has been shown that interior point methods are as successful for nonlinear optimization as for linear programming. 

"""

# ╔═╡ 3f38a7f9-d64a-4eca-8205-72cfee88bb4d
PlutoUI.details("deep dive - interior points for general optimisation", md"""For simplicity, we restrict our attention to convex quadratic programs,
which we write as follows:
```math
\begin{aligned}
\min_{\vec{x}}\, & f\left(\vec{x}\right)\overset{\vartriangle}{=}\frac{1}{2} \vec{x}^\mathsf{T}Q\vec{x}- \vec{c}^\mathsf{T}\vec{x}\\
\textrm{subject to}\, & \begin{cases}
A_{\textrm{eq}}\vec{x}=\vec{b}_{\textrm{eq}}\,,\\
A_{\textrm{in}}\vec{x}\leq\vec{b}_{\textrm{in}}\,,
\end{cases}
\end{aligned}
```
where ``Q`` is a symmetric and positive semidefinite ``n\times n`` matrix,
``\vec{c}\in\mathbb{R}^{n}``, ``A_{\textrm{eq}}`` is a ``m\times n`` matrix,
``\vec{b}_{\textrm{eq}}\in\mathbb{R}^{m}``, ``A_{\textrm{in}}`` is a ``p\times n``
matrix and ``\vec{b}_{\textrm{in}}\in\mathbb{R}^{p}``. Rewriting the KKT
conditions in this notation, we obtain
```math
\begin{aligned}
\vec{\mu} & \geq\vec{0}\,,\\
Q\vec{x}+ A_{\textrm{eq}}^\mathsf{T}\vec{\lambda}+ A_{\textrm{in}}^\mathsf{T}\vec{\mu}-\vec{c} & =\vec{0}\,,\\
\left(A_{\textrm{in}}\vec{x}-\vec{b}_{\textrm{in}}\right)_{j}\mu_{j} & =0\,,\quad j=1,\dots,p\,,\\
A_{\textrm{eq}}\vec{x} & =\vec{b}_{\textrm{eq}}\,,\\
A_{\textrm{in}}\vec{x} & \leq\vec{b}_{\textrm{in}}\,.
\end{aligned}
```
By introducing the slack vector ``\vec{y}\geq\vec{0}``, we can rewrite
these conditions as
```math
\begin{aligned}
\left(\vec{\mu},\vec{y}\right) & \geq\vec{0}\,,\\
Q\vec{x}+ A_{\textrm{eq}}^\mathsf{T}\vec{\lambda}+ A_{\textrm{in}}^\mathsf{T}\vec{\mu}-\vec{c} & =\vec{0}\,,\\
y_{j}\mu_{j} & =0\,,\quad j=1,\dots,p\,,\\
A_{\textrm{eq}}\vec{x}-\vec{b}_{\textrm{eq}} & =\vec{0}\,,\\
A_{\textrm{in}}\vec{x}-\vec{b}_{\textrm{in}}+\vec{y} & =\vec{0}\,.
\end{aligned}
```
Since we assume that ``Q`` is positive semidefinite, these KKT conditions
are not only necessary but also sufficient, so we can solve the convex
quadratic program by finding solutions of this system.

Primal-dual methods generate iterates that satisfy the bounds strictly; that is, ``\vec{y}>0``
and ``\vec{\mu}>0``. This property is the origin of the term interior-point.
By respecting these bounds, the methods avoid spurious solutions,
points that satisfy the system but not the bounds. Spurious solutions
abound, and do not provide useful information about real solutions,
so it makes sense to exclude them altogether. Given a current iterate
``\left(\vec{x}^{\left(k\right)},\vec{y}^{\left(k\right)},\vec{\lambda}^{\left(k\right)},\vec{\mu}^{\left(k\right)}\right)``
that satisfies ``\left(\vec{\mu}^{\left(k\right)},\vec{y}^{\left(k\right)}\right)>0``,
we can define a _complementary measure_
```math
\nu_{k}=\frac{ \left(\vec{y}^{\left(k\right)}\right)^\mathsf{T}\vec{\mu}^{\left(k\right)}}{p}\,.
```
This measure gives an indication of the desirability of the couple
``\left(\vec{\mu}^{\left(k\right)},\vec{y}^{\left(k\right)}\right)``.

We derive a path-following, primal-dual method by considering the
perturbed KKT conditions by
```math
\vec{F}\left(\vec{x}^{\left(k+1\right)},\vec{y}^{\left(k+1\right)},\vec{\lambda}^{\left(k+1\right)},\vec{\mu}^{\left(k+1\right)},\sigma_{k}\nu_{k}\right)=\begin{pmatrix}Q\vec{x}^{\left(k+1\right)}+ A_{\textrm{eq}}^\mathsf{T}\vec{\lambda}^{\left(k+1\right)}+ A_{\textrm{in}}^\mathsf{T}\vec{\mu}^{\left(k+1\right)}-\vec{c}\\
Y_{k+1}M_{k+1}\vec{1}-\sigma_{k}\nu_{k}\vec{1}\\
A_{\textrm{eq}}\vec{x}^{\left(k+1\right)}-\vec{b}_{\textrm{eq}}\\
A_{\textrm{in}}\vec{x}^{\left(k+1\right)}-\vec{b}_{\textrm{in}}+\vec{y}^{\left(k+1\right)}
\end{pmatrix}=\vec{0}\,,
```
where
```math
Y_{k+1}=\begin{pmatrix}y_{1}^{\left(k+1\right)} & 0 & \cdots & 0\\
0 & y_{2}^{\left(k+1\right)} & \ddots & 0\\
\vdots & \ddots & \ddots & 0\\
0 & 0 & 0 & y_{p}^{\left(k+1\right)}
\end{pmatrix}\,,\quad M_{k+1}=\begin{pmatrix}\mu_{1}^{\left(k+1\right)} & 0 & \cdots & 0\\
0 & \mu_{2}^{\left(k+1\right)} & \ddots & 0\\
\vdots & \ddots & \ddots & 0\\
0 & 0 & 0 & \mu_{p}^{\left(k+1\right)}
\end{pmatrix}\,,
```
and ``\sigma\in\left[0,1\right]`` is the reduction factor that we wish
to achieve in the complementary measure on one step. We call ``\sigma``
the _centering parameter_. The solution of this system for all
positive values of ``\sigma`` and ``\nu`` define the _central path_,
which is a trajectory that leads to the solution of the quadratic
program as ``\sigma\nu`` tends to zero.

By fixing ``\sigma_{k}`` and applying Newton's method to the system,
we obtain the linear system
```math
\begin{pmatrix}Q & 0 &  A_{\textrm{eq}}^\mathsf{T} &  A_{\textrm{in}}^\mathsf{T}\\
0 & M_{k} & 0 & Y_{k}\\
A_{\textrm{eq}} & 0 & 0 & 0\\
A_{\textrm{in}} & I & 0 & 0
\end{pmatrix}\begin{pmatrix}\vec{d}_{\vec{x}}^{\left(k\right)}\\
\vec{d}_{\vec{y}}^{\left(k\right)}\\
\vec{d}_{\vec{\lambda}}^{\left(k\right)}\\
\vec{d}_{\vec{\mu}}^{\left(k\right)}
\end{pmatrix}=-\begin{pmatrix}Q\vec{x}^{\left(k\right)}+ A_{\textrm{eq}}^\mathsf{T}\vec{\lambda}^{\left(k\right)}+ A_{\textrm{in}}^\mathsf{T}\vec{\mu}^{\left(k\right)}-\vec{c}\\
Y_{k}M_{k}\vec{1}-\sigma_{k}\nu_{k}\vec{1}\\
A_{\textrm{eq}}\vec{x}^{\left(k\right)}-\vec{b}_{\textrm{eq}}\\
A_{\textrm{in}}\vec{x}^{\left(k\right)}-\vec{b}_{\textrm{in}}+\vec{y}^{\left(k\right)}
\end{pmatrix}\,.
```
We obtain the next iterate by setting
```math
\begin{pmatrix}\vec{x}^{\left(k+1\right)}\\
\vec{y}^{\left(k+1\right)}\\
\vec{\lambda}^{\left(k+1\right)}\\
\vec{\mu}^{\left(k+1\right)}
\end{pmatrix}=\begin{pmatrix}\vec{x}^{\left(k\right)}\\
\vec{y}^{\left(k\right)}\\
\vec{\lambda}^{\left(k\right)}\\
\vec{\mu}^{\left(k\right)}
\end{pmatrix}+\alpha_{k}\begin{pmatrix}\vec{d}_{\vec{x}}^{\left(k\right)}\\
\vec{d}_{\vec{y}}^{\left(k\right)}\\
\vec{d}_{\vec{\lambda}}^{\left(k\right)}\\
\vec{d}_{\vec{\mu}}^{\left(k\right)}
\end{pmatrix}\,,
```
where ``\alpha_{k}`` is chosen to retain the bounds ``\left(\vec{\mu}^{\left(k+1\right)},\vec{y}^{\left(k+1\right)}\right)>0``
and possibly to satisfy various other conditions.

The choices of centering parameter ``\sigma_{k}`` and step-length ``\alpha_{k}``
are crucial for the performance of the method. Techniques for controlling
these parameters, directly and indirectly, give rise to a wide variety
of methods with diverse properties. One option is to use equal step
length for the primal and dual updates, and to set ``\alpha_{k}=\min\left\{ \alpha_{k}^{\textrm{pri}},\alpha_{k}^{\textrm{dual}}\right\} ``,
where
```math
\begin{aligned}
\alpha_{k}^{\textrm{pri}} & =\max\left\{ \alpha\in\left\{ 0,1\right\} :\vec{y}^{\left(k\right)}+\alpha\vec{d}_{\vec{y}}^{\left(k\right)}\geq\left(1-\tau\right)\vec{y}^{\left(k\right)}\right\} \,,\\
\alpha_{k}^{\textrm{dual}} & =\max\left\{ \alpha\in\left\{ 0,1\right\} :\vec{\mu}^{\left(k\right)}+\alpha\vec{d}_{\vec{\mu}}^{\left(k\right)}\geq\left(1-\tau\right)\vec{\mu}^{\left(k\right)}\right\} \,,
\end{aligned}
```
the parameter ``\tau\in\left]0,1\right[`` controls how far we back
off from the maximum step for which the conditions ``\vec{y}^{\left(k\right)}+\alpha\vec{d}_{\vec{y}}^{\left(k\right)}\geq\vec{0}``
and ``\vec{\mu}^{\left(k\right)}+\alpha\vec{d}_{\vec{\mu}}^{\left(k\right)}\geq\vec{0}``
are satisfied. A typical value of ``\tau=0.995`` and we can choose
``\tau_{k}`` to approach ``1`` as the iterates approach the solution,
to accelerate the convergence.

The most popular interior-point method for convex QP is based on Mehrotra's
predictor-corrector. First we compute an affine scaling step ``\left(\vec{d}_{\vec{x},\textrm{aff}},\vec{d}_{\vec{y},\textrm{aff}},\vec{d}_{\vec{\lambda},\textrm{aff}},\vec{d}_{\vec{\mu},\textrm{aff}}\right)``
by setting ``\sigma_{k}=0``. We improve upon this step by computing
a corrector step. Next, we compute the centering parameter ``\sigma_{k}``
using following heuristic
```math
\sigma_{k}=\left(\frac{\nu_{\textrm{aff}}}{\nu_{k}}\right)^{3}\,,
```
where ``\nu_{\textrm{aff}}=\frac{ \left(\vec{y}_{\textrm{aff}}\right)^\mathsf{T}\left(\vec{\mu}_{\textrm{aff}}\right)}{p}``.
The total step is obtained by solving the following system
```math
\begin{pmatrix}Q & 0 &  A_{\textrm{eq}}^\mathsf{T} &  A_{\textrm{in}}^\mathsf{T}\\
0 & M_{k} & 0 & Y_{k}\\
A_{\textrm{eq}} & 0 & 0 & 0\\
A_{\textrm{in}} & I & 0 & 0
\end{pmatrix}\begin{pmatrix}\vec{d}_{\vec{x}}^{\left(k\right)}\\
\vec{d}_{\vec{y}}^{\left(k\right)}\\
\vec{d}_{\vec{\lambda}}^{\left(k\right)}\\
\vec{d}_{\vec{\mu}}^{\left(k\right)}
\end{pmatrix}=-\begin{pmatrix}Q\vec{x}^{\left(k\right)}+ A_{\textrm{eq}}^\mathsf{T}\vec{\lambda}^{\left(k\right)}+ A_{\textrm{in}}^\mathsf{T}\vec{\mu}^{\left(k\right)}-\vec{c}\\
Y_{k}M_{k}\vec{1}+\Delta Y_{\textrm{aff}}\Delta M_{\textrm{aff}}\vec{1}-\sigma_{k}\nu_{k}\vec{1}\\
A_{\textrm{eq}}\vec{x}^{\left(k\right)}-\vec{b}_{\textrm{eq}}\\
A_{\textrm{in}}\vec{x}^{\left(k\right)}-\vec{b}_{\textrm{in}}+\vec{y}^{\left(k\right)}
\end{pmatrix}\,,
```
where
```math
\Delta Y_{\textrm{aff}}=Y_{\textrm{aff}}-Y_{k}\,,\quad\Delta M_{\textrm{aff}}=M_{\textrm{aff}}-M_{k}\,.
```""")

# ╔═╡ 7d2cb249-0d7f-4a69-9f33-4fac6e22f58b
md"""
#### Implementation
We will use the [Ipopt solver](https://coin-or.github.io/Ipopt/), which is written in C. It is made available to the Julia language through the [`Ipopt.jl`](https://github.com/jump-dev/Ipopt.jl) package, which integrates perfectly with the JuMP framework, making it very user-friendly.

Considering the example from earlier, i.e.
```math
\begin{aligned}
\min_{\vec{x}}\, & f\left(\vec{x}\right)=\left(x_{1}-1\right)^{2}+\left(x_{2}-2.5\right)^{2}\\
\textrm{subject to}\, & \begin{cases}
-x_{1}+2x_{2}-2\leq0\,,\\
x_{1}+2x_{2}-6\leq0\,.\\
x_{1}-2x_{2}-2\leq0\,,\\
-x_{1}\leq0\,,\\
-x_{2}\leq0\,.
\end{cases}
\end{aligned}
```
You can see in the code below, that the implementation is an almost direct copy of the original problem. 
"""

# ╔═╡ b949506d-936a-4c5b-8724-1a71e86b5397
let
	model = Model(Ipopt.Optimizer)
	set_attribute(model, "print_level", 1) # to limit the solver's output
	@variable(model, x₁ ≥ 0, start=2)
	@variable(model, x₂ ≥ 0, start=0)
	@NLobjective(model, Min, (x₁-1)^2+(x₂-2.5)^2)
	@constraint(model, con1, -x₁+2x₂ <= 2)
	@constraint(model, con2,  x₁+2x₂ <= 6)
	@constraint(model, con3,  x₁-2x₂ <= 2)
	optimize!(model)
    @info """Obtained solution: 
	- x₁: $(value(x₁))
	- x₂: $(value(x₂))
	"""
end

# ╔═╡ 3e9afcf2-601b-4965-a738-37b4b5e2638c
md"""
## Stochastic optimisation
We have seen that most algorithm follow a greedy approach, and will find the optimum closest to the initial point, which can lead to us being stuck in a local optimum. This problem can be overcome by adding randomness to help escape local optima and increase the chances of finding a global optimum.

!!! info "Stochastic Optimisation"
	Stochastic optimisation refers to methods that incorporate randomness to improve the search for optimal solutions, particularly to escape local optima and increase the likelihood of finding a global optimum. These methods are useful when the objective function is complex, non-convex, or has multiple local optima. Randomness is often introduced via techniques like random perturbations, simulated annealing, or genetic algorithms.

	Formally, stochastic optimisation can be described as:
	```math
	\min_{\vec{x} \in \Omega} f(\vec{x})
	```
	where randomness is used in the algorithm (e.g., random sampling or stochastic gradients) to explore the solution space ``\Omega \subseteq \mathbb{R}^n``, and ``f : \mathbb{R}^n \mapsto \mathbb{R}`` is the objective function.

!!! danger "Heads up!"
	1. Stochastic methods trade determinism for robustness, often requiring more computational effort but improving global convergence.
	2. Proper tuning of randomness (e.g., step sizes or mutation rates) is critical to balance exploration and exploitation.
"""

# ╔═╡ 0293ad9d-d058-4467-874b-d8c51ed2882e
md"""
### Particle Swarm Optimisation

!!! info "Particle Swarm Optimisation (PSO)"
	Particle Swarm Optimisation (PSO) is a stochastic optimisation method inspired by the social behavior of flocks of birds or schools of fish. It uses a population of particles, each representing a candidate solution, that move through the search space based on their own best-known position and the swarm's global best position. Randomness in velocity updates helps particles escape local optima, increasing the likelihood of finding a global optimum.

	Each particle's velocity is updated as:
	```math
	\vec{v}_i \gets w \vec{v}_i + c_1 r_1 (\vec{x}_{\text{best},i} - \vec{x}_i) + c_2 r_2 (\vec{x}_{\text{best}} - \vec{x}_i)
	```
	```math
	\vec{x}_i \gets \vec{x}_i + \vec{v}_i
	```
	where $\vec{v}_i$ is the velocity, $\vec{x}_{\text{best},i}$ is the particle $i$'s best position, $\vec{x}_{\text{best}}$ is the global best position, $w$ is the inertia weight, $c_1, c_2$ are parameters, and $r_1, r_2 \sim U(0,1)$ are random numbers.

	**Notes**:
	1. PSO is effective for non-convex, multimodal problems but may require careful tuning of parameters $w,c_1, c_2$ to balance exploration and convergence.
	2. The algorithm’s performance depends on the initial particle distribution and the complexity of the objective function.
"""

# ╔═╡ d85aaa13-555a-465f-8f8e-3732978cae7c
md"""
!!! tip "Optimising the Rastrigin function with PSO"
	The [Rastrigin function](https://en.wikipedia.org/wiki/Rastrigin_function#) is a non-convex, multimodal function commonly used to test optimisation algorithms due to its many local minima.

	It is defined as:
	```math
	f(\vec{x}) = 10n + \sum_{i=1}^n \left[ x_i^2 - 10 \cos(2\pi x_i) \right], \quad \vec{x} \in \mathbb{R}^n
	```
"""

# ╔═╡ 81955573-23b9-4af7-82bf-e6b21cdd36b7
let
	# Define the Rastrigin function
	function rastrigin(x)
	    A = 10
	    return A * length(x) + sum(xi^2 - A * cos(2 * π * xi) for xi in x)
	end
	
	# Set initial guess and bounds
	N = 2 # dimension
	initial_guess = rand(N) * 10 .- 5  # A random guess in the range [-5, 5]
	lower_bound = -5 * ones(N)  # Lower bound for each dimension
	upper_bound = 5 * ones(N)   # Upper bound for each dimension
	
	# Run PSO
	result = optimize(rastrigin, initial_guess, ParticleSwarm(lower=lower_bound, upper=upper_bound, n_particles=100))
	result_nelder = optimize(rastrigin, initial_guess, NelderMead(lower=lower_bound, upper=upper_bound))
	
	# Display results
	println("Optimal solution: ", Optim.minimizer(result))
	println("Objective value: ", Optim.minimum(result))
	println("Converged: ", Optim.converged(result))

	# Plot the Rastrigin function
	x = y = -5:0.1:5
	Z = [rastrigin([xi, yi]) for xi in x, yi in y]
	contour(x, y, Z',
	    title="Rastrigin Function Contour Plot",
		fill=true,
	    xlabel="X",
	    ylabel="Y",
	    color=:turbo,
	    clims=(0, 100),
	    colorbar_title="Function Value",
	    levels=20)
	# Add the initial guess
	scatter!([initial_guess[1]], [initial_guess[2]], label="Initial guess", color=:black, marker=:diamond, markersize=8)
	# Add the PSO result + Add value ot the function in the legend label using string interpolation
	scatter!([Optim.minimizer(result)[1]], [Optim.minimizer(result)[2]], label="PSO solution ($(Optim.minimum(result)))", color=:red, marker=:cross, markersize=8)
	# Add the Nelder-Mead result
	scatter!([Optim.minimizer(result_nelder)[1]], [Optim.minimizer(result_nelder)[2]], label="Nelder-Mead Solution ($(round(Optim.minimum(result_nelder), digits=2)))", color=:gray, marker=:hexagon, markersize=8)
	plot!(title="PSO Solution", xlabel="X coordinate", ylabel="Y coordinate")
end

# ╔═╡ 053779d8-056b-46fe-bee8-c151132639c1
md"""
## Optimisation of stochastic functions
!!! info "Optimisation of Stochastic Functions"
	This refers to optimisation problems where the objective function or constraints involve randomness, such as when ``\left(f(\vec{x})\right)`` is an expected value or involves noisy measurements. Examples include optimising systems under uncertainty (e.g., financial models, machine learning). The goal is to minimise the expected value of the objective function:
	```math
	\min_{\vec{x} \in \Omega} \mathbb{E}[f(\vec{x}, \omega)]
	```
	subject to constraints that may also be stochastic:
	```math
	\mathbb{E}[\vec{h}(\vec{x}, \omega)] = \vec{0}, \quad \mathbb{E}[\vec{g}(\vec{x}, \omega)] \leq \vec{0}
	```
	where $\omega$ represents random variables, and expectations are taken over their distributions.



!!! danger "Heads up!"
	1. Estimating the expected value of the objective function typically requires running multiple samples or simulations, which can be computationally expensive.
	2. Stochastic optimisation may not always guarantee a global optimum due to the noise, but it can often find a good solution given the randomness in the system.
	3. Defining the stochastic components (e.g., probability distributions) accurately is crucial for meaningful solutions.
	4. As the number of stochastic dimensions increases, suitable sampling approaches should be selected to keep the sampling computationally tractable.
"""

# ╔═╡ 40833da5-cfcc-4fe1-bdeb-9a1aa4b34f57
md"""
!!! tip "Structural design - beam deflection"
	You might already be familiar with beam deflection from the basic mechanics courses. In practive however, both the material properties of the beam as well as the loads it is subjected to can be variable. This problem is typical in engineering, where real-world conditions often introduce variability. In current building norms, this is covered by using safety coefficients that will underestimate the material properties and overestimate the load. 

	Suppose we want to minimise the weight of a beam (which depends on its length, width, and thickness). We also want the deflection of the beam must stay within limits, which is computed using a simplified beam deflection formula, subject to randomness in material properties (e.g., Young's modulus) and load (e.g., applied force).

	**Note:** for this simple example, we will consider a rectangular section, which is far from optimal, it simply serves to illustrate the point.
"""

# ╔═╡ e41e416c-f687-4493-9266-d107145b1f7e

begin
    
    # Define the stochastic beam deflection function using lognormal distribution
    function beam_deflection(x, material_variability=0.1, load_variability=0.2)
        length, width, thickness = x
        
        # Lognormal distribution for Young's modulus
        mean_log_E = log(2e11)
        std_log_E = material_variability
        Young_modulus = exp(randn() * std_log_E + mean_log_E)
        
        # Lognormal distribution for applied load
        mean_log_F = log(1000)
        std_log_F = load_variability
        applied_load = exp(randn() * std_log_F + mean_log_F)
        
        # Simplified beam deflection formula
        deflection = (applied_load * length^3) / (3 * Young_modulus * width * thickness^3)
        
        return deflection
    end

    # Define the objective function (total weight of the beam)
    function beam_weight(x)
        length, width, thickness = x
        density = 7800
        return density * length * width * thickness
    end

    # Define the combined objective function with stochastic deflection
    function objective(x)
        weight = beam_weight(x)
        # Estimate deflection with Monte Carlo
        deflection = 0.0
        num_samples = 500
        for _ in 1:num_samples
            deflection += beam_deflection(x)
        end
        expected_deflection = deflection / num_samples
        
        # Penalise if deflection exceeds limit (e.g., 5mm)
        if expected_deflection > 5e-3
            penalty = 1e7 * (expected_deflection - 5e-3)^2  # Stronger quadratic penalty
        else
            penalty = 0.0
        end
        
        return weight + penalty
    end

    # Set bounds for the beam dimensions
    lower_bound = [1.0, 0.1, 0.01]
    upper_bound = [10.0, 1.0, 0.1]
    
    # Set initial guess
    initial_guess = [5.0, 0.5, 0.05]

    # Run box-constrained Nelder-Mead method
    res = optimize(objective, lower_bound, upper_bound, initial_guess)
    res.minimizer
end

# ╔═╡ 5be46829-11b4-4705-b3f8-9bced947f307
begin
	# Make an illustration of the beam deflection
    p = plot()
    for (i, (dimensions, label)) in enumerate([(lower_bound, "lower bounds"), (upper_bound, "upper bounds"), (initial_guess, "initial guess"), (res.minimizer, "optimal solution")])
        @info "Beam dimensions $(label): $(dimensions)"
		# Note: we sample other values at random here, than the ones we optimized on.
        deflection = [beam_deflection(dimensions) for _ in 1:100]
        weight = [beam_weight(dimensions) for _ in 1:100]
        violin!(repeat([i], length(deflection)), deflection, label="$(label)  - $(round(Int, mean(weight))) [kg]", alpha=0.5)
    end
    plot!(xlabel="Beam index", ylabel="Deflection (m)", title="Beam Deflection with stochastic parameters", legend=:topright, yscale=:log10)
	
    # Display the plot
    p
end

# ╔═╡ 9e17f334-cad1-4c62-8ab9-f23a4443057b
md"""# Example problems"""

# ╔═╡ 76d17e1b-1d1a-48f5-ab73-e07fdc884cce
md"""
## Unmanned Combat-Air-Patrol (UCAP) Allocation
!!! tip ""
	A joint-forces commander must assign a fleet of long-endurance unmanned combat aerial vehicles (UCAVs) to patrol six coastal sectors that guard a strategic strait.  
	
	Mission goals & resources:

	* Every sector ``j`` needs ``H_j`` patrol hours per day (``j \in {1,…,6}``).  
	* The squadron has 10 identical UCAVs. Each can fly at most 10 h before landing for a 2 h turnaround (refuel + re-arm).  
	* Launch and recovery happen at two airbases (A and B). Each base has 4 simultaneous ramp slots.  
	* Patrolling sector ``j`` from base b consumes ``C_j^b`` kg of fuel per hour (different distances), and total daily fuel available at each base is variable ``F^b_{\text{max}}``.  
	* While on-station, sector ``j`` exposes the aircraft to a risk score ``R_j  \in [0,1]`` (with higher being more hostile).
	* Objective: satisfy all patrol-hour requirements while minimising cumulative risk-weighted flight hours.
"""

# ╔═╡ 085e1fa2-34ba-427e-851b-0465138f6710
begin
UCAP_dv_content = md"""
	We can propose the following variables:
	* ``x_{ij}^b``: daily flight hours that UCAV $i$ flies in sector $j$ from base $b$ (continuous and ``\ge 0``).
	* ``u_i^b``: UCAV $i$ operates at base $b$ on a given day (binary).

	Additionaly, we should also consider the following parameters:
	* ``N``= number of UCAV (10)
	* ``j``: set of sectors (1 - 6)
	* ``H_j``: number of daily coverage required at sector $j$.
	* ``F``: maximum daily flight time: 20 hours, assuming this mission is running 24/7 (10 h on-station + 2 h turnaround => 2 cycles/day)
	* ``R_j``: risk in sector $j$.
	* ``C_j^{b}``: fuel use (kg h⁻¹) for sector $j$ from base *b*
	* ``F_{\max}^{b}``: fuel available at base $b$ per day (kg)
	* ``B_{\max}``: number of simultaneous ramp slots
	"""
	UCAP_dv = PlutoUI.details("Variables", UCAP_dv_content, open=false)

UCAP_obj_content = md"""
We want to minimize the risk-weighted exposure
```math
\min \; \sum_{i=1}^{N}\sum_{b\in\{A,B\}}\sum_{j=1}^{6} R_j \, x_{ij}^{b},
```
where $i$ is the index of the UCAP, and $b$ the index assigment to the base.	
"""
	UCAP_obj = PlutoUI.details("Objective function", UCAP_obj_content, open=false)
	
UCAP_constraints_content = md"""
We from the problem description, we can identify the following constraints:
1. sufficient patrol hour coverage	
```math
\sum_{i=1}^{N}\sum_{b\in\{A,B\}} x_{ij}^{b} \;\; \ge \;\; H_j, 
\qquad \forall j=1,\dots,6
```
2. respect daily flight-time limits:
```math
\sum_{b}\sum_{j} x_{ij}^{b} \;\; \le \;\; F,
\qquad \forall i=1,\dots,N
```	
3. physical limitations of a specific base:
```math
\sum_{i=1}^{N} u_{i}^{b} \;\; \le \;\; B_{\text{max}},
\qquad b\in\{A,B\}
```		
4. each UVAC can be on one base only
```math
\sum_{b} u_{i}^{b} = 1 \qquad \forall i
```	
5. allocated flight times should be linked to the base the UCAV is assigned to
```math
x_{ij}^b \le F u_i^b \qquad \forall i,j,b
```	
6. account for fuel limits on each base
```math
\sum_{i=1}^{N} \sum_{j} C_j^b x_{ij}^b \le F_{\max}^{b}  \qquad \forall b
```		
"""
UCAP_constraints = PlutoUI.details("Constraints", UCAP_constraints_content, open=false)
	PlutoUI.details("Problem analysis", [ UCAP_dv; UCAP_obj;UCAP_constraints], open=true)
end

# ╔═╡ 5319e52e-f9ff-4aac-8bc9-8dfa378ce2cd
let
	N = 10 # number of UCAV
	J = 6  # number ofsectors
	B = 2  # number of bases
	F = 20 # flight time per day for a single UCAV
	model = Model(GLPK.Optimizer)
	H = rand(2:24, J) # minimal daily coverage
	R = rand(J)      # risk factor
	B_max = 5 # number of simultaneous ramps
	C = hcat(rand(20:50, J), rand(40:80, J))
	F_max = [1500;2500]
	@variable(model, x[1:N, 1:J, 1:B] ≥ 0)
	@variable(model, u[1:N, 1:B], Bin)
	
	@objective(model, Min, sum(R[j] * x[i,j,b] for i in 1:N, j in 1:J, b in 1:B))
	
	@constraint(model, [j in 1:J],   sum(x[i,j,b] for i in 1:N, b in 1:B) ≥ H[j])
	@constraint(model, [i in 1:N],   sum(x[i,j,b] for j in J, b in 1:B) ≤ F)
	@constraint(model, [b in 1:B],   sum(u[i,b]   for i in 1:N) ≤ B_max)
	@constraint(model, [i in 1:N],   sum(u[i,b]   for b in 1:B)  == 1)
	@constraint(model, [i in 1:N, j in 1:J, b in 1:B],     x[i,j,b] ≤ F * u[i,b])
	@constraint(model, [b in 1:B],   sum(C[j,b] * x[i,j,b] for i in 1:N, j in 1:J) ≤ F_max[b])
	
	optimize!(model)

	if termination_status(model) == OPTIMAL
		@info value.(x)
	else
		@warn "No optimal solution could be found 🤬" 
	end
end

# ╔═╡ 0d4134cd-960f-4ffa-abae-f67be8b05e47
md"""
!!! warning "Go beyond - food for thought"
	* are there any implicit assumption? Which ones? Is this a problem? How to solve this?
	* how to add staggered flight windows, or distinct UCAV types?
"""

# ╔═╡ 15b9fe89-bde2-4f82-85c7-20314c3499a3
md"## Electronic Warfare (EW) asset assignment under uncertainty"

# ╔═╡ 868942c1-c331-43de-9751-94d34df64d0e
md"""
!!! tip ""
	You are supporting a mission with EW assets that will be used to saturate the adversary's early warning radars (EWR), in order to help facilitate a strike undetected. You have two airborne jammer assets that fly out from an aircraft carrier. Once in place, they orbit their loiter point for 90 minutes before heading back to the carrier.
	Your task is to find a positioning of the jammer assets that saturates the EWRs, and at the same time, we want to __maximise the expected residual jamming margin__, in order to be able to take on additional taskings.


	**Mission specifics**:
	* The carrier is located in (0, -150);
	* Adversary EWRs are located at (0,0), (120, 50), and (210, 30). An EWR is out-of-service, if the combination of the receiver power (i.e. the sum) from the jammers exceeds ``S_{\text{min}} = 1.8 \times 10^{-4} [Wm^{-2}]``;
	* The jammer assets need to stay within a 300km range from the carrier;
	* The EWR ``j`` receives an instantaneous power density from jammer ``h`` as follows:
	  ```math
	  S_{hj}(\omega) = \frac{P_h}{4\pi d_{hj}^2} \kappa(\omega),
	  ```
	  where ``P_h`` is the power transmitted from jammer ``h``, ``d_{hj}`` is the distance between the jammer and the EWR, and ``\kappa(\omega)`` a an [atmospheric ducting](https://en.wikipedia.org/wiki/Atmospheric_duct) multiplier. ``\kappa(\omega)`` follows a [log-normal distribution](https://en.wikipedia.org/wiki/Log-normal_distribution), centered on ``0``, with a standard deviation of ``0.25``;
	* The jammers have a limited amount of fuel (7 tonnes). For a specific loiter point for asset ``h``, the fuel consumption can be modelled as follows:
	  ```math
	  F_h = 1.2 + 0.06 d_h + 2 P_h^{1.3},
	  ```
	  where ``d_h`` is the distance between the loiter point of asset ``h`` and the carrier, and ``P_h`` is the power transmitted from jammer ``h``

	**Illustration**:
"""

# ╔═╡ fa9e13f2-de57-4edb-9952-6cc1ad1ee412
let	
	# Define the received_power function
	function received_power(loiter_point, P, target, k)
	    d = sqrt((loiter_point[1] - target[1])^2 + (loiter_point[2] - target[2])^2)
	    d = max(d, 1e-2) # Increase minimum distance to reduce max Z
	    S = P / (4 * π * d^2) * k
	    return S
	end
	
	# Define parameters
	carrier = (0, -150)
	rₕ = 300
	EWR = [(0, 0), (120, 50), (210, 30)]
	assets = [(-150, -50), (150, -50)]
	P = [0.0002, 0.00015] # power per asset
	κ = LogNormal(0, 0.25)
	k = rand(κ) # Sample k from LogNormal distribution
	
	# Create grid of coordinates
	x = -300:5:300
	y = -200:5:200
	
	# Create grid
	X = [xi for xi in x, _ in y]
	Y = [yi for _ in x, yi in y]
	
	# Compute received power from each asset for each point in the grid
	Z = [received_power(assets[1], P[1], (xi,yi), k) for xi in x, yi in y] .+ 
		[received_power(assets[2], P[2], (xi,yi), k) for xi in x, yi in y]
	
	
	# Clip Z to avoid extremely large values and ensure positive (some artifacts with close points)
	Z = clamp.(Z, 1e-10, 1e5)
	
	# Create combined plot
	p = contour(x, y, log10.(Z'), # Transpose Z to match x[i], y[j]
	    fill=true, 
	    color=:turbo, 
	    clims=(-10, -2), # Limit log10(Z) to [-5, 0] (10^-5 to 10^0 W/m²)
	    colorbar_ticks=([-5, -4, -3, -2, -1, 0], [L"10^{-5}", L"10^{-4}", L"10^{-3}", L"10^{-2}", L"10^{-1}", L"10^{0}"]),
	    title="Received Power (RP) contour plot",
	    xlabel="X",
	    ylabel="Y",
	    colorbar_title=L"\log_{10}(RP) \; [W/m^2]",
	    levels=9, 
	    right_margin=10mm)
	scatter!(carrier, label="Carrier", color=:grey, alpha=1., marker=:square, markersize=8)
	scatter!(assets, label="Jammers", color=:grey, alpha=1., marker=:cross, markersize=8)
	plot!(carrier[1] .+ rₕ .* cos.(range(0, 2*pi, length=100)), carrier[2] .+ rₕ .* sin.(range(0, 2*pi, length=100)), 
	      color=:grey, alpha=0.5, linestyle=:dash, label="Asset deployment range")
	scatter!(EWR, label="EWR", color=:red, marker=:diamond, markersize=8)
	plot!(xlims=(-300, 300), ylims=(-200, 200)) # Set limits for x and y axes
end

# ╔═╡ 40d9a168-0821-4d7e-b8c2-38f8ba7d27a3
begin
EW_rand_content = Markdown.parse("""
For this application, we can consider two different approaches because the stochastic aspect is limited (only the ducting effect), and we know its distribution:

1. Use the known distribution:

   Suppose we want to be fairly certain to suppress the adversary EWRs with our EW measures, for example, 90% sure that we will jam enough. You can simply use the inverse of the log-normal distribution, i.e., find ``x`` such that ``P(X \\leq x) = 0.90``, with ``X \\sim \\text{Lognormal}(\\mu=0, \\sigma=0.25)``. We could call this ``\\kappa_{\\text{crit}}``

   ```julia
   dist = LogNormal(0, 0.25)
   x = quantile(dist, 0.90)
   ```
   ```
   1.3776620439479017
   ```

								 

2. Sample from the distribution:

   Alternatively, you can sample from the log-normal distribution to simulate the effect of the EW measures. We could call this vector ``\\bar{\\kappa}``.

   ```julia
   k = rand(LogNormal(0, 0.25), 100)
   ```
""")
	EW_rand = PlutoUI.details("Dealing with uncertainty", EW_rand_content, open=false)

EW_dv_content = md"""
	We can identify the following decision variables: ``(x_h, y_h, P_h), \; h \in [1, 2]``, 
	associated with the horizontal and vertical position, and the emited power of every asset respectively.

	We can also define the threshold power required for saturation of the adversaries' EWRs: ``S_{\text{min}} = 1.8 \times 10^{-5} [Wm^{-2}]``
	"""
	EW_dv = PlutoUI.details("Variables", EW_dv_content, open=false)

EW_obj_content = md"""
Suppose we are using the sampling approach, the objective function expressing the expected residual jamming capacity can be written as follows:
```math
\max_{x_h, y_h, P_h} \frac{1}{N} \sum_{s=1}^{N} \sum_{j=1}^{3} \left( \sum_{h=1}^{2}\frac{P_h \kappa_s}{4\pi d_{hj}^2} - S_{\text{min}} \right)_{+},
```
where $h$ indicates the index of the EW assets, $j$ indicates the index of the EWRs, and $s$ indicates the index of atmospheric conduct parameter. The notation $(\cdot)_+ = \max{(0, \cdot)}$, this makes sure that the residual value is positive.
"""
	EW_obj = PlutoUI.details("Objective function", EW_obj_content, open=false)
	
EW_constraints_content = md"""
Again, assuming we are using the sampling approach, we can write the constraint related to the suppression of the EWRs as follows:
```math
\frac{1}{N}\sum_{s=1}^{N} \mathbf{1}\left( \sum_{h=1}^{2}\frac{P_h \kappa_s}{4\pi d_{hj}^2} \ge S_{\text{min}} \right) \ge 0.9 \;\; \forall j = 1,2,3.
```
In the above equation, $\mathbf{1}$ is the [indicator function](https://en.wikipedia.org/wiki/Indicator_function), which returns one if the argument is true, and zero otherwise.

The fuel constraints are obtained almost directly from the problem statement:
```math
1.2 + 0.06 d_h + 2 P_h^{1.3} \le 7  \;\; \forall h = 1,2.
```

The emission constraints are also directly obtained:
```math
0 \le P_h \le 6  \;\; \forall h = 1,2.
```	

Finally, we should also make sure our assest remain within recoverable distance of the carrier:
```math
0 \le \sqrt{(x_h - x_c)^2 + (y_c - y_c)^2} \le 300  \;\; \forall h = 1,2.
```	
In the above equation $(x_c, y_c)$ refers to the carrier position.
	
"""
EW_constraints = PlutoUI.details("Constraints", EW_constraints_content, open=false)
	PlutoUI.details("Problem analysis", [EW_rand; EW_dv; EW_obj;EW_constraints], open=true)
end

# ╔═╡ 3b379685-636b-48b6-b797-5c4fce3ddc8d
let	
	function received_power(loiter_point, P, target, k)
	# Calculate the distance from the loiter point to the target EWR
    d = sqrt((loiter_point[1] - target[1])^2 + (loiter_point[2] - target[2])^2)
	# Calculate the received power at the target EWR, accounting for the atmospheric ducting multiplier
	S = P / (4 * π * d^2) * k
	return S
	end
		
	# Define parameters
	(x_c, y_c) = (0, -150) 		# carrier location
	rₕ = 300 					# max radius from carrier
	P_max = 6 				 	# max power emission
	P_jam = 0.9 				# desired certainty of jamming the EWRs
	EWR = [(0, 0), 				# EWR locations	
		   (120, 50), 
		   (210, 30)]
	S_min = 1.8e-5
	κ = LogNormal(0, 0.25)
	N = 10  					# number of samples
	k = rand(κ, N) 				# Atmospheric conduct coefficient sample

	# setup model
	model = Model(Ipopt.Optimizer)
	set_attribute(model, "print_level", 0) # to limit the solver's output
	set_optimizer_attribute(model, "max_iter", 3000) # set max iterations for the solver

	@variable(model, x[1:2]) # asset horizontal location
	set_start_value(x[1], 20)
	set_start_value(x[2], 50)
	@variable(model, y[1:2]) # asset vertical location
	set_start_value(y[1],50)
	set_start_value(y[2],30)
	@variable(model, P[1:2]) # power emission
	set_start_value(P[1], 0.2)
	set_start_value(P[2], 0.5)

	# add objective
	@NLobjective(model, Max, sum(sum(max(0, P[h] * k[s] / (4 * pi * sqrt((x[h] - EWR[j][1])^2 + (y[h] - EWR[j][2])^2) + 1e-3) - S_min) for h in 1:length(x)) for j in 1:length(EWR), s in 1:N))

	
	# add constraints
	for j in 1:length(EWR)
		# exact version (some issues with the double inequality, can be solved by transforming into a mixed integer problem)
		#@constraint(model, sum( P[h] * k[s] / (4 * pi * sqrt((x[h] - EWR[j][1])^2 + (y[h] - EWR[j][2])^2)) ≥ S_min for h in 1:length(x), s in 1:N) / N ≥ P_jam)
		# simplified version
		@NLconstraint(model, sum(P[h] * k[s] / (4 * pi * sqrt((x[h] - EWR[j][1])^2 + (y[h] - EWR[j][2])^2)  + 1e-3 ) for h in 1:length(x), s in 1:N) / N ≥ P_jam * S_min)
	end
	for h in 1:length(x)
		d_h = sqrt( (x_c - x[h])^2 + (y_c - y[h])^2  + 1e-3)
		@NLconstraint(model, d_h ≤ rₕ)
		@NLconstraint(model, 1.2 + 0.06 * d_h + 2 * P[h] ^ (1.3) ≤ 7)
		@NLconstraint(model, P[h] ≥ 0) # power emission must be non-negative
		@NLconstraint(model, P[h] ≤ P_max) # power emission must be less than max
		@constraint(model, x[h] >= -300) # asset horizontal location must be greater than -300
		@constraint(model, x[h] <= 300) # asset horizontal location must be less than 300
		@constraint(model, y[h] >= -300) # asset vertical location must be greater than -450
		@constraint(model, y[h] <= 300) # asset vertical location must be less than 150
	end
	
	@NLconstraint(model, sqrt((x[1] - x[2])^2 + (y[1] - y[2])^2) ≥ 100) # ensure a minimum distance between the two assets

	# Optimize
    optimize!(model)

	@info termination_status(model)

	# Get results
	x_opt = value.(x)
	y_opt = value.(y)
	P_opt = value.(P)
	@info "Optimal asset locations: $(x_opt), $(y_opt)"
	@info "Optimal power emissions: $(P_opt)"

	# Plot results
	plot()
	# Create grid of coordinates
	xx = -300:5:300
	yy = -500:5:200

	# Create grid
	X = [xi for xi in xx, _ in yy]
	Y = [yi for _ in xx, yi in yy]

	# Compute received power for each point in the grid
	Z = [received_power((x_opt[1], y_opt[1]), P_opt[1], (xi,yi), k[1]) for xi in xx, yi in yy] .+ 
		[received_power((x_opt[2], y_opt[2]), P_opt[2], (xi,yi), k[2]) for xi in xx, yi in yy]


	# Clip Z to avoid extremely large values and ensure positive
	Z = clamp.(Z, 1e-10, 1e5)

	# Create combined plot
	contour(xx, yy, log10.(Z'), # Transpose Z to match x[i], y[j]
    fill=true, 
    color=:turbo, 
    clims=(-6, 0), # Limit log10(Z) to [-5, 0] (10^-5 to 10^0 W/m²)
    colorbar_ticks=([-5, -4, -3, -2, -1, 0], [L"10^{-5}", L"10^{-4}", L"10^{-3}", L"10^{-2}", L"10^{-1}", L"10^{0}"]),
    title="Received Power (RP) contour plot",
    xlabel="X",
    ylabel="Y",
    colorbar_title=L"\log_{10}(RP) \; [W/m^2]",
    levels=12, 
    right_margin=10mm)
	scatter!([x_c], [y_c], label="Carrier", color=:green, alpha=0.5, marker=:square, markersize=8)
	scatter!([(x_opt[i], y_opt[i]) for i in 1:length(x_opt)], label="Jammers", color=:green, alpha=0.5, marker=:circle, markersize=8)
	plot!(x_c .+ rₕ .* cos.(range(0, 2*pi, length=100)), y_c .+ rₕ .* sin.(range(0, 2*pi, length=100)), color=:green, alpha=0.5, linestyle=:dash, label="Asset deployment range")
	# add carrier, jammers, and EWRs
	scatter!([(EWR[i][1], EWR[i][2]) for i in 1:length(EWR)], label="EWR", color=:red, marker=:diamond, markersize=8)

	plot!(title="Optimal Asset Deployment (local optimum)", xlabel="X coordinate", ylabel="Y coordinate")
end

# ╔═╡ cb948119-db02-441a-86ec-d50a7c34983f
md"""
!!! warning "Go beyond - food for thought"
	* is the number of samples we used adequate?
	* what is the impact of the shape of the distribution?
	* how to add additional contrainst? E.g. a no-fly zone?
	* could other solution methods also be suited? If so, which ones, and why?
"""

# ╔═╡ Cell order:
# ╟─a76ef974-2046-11f0-240d-e5aa708db0e9
# ╟─ddac3c21-7ac9-4295-aeca-a8f460c1f3b1
# ╠═27e916ea-958c-4df8-b861-b2674798cee9
# ╟─7f3b10fe-8a8e-49ba-a468-a7fa0cb8c17d
# ╟─19bc12c5-2d3c-46dc-bb9b-02efe0882295
# ╟─3e7cdf87-e064-4746-abd3-8ca6a702a0fe
# ╟─561c3509-a1d4-43f4-a1ba-a55dbdfb0620
# ╟─a0c4e07f-504d-426e-8d9f-7a212855888f
# ╟─f195819d-4ca2-4f57-8fe9-17d0b57d477a
# ╟─13707c2b-6eb9-4a5d-885e-39d48b3c9bae
# ╟─0ea96b49-8bd4-49fe-834a-b93865f5541b
# ╟─cec44eec-ac69-47ac-9ad3-bfb58fc0a0ec
# ╠═b1144ca2-087c-4ba7-ae77-ae9b6073a642
# ╠═102e0051-dbfb-45e0-871d-db0a0d07abb1
# ╠═86e70877-1f9c-4634-9f5a-94659bfab519
# ╟─d4b05c5e-ac08-4a69-b54c-5d825d864bfa
# ╟─1450d898-5e03-4b54-a1ba-bf3d0f659d25
# ╟─9e9a1b5c-a78f-414c-b99e-328e96061542
# ╟─ff3de131-b74b-4924-aa3f-4954f4b0ecca
# ╟─110a345d-70dd-40eb-bc1f-1a4d4c9c1926
# ╟─22915619-cd8f-4fef-a328-3cb7ba999946
# ╟─a768a6d1-b9af-4c42-877b-9eb55cdee7d8
# ╟─65ad9943-df85-43b2-aa28-f6e91da11e83
# ╟─b0d7d73b-49ba-45f6-9547-72b47c1f51ba
# ╟─1af7b9e6-43e0-4f32-b0bc-2bd5edd52c8a
# ╠═8784b29e-52be-4233-aec7-109e3233fecb
# ╟─84d6d961-d5a7-4ebb-a1f5-f79f4dad19a4
# ╠═f827a728-8111-4b7e-a8b0-821dc6454688
# ╟─1e31e88d-265f-4de6-bd98-8465ddb5cb5a
# ╠═12bfc573-4b38-499f-89c0-49e6ea70759f
# ╟─484fd731-6add-4f8f-a897-0f0b5d48d7aa
# ╠═232fc07c-ed6d-4287-8dac-a0f7e10756fc
# ╟─c09cb716-15b6-41d1-a016-cf76b5b7efaf
# ╠═12699940-fa1c-454a-9692-11f5c3e97909
# ╟─5f685c6b-6177-4992-86aa-f788d2727217
# ╠═242719f3-2191-4e7f-878b-5fc7fe6f5080
# ╟─1a29e47e-8495-4eca-95ea-971661fc615b
# ╠═dc757906-2b34-4341-96ad-237a3cfcbfeb
# ╟─b3fd0b39-ca17-49e5-adec-552a69e386f8
# ╟─ce5cea4c-17a0-4c12-b2f0-3b2ba705954e
# ╟─5819029f-796f-43ff-a079-5fa95b3fb011
# ╟─c0d3cda6-2506-40be-8fa1-51c604d7f548
# ╟─5ec1071f-cfaf-404a-a468-efd0f76d709e
# ╟─c06bd9c8-f489-42a4-8a6d-162f4864ba19
# ╟─b5c4010d-f373-4a5b-8e14-275fb45c5292
# ╟─afb498db-dc05-49c3-baad-d4bca7d2cc27
# ╟─3f38a7f9-d64a-4eca-8205-72cfee88bb4d
# ╟─7d2cb249-0d7f-4a69-9f33-4fac6e22f58b
# ╠═b949506d-936a-4c5b-8724-1a71e86b5397
# ╟─3e9afcf2-601b-4965-a738-37b4b5e2638c
# ╟─0293ad9d-d058-4467-874b-d8c51ed2882e
# ╟─d85aaa13-555a-465f-8f8e-3732978cae7c
# ╟─81955573-23b9-4af7-82bf-e6b21cdd36b7
# ╟─053779d8-056b-46fe-bee8-c151132639c1
# ╟─40833da5-cfcc-4fe1-bdeb-9a1aa4b34f57
# ╟─e41e416c-f687-4493-9266-d107145b1f7e
# ╟─5be46829-11b4-4705-b3f8-9bced947f307
# ╟─9e17f334-cad1-4c62-8ab9-f23a4443057b
# ╟─76d17e1b-1d1a-48f5-ab73-e07fdc884cce
# ╟─085e1fa2-34ba-427e-851b-0465138f6710
# ╠═5319e52e-f9ff-4aac-8bc9-8dfa378ce2cd
# ╟─0d4134cd-960f-4ffa-abae-f67be8b05e47
# ╟─15b9fe89-bde2-4f82-85c7-20314c3499a3
# ╟─868942c1-c331-43de-9751-94d34df64d0e
# ╟─fa9e13f2-de57-4edb-9952-6cc1ad1ee412
# ╟─40d9a168-0821-4d7e-b8c2-38f8ba7d27a3
# ╟─3b379685-636b-48b6-b797-5c4fce3ddc8d
# ╟─cb948119-db02-441a-86ec-d50a7c34983f
