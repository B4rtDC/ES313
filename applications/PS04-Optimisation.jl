### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ c175a542-11d4-49f1-a872-2053d81d5ade
begin
	# Pkg needs to be used to force Pluto to use the current project instead of making an environment for each notebook
	using Pkg
	# this is redundant if you run it through start.jl, but to make sure...
	while !isfile("Project.toml") && !isdir("Project.toml")
        cd("..")
    end
    Pkg.activate(pwd())
end

# ╔═╡ f1068fca-0331-11eb-20de-a98c65d5c2dc
begin
	using Optim, Plots
    using Distributions
	using JuMP, Ipopt
	using LaTeXStrings
	using LinearAlgebra
	using Tulip, GLPK
	using StatsPlots, Measures
	using PlutoUI
	PlutoUI.TableOfContents()
end

# ╔═╡ 543d9901-6bdc-4ca5-bfac-800f543c3490
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

# ╔═╡ 72ad677c-738f-4e62-afcb-c5260ff9a79e
md"""
# Optimization Libraries and Toolboxes: A Cross-Language Survey
During the lectures, a detailed overview of the most commonly available optimization techniques was provided. You saw a variety of practical implementations in the Julia coding language. With this short overview, we wish to highlight how these techniques can be used in other common programming languages. You will notice how the same optimization techniques take on different forms.

*Note: This list is not in any way exhaustive. The choice of optimizer will always depend on the particularities of the project you are working on.*

## MATLAB

As a student, you have never experienced the financial consequences of using MATLAB. For professional use, licenses can easily become very expensive. However, for this high price, the MATLAB code is always well maintained, with seamless integration and interoperability.

Therefore, all optimization tools are integrated in the [Optimization Toolbox](https://nl.mathworks.com/products/optimization.html), which offers both a command line interface and a graphical user interface. We highly recommend experimenting with these modules. 

!!! warning "Installation"
	The `Optimization Toolbox` needs to be added as a package to your MATLAB installation.

The primary [functions](https://nl.mathworks.com/help/matlab/optimization.html) are:

| Optimizer | Application |
| :-- | :-- |
| `fminbnd` |	Find local minimum of single-variable function on fixed interval
| `fminsearch` | Search for local minimum of unconstrained multivariable function using derivative-free method
| `lsqnonneg` | Solve nonnegative linear least-squares problem

Or simply call `Optimize` in the live editor. Your optimization procedure can be customized by using the function `optimset`.

The interested student is highly recommended to go through the 'Getting Started' section on the [MathWorks Website](https://nl.mathworks.com/help/optim/getting-started-with-optimization-toolbox.html), where you can find easily accessible tutorials, further information and even instructive videos.

## Python

Python is a widely used, high-level, open-source programming language known for its readability, simplicity, and versatility. Python is easy to learn and write, comes with extensive library support and is carried by a large community. However, the language often lacks performance and is memory intensive.

When considering optimization, the [Scipy Optimization](https://docs.scipy.org/doc/scipy/tutorial/optimize.html) library provides a variety of tools:

* Local minimization of multivariate scalar functions (`minimize`)
* Constrained minimization
* Global optimization
* Least-squares minimization (`least-squares`)
* Univariate function minimizers
* Custom minimizers
* Linear Programming
* Etc.

SciPy offers functionality for optimization, integration, interpolation, linear algebra, eigenvalue problems, algebraic and differential equations, statistics, signal and image processing, and much more. It uses numpy arrays as its basic data structure and adds specialised algorithms. The code is mostly written in Python, but critical parts are implemented in compiled languages like C and Fortran.

## C and C++

C and C++ are both compiled languages, which means they become pertinent when performance is key. Contrarily to the aforementioned examples, they do not have one reference package. You can thus resort to:

| Package | Information |
| :-- | :-- |
| [Ceres Solver](http://ceres-solver.org) | Open source library for modeling and solving large, complicated opimization problems. |
| [OptimLib](https://optimlib.readthedocs.io/en/latest/) | Lightweight library of numerical optimization methods for nonlinear functions. |
| [OR-Tools]() | OR-Tools is open source software for combinatorial optimization. It is written in C++, but you can also use it with Python, Java, or .Net. |
| Etc. | |

## What to choose?

More often than not, a programming language is chosen for you. In larger frameworks, letting everyone pick their own language quickly becomes messy—though it still happens. As a result, you’ll often need to adapt to the limitations in front of you, which means familiarizing yourself with the language’s syntax, core principles, and available packages. Learning to code program independently is a valuable skill.

"""

# ╔═╡ b4764948-0330-11eb-3669-974d75ab1134
md"""
# Optimisation Techniques in Julia

In this section, we will cover some practical examples and implementations of the optimisation techniques seen in the lectures. For all practical purposes, we will exploit the appropriate libraries.

"""

# ╔═╡ 1b769f0c-0332-11eb-1efb-178c1985f3df
md"""
We will be using [`Optim`](https://julianlsolvers.github.io/Optim.jl/stable/) for several applications, in both uni- and multivariate optimization. For linear programming, we wil be using [JuMP](https://jump.dev/JuMP.jl/stable/) as a general framework, combined with [Tulip](https://github.com/ds4dm/Tulip.jl) or [GLPK](https://github.com/jump-dev/GLPK.jl) as a solver.
"""

# ╔═╡ 165f35b0-0332-11eb-12e7-f7939d389e58
md"""
## Unconstrained optimisation


!!! tip "Reminder"
	The general formulation of an unconstrained optimization problem is:

	```math
	\min f\left(\vec x\right)
	```

### Optimizing a function without gradient information
#### Straightforward example
For a univariation function, you need to provide an upper and lower bound
```Julia
optimize(f, lower, upper)
```
Try to optimize $x^3 - 6x + x^2 +2$
!!! info "Tasks"
	* Compare the result between both methods (`Brent()` vs `GoldenSection()`).
	* Intermediate results can be stored by using the `store_trace=true` keyword argument. The type of the returned object is `Optim.UnivariateOptimizationResults`. The numerical value of each entry can be read by using `.value`.
	* Illustrate the evolution of the estimated optimum.
"""

# ╔═╡ 77d89aa8-07d2-11eb-1bbd-a5c896e3ecfe
begin
	f(x) =  x .^3 - 6 * x + x.^2 + 2
	df(x) = 3 .* x .^2 .- 6 + 2 .* x
	res_brent = optimize(f, 0, 10, Optim.Brent(), store_trace=true)
	res_golden = optimize(f, 0, 10, Optim.GoldenSection(), store_trace=true)
	res_brent.trace
end

# ╔═╡ f27797e5-b83f-4375-ab17-480c09fd7b7f
let
	# generating the illustration
	x = range(0,5, length=100)
	p0 = plot(x, f.(x), label=L"f(x)", legendposition=:topleft, title="function evolution")
	p1 = plot([v.iteration for v in res_brent.trace], [v.value for v in res_brent.trace], label="brent method", marker=:circle)
	plot!([v.iteration for v in res_golden.trace], [v.value for v in res_golden.trace], label="golden section method", marker=:circle, markeralpha=0.5)
	title!("function value")
	p2 = plot([v.iteration for v in res_brent.trace], [v.metadata["minimizer"] for v in res_brent.trace], label="brent method", marker=:circle)
	plot!([v.iteration for v in res_golden.trace], [v.metadata["minimizer"] for v in res_golden.trace], label="golden section method", marker=:circle, markeralpha=0.5)
	title!("minimizer")
	xlabel!(p1,"Iteration")
	plot(p0, p1,p2, layout=(1,3), size=(900, 300))
	
end

# ╔═╡ e6294d6a-0334-11eb-3829-51ee2b8cadaf
md"""
#### Data fitting
Suppose we have a random periodic signal with noise, i.e. $y_i = a \sin(x_i-b) + c + \epsilon_i$ and we wish to determine the values of $a,b$ and $c$ that minimize the difference between the “model” and the measured points.

!!! info "Tasks"
	* Define an error function
	* Determine possible values for $a,b$ and $c$
	* What is the effect of the initial values? Make an illustration of the error for different starting values.
"""

# ╔═╡ 66be5114-0335-11eb-01a9-c594b92937bf
# data generation (simulated sample)
begin
	# actual values
	a = 3; b = pi/3; c=10; 
	# noise distribution
	e=Normal(0,0.1)
	# function
	F(x;a=a,b=b,c=c) = a*sin.(x .- b) .+ c
	# sample length
	n = 10;
	# domain
	xmin = 0; xmax = 20
	d=Uniform(xmin, xmax)
	# random data points (independent variable)
	x = sort(rand(d, n))
	# dependent variable with noise
	y = F.(x) .+ rand(e,n);
end

# ╔═╡ 15ef34dc-0336-11eb-0de5-b942e8871db8
# illustration
begin
	settings = Dict(:xlabel=>"x",:ylabel=>"y",:title=>"a sin(x - b) + c")
	X = range(xmin, xmax, length=50)
	scatter(x,y, label="sample")
	plot!(X,F.(X), label="ground truth"; settings...)
end

# ╔═╡ e949078a-07d3-11eb-0146-8115e335b2e9
begin
	"""
		errfun(v, x=x, y=y)
	
	where v = [a;b;c ] holds the arguments to minimise F(x;a=a,b=b,c=c). Returns the RMSE for the parameter values
	"""
	function errfun(v, x=x, y=y)
		a,b,c = v
		ŷ = F.(x,a=a;b=b,c=c)
		return sqrt(sum((ŷ .- y ) .^2) / length(y))
	end
	
	res = optimize(errfun, Float64[1;1;1])
	a_opt, b_opt, c_opt = res.minimizer
	plot(X,F.(X), label="ground truth"; settings...)
	plot!(X, F.(X,a=a_opt, b=b_opt, c=c_opt), label="optimised"; settings...)
end

# ╔═╡ 901eed25-2aea-42a4-bd7e-68b919a8766c
res

# ╔═╡ 71d2bf30-0336-11eb-28ed-95518b9204a7
md"""
Compare the estimates:
* â: $(res.minimizer[1]) $$\leftrightarrow$$ a: $(a)
* b̂: $(res.minimizer[2]) $$\leftrightarrow$$ b: $(b)
* ĉ: $(res.minimizer[3]) $$\leftrightarrow$$ c: $(c)

with the original data. What do you observe? Can you explain this?
"""

# ╔═╡ add5faba-03b8-11eb-0cc7-15f19eb1e0e2
md"""
### Optimisation with gradient information
Suppose we want to minimize a function ``\mathbb{R}^3 \mapsto \mathbb{R}``:

``\min g(\bar{x}) = x_1 ^2 + 2.5\sin(x_2) - x_1^2x_2^2x_3^2 ``

!!! info "Tasks"
	Compare the results (computation time) using
	1. a zero order method (i.e. no gradients used)
	2. the function and its gradient (both [newton](https://www.youtube.com/watch?v=W7S94pq5Xuo) and [BFGS](https://www.youtube.com/watch?v=VIoWzHlz7k8) method)
	3. the function, its gradient and the hessian

You can evaluate the performance using the `@time` macro. For a more detailed and representative analysis, you can use the package [`BenchmarkTools`](https://github.com/JuliaCI/BenchmarkTools.jl) (we will go into detail in the session about performance)
"""

# ╔═╡ 9396ccae-03ba-11eb-27a9-1b88ee4fb45f
begin 
	g(x) = x[1]^2 + 2.5*sin(x[2]) - x[1]^2*x[2]^2*x[3]^2
	initial_x = [-0.6;-1.2; 0.135];
end

# ╔═╡ 94abb7a2-03bb-11eb-1ceb-1dff8aa3cce7
begin
	# gradients
	function dg!(G, x)
		G[1] = 2*x[1] - 2*x[1]*x[2]^2*x[3]^2
		G[2] = 2.5*cos(x[2]) - 2*x[1]^2*x[2]*x[3]^2
		G[3] = -2*x[1]^2*x[2]^2*x[3]
	end

	function h!(H,x)
		H[1,1] = 2 - 2*x[2]^2*x[3]^2 
		H[1,2] = -4*x[1]*x[2]*x[3]^2 
		H[1,3] = -4*x[1]*x[2]^2*x[3]
		H[2,1] = -4*x[1]*x[2]*x[3]^2 
		H[2,2] = -2.5*sin(x[2]) - 2*x[1]^2*x[3]^2
		H[2,3] = -4*x[1]^2*x[2]*x[3]
		H[3,1] = -4*x[1]*x[2]^2*x[3]
		H[3,2] = -4*x[1]^2*x[2]*x[3]
		H[3,3] = -2*x[1]^2*x[2]^2
	end
end

# ╔═╡ 6f552aa6-07d5-11eb-18a5-b32ed233c403
begin
	println("start method comparison")
	for _ in 1:2
		@time optimize(g, initial_x)
		@time optimize(g, dg!, initial_x, Newton())
		@time optimize(g, dg!, initial_x, BFGS())
		@time optimize(g, dg!, h!, initial_x)
	end
	println("finished method comparison")
end

# ╔═╡ 966b88dc-03bc-11eb-15a4-b5492ddf4ede
md"""
### Optimize the optimizer
You could study the influence of the optimization methods and try to optimize them as well (this is sometimes refered to as hyperparameter tuning). 

!!! info "Task"
	Try to create a method that minimizes the amount of iterations by modifying the parameter $\eta$ from the `BFGS` method, which can be seen as a particular implementation of the `ConjugateGradient` method.

**Note:** 
* Look at the documentation for possible values of $\eta$.
* This is merely as a proof of concept and will not come up with a significant improvement for this case.

"""

# ╔═╡ 68263aea-07d0-11eb-24f8-6383a3a1e09d
begin
	function optimme(η)
		res = optimize(g, dg!, initial_x, ConjugateGradient(eta=η))
		return res.iterations
	end
	
	optimize(optimme, 0, 20)
end

# ╔═╡ 0b83404d-2caf-4cdf-8418-7c8296a539ba
md"""
## Constrained optimisation

In this case, we have a function that needs to be minimised, subject to several constraints. We will cover the most general formulation of such a problem, before we cover specific cases:

!!! tip "Typical Problem Layout"
	```math
	\begin{align}
	\min_{\vec{x}}\, & f\left(\vec{x}\right)\, \textrm{subject to}\, \begin{cases}
	\vec{h}\left(\vec{x}\right)=\vec{0}\, \\
	\vec{g}\left(\vec{x}\right)\leq\vec{0}
	\end{cases}
	\end{align}
	```
	
	where  ``f:\mathbb{R}^{n}\rightarrow\mathbb{R}``, ``\vec{h}:\mathbb{R}^{n}\rightarrow\mathbb{R}^{m}``,
	``m\leq n, \text{and } \vec{g}:\mathbb{R}^{n}\rightarrow\mathbb{R}^{p}``.

However, if both your objective function and constraints are linear, the problem (and solutions methods) can be simplified.

!!! tip "Linear Programming"
	A linear program is an optimization problem of the form:
	
	```math
	\min_{\vec{x} \in \Omega } \vec{c}^\mathsf{T}\vec{x} \; \text{ subject to } 
	\cases{
	\mathbf{A}\vec x=\vec b\\
	\vec x\ge\vec 0}
	```
	where $\vec c\in\mathbb R^n$, $\vec b\in\mathbb R^m$ and $\mathbf A \in \mathbb R^{m\times n}$.

Making way for the application of the simplex and interior point methods.

!!! tip "Quadratic Programming"
	An optimization problem with a quadratic objective function and linear
	constraints is called a _quadratic program_. The general quadratic program can be stated as
	
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

Problems of this type are important in their own right, and they also arise as subproblems in methods for general constrained optimization such as sequential quadratic programming and interior-point methods.

!!! tip "Sequential Quadratic Programming"
	Sequential Quadratic Programming (SQP) is an iterative method used to solve constrained nonlinear optimization problems by approximating the original problem at each iteration with a quadratic programming subproblem. This subproblem minimizes a quadratic model of the objective function subject to linearized constraints derived from the original nonlinear constraints. By solving this sequence of quadratic programs, SQP efficiently handles nonlinear objectives and constraints, converging towards an optimal solution while incorporating derivative information such as gradients and Hessians.


"""

# ╔═╡ f23a8448-bd4e-4837-8ed9-c990d489a67e
md"""
### Linear Programming
!!! warning "Section on LP"
	For all practical purposes, the majority of the work in linear programming comes down to the appropriate mathematical translation of the problem you are trying to optimize. As these can become quite elaborate, we will cover them in a separate section.
"""

# ╔═╡ ec264b44-03c2-11eb-1695-cbf638f8cea9
md"""
### Sequential Quadratic Programming

SQP allows you to deal with nonlinear constraints.

Try to solve the following problem:
```math
\begin{align}
\min_{\bar{x}} f(\bar{x}) = -x_1 - x_2 \\
\text{ST:} \begin{cases}-x_1^2 + x_2 \ge 0\\1- x_1^2 - x_2^2 \ge 0\end{cases}
\end{align}
```

Solve the problem with [JuMP](https://github.com/jump-dev/JuMP.jl) (combined with [Ipopt](https://github.com/jump-dev/Ipopt.jl)).
"""

# ╔═╡ 053bae8a-087d-11eb-2e8c-73c41fb4e005
let 
	model = Model(Ipopt.Optimizer)
	@variable(model, x[1:2])
	@objective(model, Min, -x[1] - x[2])
	@constraint(model, - x[1] ^2 + x[2] >= 0)
	@constraint(model, 1 - x[1] ^2 - x[2] ^2 >= 0)
	optimize!(model)
	println(termination_status(model))
	println("minimum: $(objective_value(model))")
	value.(x)
end

# ╔═╡ b5cf333b-5ffa-45d5-b9c0-00abc4b63196
md"""
# Applications
## General Optimization
### More curve fitting


!!! tip "Setting"
	We want to recover an unknown function ``u(t)`` from noisy datapoints ``b_i``. As we do not know the actual underlying signal, we want to make sure that the resulting function is piecewise smooth.


!!! warning "Piecewise smooth function"
	A piecewise smooth function is can be broken into distinct pieces and on each piece both the functions and their derivatives, are continuous. A piecewise smooth function may not be continuous everywhere, however only a finite number of discontinuities are allowed.

For the **underlying signal**, we use the following function:
```math
b_p(t) = \begin{cases}1 & 0 \le t < 0.25 \\
				      2 & 0.25 \le t < 0.5\\
					  2 - 100(t-0.5)(0.7-t) & 0.5 \le t < 0.7 \\
					  4 & 0.7 \le t \le 1
\end{cases}
```

Given our unknown vector ``u``, which should be an approximation for ``b_i``, we consider the following **loss function** which needs to be minimized:
```math
\phi_1 = \frac{h}{2}\sum_{i=1}^{N}\frac{1}{2}\left[ (u_i - b_i)^2 + (u_{i-1} - b_{i-1})^2 \right]+ \frac{\beta h}{2}\sum_{i=1}^{N}\left( \frac{u_i - u_{i-1}}{h}\right) ^2
```
!!! info "Tasks"
	Find the optimal fit using `Optim.jl`. 

	*Use following parameters:*
	* The noise on the datapoints is normally distributed ``\mathcal{N}(0, \sigma)``. 
	* Use ``h=\{0.0125; 0.008\}``. 
	* Given the following pairs of values for ``(β, \sigma = noise) = \{(1\text{e-3}; 0.01); (1\text{e-3}; 0.1); (1\text{e-4}; 0.01); (1\text{e-3}; 0.1) \}``. 

	What do you observe and what is the best approximation?

"""

# ╔═╡ c53141dc-37ef-4295-a94d-7eee43177e5b
begin
	"""
		bₚ(t::K)	

	piecewise continuous function that is used a a reference
	"""
	function bₚ(t::K) where K <: Real
		if 0 ≤ t < 0.25
			return 1.
		elseif 0.25 ≤ t < 0.5
			return 2.
		elseif 0.5 ≤ t < 0.7
			return 2 - 100*(t-0.5)*(0.7-t)
		elseif 0.7 ≤ t ≤ 1
			return 4.
		else
			return 0.
		end
	end

	"""
		gensample(t, noise)

	add noise to the value of bₚ
	"""
	gensample(t, noise) = bₚ(t) + rand(Normal()) * noise

	"""
		ϕ₁(u, b, h, β)

	Loss function used to quantify the quality of the proposed fit `u` given the observed value `b` sampled at a step size `h`. The parameter β is used for tuning the regularization term which penalizes excessive roughness in `u`
	"""
	function ϕ₁(u, b, h, β)
		return h/2 * sum(0.5 .* ((u[2:end] - b[2:end]).^2 + (u[1:end-1] - b[1:end-1]).^2)) + β*h/2 * sum( ((u[2:end] - u[1:end-1]) ./ h).^2 )
	end

end

# ╔═╡ 841fcd56-1fee-495c-ae4e-47a3ad36b953
let
	# Illustration
	h= 0.0125
	β = 1e-3
	t = range(0, 1, step=h)
	s = gensample.(t, 0.01)
	plot(t, bₚ.(t), label="ground thruth")
	scatter!(t, s, label="sample", legendposition=:topleft)

	# Optimisation trial
	res = optimize(u -> ϕ₁(u, s, h, β), s)
	res.minimizer
	plot!(t, res.minimizer, marker=:circle, label="fit")
end

# ╔═╡ 2a1e165c-b26a-4962-b243-184d83fa00da
let
	p = plot(range(0, 1, step=0.01), bₚ.(range(0, 1, step=0.01)), label="ground truth")
	# concept solution
	for h in [0.0125; 0.008]
		for (β, noise) in [(1e-3, 0.01); (1e-3, 0.1); (1e-4, 0.01); (1e-4, 0.1)]
			t = range(0, 1, step=h)
			s = gensample.(t, noise)
			fit = optimize(u -> ϕ₁(u, s, h, β), s).minimizer
			plot!(t, fit, label="fit (β = $(β), noise = $(noise))")

		end
	end
	p
end

# ╔═╡ eac72e64-8584-4588-8b0e-03ddb04956f8
md"""
From the previous results, you might not be satisfied, so we propose an **additional loss function** ``\phi_2``, this time using another regularization term.
```math
\phi_2 = \frac{h}{2}\sum_{i=1}^{N}\frac{1}{2}\left[ (u_i - b_i)^2 + (u_{i-1} - b_{i-1})^2 \right]+ \gamma h \sum_{i=1}^{N} \left( \sqrt{ \left(\frac{u_i - u_{i-1}}{h}\right) ^2 + \epsilon} \right)
```
!!! info "Tasks"
	Repeat the exercise, but using:
	* ϵ=1e-6, 
	* ``(γ, σ) = \{(1\text{e-2}; 0.01); (1\text{e-2}; 0.1); (1\text{e-3}; 0.01); (1\text{e-3}; 0.1) \}``. 

	What do you observe and what is the best approximation?
"""

# ╔═╡ 128d37f1-f4b0-44f8-8a47-5c75e0c44875
	"""
		ϕ₂(u, b, h, γ, ϵ)

	Loss function used to quantify the quality of the proposed fit `u` given the observed value `b` sampled at a step size `h`. The parameters γ and ϵ are used for tuning the regularization term which penalizes excessive roughness in `u`
	"""
	function ϕ₂(u, b, h, γ, ϵ)
		return h/2 * sum(0.5 .* ((u[2:end] - b[2:end]).^2 + (u[1:end-1] - b[1:end-1]).^2)) + γ*h * sum( sqrt.(((u[2:end] - u[1:end-1]) ./ h).^2 .+ ϵ))
	end

# ╔═╡ 8da27e06-3798-423d-b882-b8c98eb36f6a
begin
	# signal generation
	h = 0.0125
	β = 1e-3
	noise = 0.1
	T = range(0,1, step=h)
	B = bₚ.(T) + rand(Normal(),length(T)) * mean(bₚ.(T)) * noise
end

# ╔═╡ 8e3a7568-ae6c-459d-9d95-4f80ca79accf
md"""
!!! info "Task"
	Can you optimize the loss function, i.e. determine those values of β or (γ, ϵ) that generate the best result? Note: you might want to think on how to deal with the stochastic aspect of the problem.
"""

# ╔═╡ 580b7d3b-78c3-4eee-889a-884fc732515a
md"""
### Constrained flower function optimisation
Consider the two-dimensional flower function
```math
f(x) = a ||x|| + b \sin \left(c \tan ^{-1}\left( x_2, x_1  \right) \right)
```
where ``a=1,b=1,c=4``.
"""

# ╔═╡ 117d36ab-a6ba-40e0-b5fc-c0209acbfbfd
"""
	flower(x; a=1, b=1, c=4)

flower function
"""
function flower(x::Vector{T}; a=1, b=1, c=4) where T<:Real
	return a*norm(x) + b*sin(c*atan(x[2], x[1]))
end

# ╔═╡ ffa3233d-a17c-4600-8fa1-8001e07fe600
md"""
!!! info "Tasks"
	1. minimise the flower function.
	2. minimise the flower function with the additional constraint ``x_1^2 + x_2^2 \ge 2``

	Make an illustration for different starting values.

!!! tip "Alternative?"
	How could you allow (limited) disrespect of the constraints?
"""

# ╔═╡ f7478cd0-7558-4c71-8933-2003863eb1bd
let
	# some illustrations
	x = range(-3, 3, length=100)
	y = range(-3, 3, length=100)
	contour(x,y, (x,y) -> flower([x;y]), label="flower")
	title!("Flower function contour plot")
	xlabel!("x")
	ylabel!("y")
end

# ╔═╡ fea692ef-2192-40a5-91ad-c3aad9a12676
md"""
## Linear Programming
!!! warning "Applications"
	Applications on LP will be covered in the section on LP.
"""

# ╔═╡ c76417ca-f3ba-49bd-a16e-6246c396d458
md"""
# Linear programming
We will be using [JuMP](https://jump.dev/JuMP.jl/stable/) as a general framework, combined with [Tulip](https://github.com/ds4dm/Tulip.jl) or [GLPK](https://github.com/jump-dev/GLPK.jl) as a solver.
"""

# ╔═╡ 5f9e6cbc-ce95-4b00-a0e5-f5633e82b157
md"""
## Example - Employee planning
We manage a crew of call center employees and want to optimise our shifts in order to reduce the total payroll cost. 

!!! tip "Setting"
	* Employees have to work for five consecutive days and are then given two days off. 
	* The current policy is simple: each day gets the same amount of employees (currently we have 5 persons per shift, which leads to 25 persons on any given day).
	* We have some historical data that gives us the minimum amount of calls we can expect: Mon: 22, Tue: 17, Wed:13, Thu:14, Fri: 15, Sat: 18, Sun: 24
	* Employees are payed € 96 per day of work. This lead to the current payroll cost of 25x7x96 = € 16.800. 

!!! info "Task"
	You need to optimize employee planning to reduce the payroll cost.

Following table gives an overview:

| Schedule | Days worked | Attibuted Pers | Mon | Tue | Wed | Thu | Fri | Sat | Sun |
|----------|-------------|----------------|-----|-----|-----|-----|-----|-----|-----|
| A | Mon-Fri | 5 | W | W | W | W | W | O | O |
| B | Tue-Sat | 5 | O | W | W | W | W | W | O |
| C | Wed-Sun | 5 | O | O | W | W | W | W | W |
| D | Thu-Mon | 5 | W | O | O | W | W | W | W |
| E | Fri-Tue | 5 | W | W | O | O | W | W | W |
| F | Sat-Wed | 5 | W | W | W | O | O | W | W |
| G | Sun-Thu | 5 | W | W | W | W | O | O | W |
| Total Employees: | - | 35 | 5 | 5 | 5 | 5 | 5 | 5 | 5 |
| Required (calls): | - | - | 22 | 17 | 13 | 14 | 15 | 18 | 24 |

### Mathematical formulation
We need to formaly define our decision variables, constraints and objective function.

!!! tip "Decision variables"
	The amount of persons attributed to each schedule ( ``Y = [y_1,y_2,\dots,y_7]^{\intercal}``)

!!! tip "Objective function"
	*The payroll cost*
	  
	Suppose the matrix ``A`` is the matrix indicating the workload for each schedule (in practice ``W=1`` and ``O=0``):
	```math
	A = \begin{bmatrix}  
	W & W & W & W & W & O & O \\
	O & W & W & W & W & W & O \\
	O & O & W & W & W & W & W \\
	W & O & O & W & W & W & W \\
	W & W & O & O & W & W & W \\
	W & W & W & O & O & W & W \\
	W & W & W & W & O & O & W 	\\
	\end{bmatrix}
	```
	Now $$A^\intercal Y$$ gives us a vector indicating the amount of employees working on a given day. Suppose we also use the vector $$c$$ to indicate the salary for a given day (in this case $$c = [96,96,96,\dots,96]$$). 
	
	We are now able to write our objective function:
	```math
	\min Z = c^\intercal A^\intercal Y
	```

!!! tip "Constraints"

	1. Each day we need at least enough employees to cover all incoming calls. Suppose we use the vector $$b$$ to indicate the amount of incoming calls for a given day. We are able to write the constraints in a compact way:
	
	```math
	\text{subject to } A^\intercal Y  \ge b 
	```
	
	2. We also want to avoid a negative amount of attributed employees on any given day, since this would lead to a negative payroll cost:
	```math
	\text{and }Y \ge 0
	```
	
	3. $\forall Y : Y \in \mathbb{N}$
### Implementation
"""

# ╔═╡ 5e75e9f8-e76f-417e-8b83-e90c2f08f657
begin
	# basic data
	A = ones(Bool,7,7) - diagm(-1=>ones(Bool,6), -2=> ones(Bool,5), 5=>ones(Bool,2), 6=>ones(Bool,1))
	Y = [5,5,5,5,5,5,5]
	Bc = [22,17,13,14,15,18,24]
	C = [96,96,96,96,96,96,96];
	A
end

# ╔═╡ d05bd2a1-475d-4f0c-b070-1adb0015ca3b
# A' * Y .> Bc
C' * A' * Y

# ╔═╡ 2d949d67-f5d3-4ac4-ae89-9ce0ae6a4c73
let
	model = Model(GLPK.Optimizer)
	@variable(model, Y[1:7] >= 0, Int)
	@constraint(model, A' * Y .>= Bc)
	@objective(model, Min, C' * A' * Y)
	optimize!(model)
	println("termination status: $(termination_status(model))")
	println("objective value:    $(objective_value(model))")
	println("personnel assignment per schedule: $(value.(Y))")
end

# ╔═╡ 40e020d3-53e2-4953-8ba0-119ad43dbab9
md"""
### Adding uncertainty
Up to now, we have had constant numbers for the minimum number of employees needed per day. In reality these quantities are uncertain. The actual number of calls will fluctuate each day. For simplicity's sake will we use a [lognormal distribution](https://en.wikipedia.org/wiki/Log-normal_distribution#Occurrence_and_applications) for the amount of calls (using their initial value as mean and a standard deviation of two). Working this way, we avoid having negative calls.
"""

# ╔═╡ 65ca25af-03ef-4798-97d1-4e4187704e94
Bc

# ╔═╡ f52b6763-e57d-44cf-92ee-144a049993a5
begin
	# generating the distributions
	B_u = Distributions.LogNormal.(Bc,2) # array with distributions

	# quick sample to illustrate amount of calls being randomized
	log.(rand.(B_u))
end

# ╔═╡ 03b24a45-607c-4f66-8155-eb96d91aceaa
begin
	cost = Float64[]
	for _ in 1:10000
		let cout=cost
			model = Model(GLPK.Optimizer)
			@variable(model, Y[1:7] >= 0, Int)
			@constraint(model, A' * Y .>= log.(rand.(B_u)))
			@objective(model, Min, C' * A' * Y)
			optimize!(model)
			push!(cout, objective_value(model))
		end
	end
	cost
end

# ╔═╡ 34dca455-df8a-48f9-a0e4-31492d25867a
StatsPlots.histogram(cost, normalize=:pdf,xlabel="objective value", ylabel="PDF", label="")

# ╔═╡ f0a7dc6b-d9cd-4198-9016-e55ef8c93a7e
md"""
### Small variant: adding a commission
Suppose each worker receives extra pay for the amount of calls that have been treated. We can easily include this in our model
"""

# ╔═╡ f409d2f6-0309-43a6-9f55-bfde2ca1a589
begin
	cost_c = Float64[]
	commission = 20
	for _ in 1:10000
		let cout=cost_c
			model = Model(GLPK.Optimizer)
			appels = log.(rand.(B_u))
			@variable(model, Y[1:7] >= 0, Int)
			@constraint(model, A' * Y .>= appels)
			@objective(model, Min, C' * A' * Y + sum(appels) * commission)
			optimize!(model)
			push!(cout, objective_value(model))
		end
	end

	StatsPlots.histogram(cost_c, normalize=:pdf,xlabel="objective value", ylabel="PDF", label="")
end

# ╔═╡ fcbc6f59-958c-440e-b5f3-676edb0b308c
md"""
#### Playing it safe
The above has given us some information on what the distributions of the payroll cost may be, however in reality, you would want to make sure that the clients calling to center are taken care off. To realise this, one might say that for any given day, you want to make sure that 90% of all calls can be treated by the specific capacity.
"""

# ╔═╡ 49666e38-230d-4a2c-894c-7b7113bb29d7
log.(quantile.(B_u, 0.90))

# ╔═╡ b2f11df8-d83e-40d0-9cfa-0fa3b56e0c87
 let
	model = Model(GLPK.Optimizer)
	@variable(model, Y[1:7] >= 0, Int)
	@constraint(model, A' * Y .>= log.(quantile.(B_u, 0.99)))
	@objective(model, Min, C' * A' * Y)
	optimize!(model)
	termination_status(model)
	objective_value(model)
end

# ╔═╡ fc31d991-4683-4d49-bb83-69db0cb4fb76
md"""
### Additional questions
* The example we have treated so far has very traditional working patterns for the employees. How woud you deal with modern working patterns (e.g. 4/5 or parttime working)?
* We took a look at the stochastic nature of the amount of calls, however, the personnel might not show up for various reasons. How would you describe the possible influence? Hint: make a discrete event model of this setting, using the optimal design and controlling for employees showing up or not.
"""

# ╔═╡ 376b3f70-013a-4931-9284-fda3ceb88683
md"""
## Application - Maximize flow in a network

We try to maximize the flow in a network using Linear Programming.


!!! tip "Setting"
	Let $N = (V, E)$ be a directed graph, where $V$ denotes the set of vertices and $E$ is the set of edges. Let $s ∈ V$ and $t ∈ V$ be the source and the sink of $N$, respectively. The capacity of an edge is a mapping $c : E \mapsto \mathbb{R}^+$, denoted by $c_{u,v}$ or $c(u, v)$. It represents the maximum amount of flow that can pass through an edge.
	
	A flow is a mapping $f : E \mapsto \mathbb{R}^+$ , denoted by $f_{uv}$ or  $f(u, v)$, subject to the following two constraints:
	
	* Capacity Constraint: 
	
	```math
	\forall e \in E: f_{uv} \le c_{uv}
	```
	
	* Conservation of Flows: 
	
	```math
	\forall v \in V\setminus\{s,t\} : \sum_{u:(u,v)\in E}f_{uv} = \sum_{w:(v,w)\in E} f_{vw}
	```

!!! info "Tasks"

	We want to maximize the flow in the network, i.e. 
	```math
	\max |f| = \max \sum_{v:(s,v)\in E}f_{sv} = \max \sum_{v:(v,t)\in E}f_{vt}
	```


#### Setting:
Consider the following network:

$(PlutoUI.LocalResource("./applications/img/network.png"))

!!! info "We want to:"
	1. Determine the maximal flow in the network
	2. Be able to get a troughput of 35 from the source node (A) to the sink node (G), whilst keeping the costs limited. Each link has a possible increase, with an associated cost (cf. table)

$(PlutoUI.LocalResource("./applications/img/networkcost.png"))
"""

# ╔═╡ 1ac40672-daf3-49e2-b4a4-bf4b9960dcb1
# given set-up
begin
	# Topology and maximum flow matrix
	W = [0 13 6 10 0 0 0;
		 0 0  0  9 5 7 0;
		 0 0  0  8 0 0 0;
		 0 0  0  0 3 0 12;
		 0 0  0  0 0 4 6;
		 0 0  0  0 0 0 9;
		 0 0  0  0 0 0 0;
	];
	# extra capacity
	xcap = [ 0 6  4  3 0 0 0;
			 0 0  0  4 5 3 0;
			 0 0  0  5 0 0 0;
			 0 0  0  0 2 0 5;
			 0 0  0  0 0 2 4;
			 0 0  0  0 0 0 5;
			 0 0  0  0 0 0 0;
	];
	# cost per increased capacity
	xcost= [ 0 2.8  2.5  2.8 0   0   0;
			 0 0    0    2.5 3.1 1.6 0;
			 0 0    0    3.9 0   0   0;
			 0 0    0    0   2.8 0   1.6;
			 0 0    0    0   0   4.6 2.9;
			 0 0    0    0   0   0   1.8;
			 0 0    0    0   0   0   0;
	];
end

# ╔═╡ 1b2ff048-e4a5-4fc6-a7cb-f18430a18ce1
md"""
## Application - Optimizing an investment portfolio

In 1952 [Harry Max Markowitz](https://en.wikipedia.org/wiki/Harry_Markowitz) proposed a new approach for the optimization of an investment portfolio. This ultimately led to him winning the Nobel Prize in Economic Sciences in 1990. The idea is relatively simple:

!!! tip "Setting"
	Given a portfolio with $n$ stock proportions $S_1,S_2,\dots, S_n$, we want to maximize the return (=profit) and minimize the risk. The goal is to find the values $S_i$ that lead to either a minimum risk attribution with a minimal return or that lead to a maximum return attribution with a maximal risk.
	
	Remembering that $\sigma^{2} {\sum_{i=1}^{n}X_i}= \sum_{i=1}^{n}\sigma^2_{X_i} + \sum_{i \ne j}\text{Cov}(X_i,X_j) $, the risk can be expressed in terms of the covariance matrix $\Sigma$:
	
	$$S^\mathsf{T} \Sigma S $$ 
	
	The return can be expressed as:
	$$\mu^\mathsf{T}S$$

Consider the following portfolio problem:
!!! info "Tasks"
	You are given the covariance matrix and expected returns and you want study several approaches. For each case you should formulate a proper Linear/Quadratic Programming form.
	1. Ignore the risk and go for optimal investment (i.e. maximal return)
	2. Same as (1), but a single stock can be at most 40% of the portfolio
	3. Minimize the risk, with a lower bound on the return e.g. with at least 35% expected return
	4. Make a graph for:
	    * the minimal risk in fuction of the expected return. 
	    * the distribution of the portfolio with the minimal risk in function of the expected return
	    * the final portfolio value in function of the expected return
"""

# ╔═╡ a9e7cff7-0ca2-4b4a-824b-17af4065c610
begin
	P = [60; 127; 4; 50; 150; 20] # stock prices
	μ = [0.2; 0.42; 1.; 0.5; 0.46; 0.3] # expected returns
	Σ = [0.032 0.005 0.03 -0.031 -0.027 0.01;
		 0.005 0.1 0.085 -0.07 -0.05 0.02;
		 0.03 0.085 1/3 -0.11 -0.02 0.042;
		 -0.031 -0.07 -0.11 0.125 0.05 -0.06;
		 -0.027 -0.05 -0.02 0.05 0.065 -0.02;
		 0.01 0.02 0.042 -0.06 -0.02 0.08]; # covariance matrix
end

# ╔═╡ 43ba9db1-a10a-4bf8-b2ad-30e97da6cc46
md"""
## Application - Optimal course planning
!!! tip "Setting"
	Suppose a professor teaches a course with $N=20$ lectures. We must decide how to split each lecture between theory and applications. Let $T_i$ and $A_i$ denote the fraction of the i$^{\text{th}}$ lecture devoted to theory and applications, for $i=1,\dots,N$. We can already determine the following: 
	
	```math
	\forall i: T_i \ge 0, A_i \ge 0, T_i+A_i =1.
	```
	
	As you may know from experience, you need to cover a certain amount of theory before you can start doing applications. For this application consider the following model:
	
	$$\sum_{i=1}^{N} A_i \le \phi \left( \sum_{i=1}^{N} T_i \right)$$
	
	We interpret $\phi(u)$ as the cumulative amount of applications that can be covered, when the cumulative amount of theory covered is $u$. We will use the simple form $\phi(u) = a(u − b)$, with $a=2, b=3$, which means that no applications can be covered until $b$ lectures of the theory are covered; after that, each lecture of theory covered opens the possibility of covering a lecture on applications.
	
	Psychological studies have shown that the theory-applications split affects the emotional state of students differently. Let $s_i$ denote the emotional state of a student after lecture $i$, with $s_i = 0$ meaning neutral, $s_i > 0$ meaning happy, and $s_i < 0$ meaning unhappy. Careful studies have shown that $s_i$ evolves via a linear recursion dynamic:
	
	$$s_i =(1−\theta)s_{i−1} +\theta(\alpha T_i +\beta A_i)\text{ with }\theta \in[0,1]$$ 
	
	with $s_0=0$. In order to make sure that the student leave with a good feeling at the end of the course, we try to maximize $s_N$, i.e. the emotional state after the last lecture.

!!! info "Tasks"
	1. Determine the optimal split that leads to the most positive emotional state (for $\theta = 0.05, \alpha = -0.1, \beta = 1.4$);
	2. Show the course repartition graphically
	3. Determine values for $\alpha$ and $\beta$ that lead to a neutral result at the end of the course. Can you give an interpretation to these values?
"""

# ╔═╡ ca2425dc-cc33-4cff-9497-e522e0ed4516
md"""
## Application - Vehicle Routing

You can find a more elaborate and detailed example here:

```Julia
include("./detailed/PS04 - Linear programming - vehicle routing.jl")
```

This Julia script models and solves the Capacitated Vehicle Routing Problem (CVRP) using JuMP and GLPK. It includes two versions: a basic Multiple Vehicle Routing Problem (MVRP) and a more advanced Multiple Trip Vehicle Routing Problem (MTVRP). Both use binary variables to decide routes for trucks visiting cities with demands while respecting vehicle capacity. The models include constraints for route continuity, capacity, and customer coverage.
"""

# ╔═╡ Cell order:
# ╟─543d9901-6bdc-4ca5-bfac-800f543c3490
# ╠═c175a542-11d4-49f1-a872-2053d81d5ade
# ╟─72ad677c-738f-4e62-afcb-c5260ff9a79e
# ╟─b4764948-0330-11eb-3669-974d75ab1134
# ╟─1b769f0c-0332-11eb-1efb-178c1985f3df
# ╠═f1068fca-0331-11eb-20de-a98c65d5c2dc
# ╟─165f35b0-0332-11eb-12e7-f7939d389e58
# ╠═77d89aa8-07d2-11eb-1bbd-a5c896e3ecfe
# ╠═f27797e5-b83f-4375-ab17-480c09fd7b7f
# ╟─e6294d6a-0334-11eb-3829-51ee2b8cadaf
# ╠═66be5114-0335-11eb-01a9-c594b92937bf
# ╠═15ef34dc-0336-11eb-0de5-b942e8871db8
# ╠═e949078a-07d3-11eb-0146-8115e335b2e9
# ╠═901eed25-2aea-42a4-bd7e-68b919a8766c
# ╟─71d2bf30-0336-11eb-28ed-95518b9204a7
# ╟─add5faba-03b8-11eb-0cc7-15f19eb1e0e2
# ╠═9396ccae-03ba-11eb-27a9-1b88ee4fb45f
# ╠═94abb7a2-03bb-11eb-1ceb-1dff8aa3cce7
# ╠═6f552aa6-07d5-11eb-18a5-b32ed233c403
# ╟─966b88dc-03bc-11eb-15a4-b5492ddf4ede
# ╠═68263aea-07d0-11eb-24f8-6383a3a1e09d
# ╟─0b83404d-2caf-4cdf-8418-7c8296a539ba
# ╟─f23a8448-bd4e-4837-8ed9-c990d489a67e
# ╟─ec264b44-03c2-11eb-1695-cbf638f8cea9
# ╠═053bae8a-087d-11eb-2e8c-73c41fb4e005
# ╟─b5cf333b-5ffa-45d5-b9c0-00abc4b63196
# ╠═c53141dc-37ef-4295-a94d-7eee43177e5b
# ╠═841fcd56-1fee-495c-ae4e-47a3ad36b953
# ╠═2a1e165c-b26a-4962-b243-184d83fa00da
# ╟─eac72e64-8584-4588-8b0e-03ddb04956f8
# ╠═128d37f1-f4b0-44f8-8a47-5c75e0c44875
# ╠═8da27e06-3798-423d-b882-b8c98eb36f6a
# ╟─8e3a7568-ae6c-459d-9d95-4f80ca79accf
# ╟─580b7d3b-78c3-4eee-889a-884fc732515a
# ╠═117d36ab-a6ba-40e0-b5fc-c0209acbfbfd
# ╟─ffa3233d-a17c-4600-8fa1-8001e07fe600
# ╠═f7478cd0-7558-4c71-8933-2003863eb1bd
# ╟─fea692ef-2192-40a5-91ad-c3aad9a12676
# ╟─c76417ca-f3ba-49bd-a16e-6246c396d458
# ╟─5f9e6cbc-ce95-4b00-a0e5-f5633e82b157
# ╠═5e75e9f8-e76f-417e-8b83-e90c2f08f657
# ╠═d05bd2a1-475d-4f0c-b070-1adb0015ca3b
# ╠═2d949d67-f5d3-4ac4-ae89-9ce0ae6a4c73
# ╟─40e020d3-53e2-4953-8ba0-119ad43dbab9
# ╠═65ca25af-03ef-4798-97d1-4e4187704e94
# ╠═f52b6763-e57d-44cf-92ee-144a049993a5
# ╠═03b24a45-607c-4f66-8155-eb96d91aceaa
# ╠═34dca455-df8a-48f9-a0e4-31492d25867a
# ╟─f0a7dc6b-d9cd-4198-9016-e55ef8c93a7e
# ╠═f409d2f6-0309-43a6-9f55-bfde2ca1a589
# ╟─fcbc6f59-958c-440e-b5f3-676edb0b308c
# ╠═49666e38-230d-4a2c-894c-7b7113bb29d7
# ╠═b2f11df8-d83e-40d0-9cfa-0fa3b56e0c87
# ╟─fc31d991-4683-4d49-bb83-69db0cb4fb76
# ╟─376b3f70-013a-4931-9284-fda3ceb88683
# ╠═1ac40672-daf3-49e2-b4a4-bf4b9960dcb1
# ╟─1b2ff048-e4a5-4fc6-a7cb-f18430a18ce1
# ╠═a9e7cff7-0ca2-4b4a-824b-17af4065c610
# ╟─43ba9db1-a10a-4bf8-b2ad-30e97da6cc46
# ╟─ca2425dc-cc33-4cff-9497-e522e0ed4516
