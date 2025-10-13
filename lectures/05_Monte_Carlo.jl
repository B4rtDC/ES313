### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ 4665a540-e8c8-466e-a2bc-3e74983bd683
begin
	# Pkg needs to be used to force Pluto to use the current project instead of making an environment for each notebook
	using Pkg
	# this is redundant if you run it through start.jl, but to make sure...
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using PlutoUI
	PlutoUI.TableOfContents(depth=3)
end

# ╔═╡ 88b449e2-8ba3-4202-a22c-56be1ee7297b
begin
	using Random
	using Plots, StatsPlots, LaTeXStrings, Measures
	using Statistics
	using Distributions
	using Graphs
	using BenchmarkTools
	using CSV, DataFrames
	using ConcurrentSim
	using Logging
end

# ╔═╡ 78afe080-f64f-4835-8f77-80ec906c2f13
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

# ╔═╡ dc08f693-5ebc-44e8-b4b2-48e48aeee5c9
md"""# Monte Carlo methods"""

# ╔═╡ 59c0990c-f11d-4895-9cdd-32d9d644e617
md"""
!!! info "Concept"
	Monte Carlo methods are computational techniques that use random sampling to estimate complex mathematical or physical systems. They rely on repeated random simulations to approximate solutions to problems that are difficult or impossible to solve analytically, often in high-dimensional spaces. These methods are widely used in fields like statistics, physics, finance, and machine learning for tasks such as numerical integration, optimization, and uncertainty quantification.


	

	**Notes**:
	- There is no single 'Monte Carlo method'. Rather, the term describes a broad approach encompassing many specific techniques.
	- The name "Monte Carlo" comes from the randomness akin to gambling, inspired by the famous casino in Monaco.
	- Historically, the [buffon's needle experiment](https://en.wikipedia.org/wiki/Buffon%27s_needle_problem) could be considered as the earliest Monte Carlo-style experiment.
	- The first modern, computerised use [stems from the Manhattan Project](https://en.wikipedia.org/wiki/Monte_Carlo_method#History), where the Eniac computer was used to run a Monte Carlo simulation of neutron paths to determine the critical radius of a U-235 sphere.
"""

# ╔═╡ 2d78885b-1673-4c75-a5c9-8ca7b4b9237e
md"""## Use cases
### Sampling and simulation
Monte Carlo methods are often used to approximate an unknown "true" model `` f(x) ``
 by sampling from a parametric model ``P(x; \theta).`` This is especially helpful when the true model is complex or inaccessible analytically. By generating random samples and computing statistics (e.g., averages or probabilities), we can learn about the model's behavior. 

!!! tip "Buffon's needle"
	By simulating random needle drops on a lined surface and observing how often they cross a line, we can estimate $\pi$.

	
"""

# ╔═╡ f2445950-a23b-4e98-b72a-37c28f0e894c
begin
	"""
		buffon_needle(n_drops, line_distance, needle_length)

	Recreation of buffon's needle experiments for the case where needle_length ≤ line_distance
	"""
	function buffon_needle(n_drops, line_distance, needle_length)
	    hits = 0
	    for _ in 1:n_drops
	        # Random center position and angle
	        x = rand() * line_distance
	        theta = rand() * π
	        # Check if needle crosses a line
	        if x <= (needle_length / 2) * sin(theta) || x >= line_distance - (needle_length / 2) * sin(theta)
	            hits += 1
	        end
	    end
	    # Estimate pi
	    if hits == 0
	        return Inf  # Avoid division by zero
	    else
	        return (2 * needle_length * n_drops) / (hits * line_distance)
	    end
	end

	let
		# Parameters
		n_drops = 100000
		line_distance = 1.0
		needle_length = 1.0
	
		 # Run simulation
		estimated_pi = buffon_needle(n_drops, line_distance, needle_length)
		println("Estimated π: ", estimated_pi)
	end
end

# ╔═╡ 40908b8a-6ed8-4442-b8bd-34c058b16de7
let
	# Make an illustration for multiple samples
	N_s = 100
	line_distance = 1.0
	needle_length = 1.0
	p = plot()
	for n_drops in 10 .^ (1:4)
		π_estimates = Float64[]
		for n in 1:N_s
			push!(π_estimates, buffon_needle(n_drops, line_distance, needle_length))
		end
		violin!(p, π_estimates)
	end
	plot!(p, xlabel="Number of drops", ylabel="Estimate value distribution")
	xticks!(1:4, [L"10^%$(i)" for i in 1:4], legend=false)
	title!("Distribution of estimates of π")
	p
end

# ╔═╡ 0a7d94b3-1485-4377-9b49-20e79fdb3d4b
md"""
Another way of estimating $\pi$ is dropping point in a square, and analyse the number of points that fall within the inscribed circle.
"""

# ╔═╡ 91c493a7-a4bc-4284-956e-86567dc100d4
# try this

# ╔═╡ 5496024e-7376-420d-b13c-e157c574553e
md"""
### Estimating quantities
Monte Carlo methods excel at estimating integrals, particularly in high-dimensional spaces where traditional methods become impractical. The idea is to sample points randomly within the domain and average the function values to approximate the integral. This approach scales well with dimensionality and is widely used in scientific computing. Suppose you want to compute
```math
c = \int_{\Omega} \pi(𝐱) f(𝐱)d𝐱.
```
We would draw M samples from ``\pi(𝐱)`` and estimate the value of $c$ by computing the mean:
```math
c \approx \frac{1}{M} \sum_{i=1}^{M}f(𝐱_i)
```

!!! tip "Integral example"
	We estimate the integral of $f(x) = x^2$ over $[0,1]$, which has an exact value of $\frac{1}{3}\approx 0.333$. We use 100,000 random samples to compute the approximation.

"""

# ╔═╡ 769c8fe3-9162-4cc9-82c5-3ce7a2c4805f
let
	function monte_carlo_integral(n_samples)
	    sum = 0.0
	    for _ in 1:n_samples
	        x = rand()  # Sample x uniformly from [0,1]
	        sum += x^2
	    end
	    return sum / n_samples
	end

	# Run simulation
	n_samples = 100000
	estimated_integral = monte_carlo_integral(n_samples)
	println("Estimated integral of x^2 from 0 to 1: ", estimated_integral)
end

# ╔═╡ 4c7434d6-2e5b-4c45-af15-649b65caa875
md"""
**Note:** an additional advantage of this approach, is that the different realisations can be computed independent from one another, so for more compute-intensive tasks, you can benefit from parallel computing for massive speep-ups.
"""

# ╔═╡ 6e1d9ce1-d90b-4b9b-9e8e-9f474535c868
md"""
### Optimisation and bayesian inference
!!! info "Bayesian inference"
	Bayesian inference is a method of statistical inference where you update your beliefs (probability distributions) about uncertain parameters based on observed data. It is grounded in Bayes' theorem, which combines a prior, a likelihood, and a posterior (cf. probability and statistics courses). Formally:
	```math
	P(\theta | D ) = \frac{P( D  | \theta ) \cdot P(\theta)}{P(D)},
	```
	where $\theta$ are the parameters, $D$ represents the data, $P(\theta | D)$ represents the posterior (the updated belief after seeing the data), $P(D | \theta )$ represents the likelihood (how probable the observed data is for specific parameter values), $P(\theta)$ is the prior (what we believe about the parameter(s) before seeing the data), and $P(D)$ is the evidence (serves a normalising constant).

In the context of Bayesian inference, we typically use Markov Chain Monte Carlo (MCMC) methods to sample from the complex posterior distribution $P(\theta | D)$, which often has no closed-form solution. Monte Carlo methods allow us to approximate the posterior distribution by drawing samples, enabling practical inference, prediction, and decision-making. This method is very interesting because:
- in addition to a point estimate, you also get a distribution
- you can incorporate prior knowledge, and update your beliefs with data
- it works for complex problems where exact math fails, which is very common in real-world systems.
"""

# ╔═╡ b90b8319-b2f9-4948-a500-a7b6518db502
md"""
!!! tip "Poisson arrival rate estimation"
	Suppose we’re analyzing the number of emails received per day over five days, with observed counts: 3, 5, 2, 7, and 4. We model these counts as coming from a Poisson distribution with an unknown rate parameter $\lambda$, representing the average number of emails per day. Our goal is to estimate $\lambda$ using Bayesian inference and Monte Carlo methods.
"""

# ╔═╡ 6cc32888-d93f-473f-b4dc-0c21cb69608e
let
arrival_content = md"""Recall from your probability courses, that the Poisson distribution is well suited for counting things that happen randomly over a fixed time. It has one parameter, $\lambda$, which is the average rate of events. The probability density function is given by: $P(x | \lambda) = \frac{\lambda^x e^{-\lambda}}{x!}$.

!!! warning \"Maximum likelihood estimator\"
	Also from last year, you might recall that you can obtain a point estimate for the MLE of a Poisson variable by simply taking the sample mean, which would give you an estimate of $4.2$.

However, the MLE gives you one number with no sense of how certain or uncertain it is. Bayesian inference, combined with Monte Carlo, will give you a range of possible values for $\lambda$ and tell you how likely each one is.
"""

prior_content = md"""
We need to establish our prior, i.e. what we think $\lambda$ might be before looking at the data. To keep things simple, we could simply estimate is to be any number between 0 and 10, all equaly likely (i.e. a uniform distribution). So we have the following prior:
```math
P(\lambda) = \begin{cases} \frac{1}{10} & \lambda \in [0, 10] \\ 0 & \text{elsewhere} \end{cases}
```
"""
prior = PlutoUI.details("Prior", [prior_content], open=false)

likelihood_content = md"""
We can determine the likelihood of our data based on its assumed model (Poisson) and the parameter: 
```math
P(D | \lambda) = \prod_{i=1}^{N} \frac{\lambda^x_i e^{-\lambda}}{x_i!}
```
"""
likelihood = PlutoUI.details("Likelihood", [likelihood_content], open=false)

posterior_content = md"""
We can determine the likelihood of our data based on its assumed model (Poisson) and the parameter: 
```math
P(\lambda | D ) \propto P(\text{data} | \lambda)  P(\lambda)
```
Note that we use $\propto$ to indicate "proportional to", because we've discarded the scaling factor $P(D)$. 
This posterior gives you a probability distribution over $\lambda$ that are most likely, given your data.
"""
posterior = PlutoUI.details("Posterior", [posterior_content], open=false)

more_content = md"""
Calculating the posterior exactly is hard, but instead of solving the equation, we use the computer to sample possible $\lambda$ values from the posterior
"""

MH_principle_content = md"""
!!! info \"Metropolis-Hastings algorithm\"
	The [Metropolis–Hastings algorithm](https://en.wikipedia.org/wiki/Metropolis–Hastings_algorithm) is a Markov chain Monte Carlo method for obtaining a sequence of random samples from a probability distribution from which direct sampling is difficult. New samples are added to the sequence in two steps: first a new sample is proposed based on the previous sample, then the proposed sample is either added to the sequence or rejected depending on the value of the probability distribution at that point. 

	It follows the following broad principle:
	- Pick an initial guess (e.g. $\lambda$ =  5.0)
	- Suggest a point by tweaking the current one a little (e.g $\lambda_{\text{new}} = 5.0 + \varepsilon$)
	- If the new point is outside our prior range, reject it right away as it is impossible based on our initial belief (e.g. less than 0 or more than 10)
	- Calculate how likely the data is with the current point (e.g. $\lambda = 5.0$) and the new point (e.g. $\lambda = 5.2$). If the new one makes the data more likely, move there. If not, you might still move, but with a probability based on how much less likely it is.
	- Movement is base on the ratio: $r = \frac{P(D | \lambda_{\text{new}})}{P(D | \lambda_{\text{current}})}$.If $r \geq 1$, accept $\lambda_{\text{new}}$. If $r < 1$, accept it with probability $r$ (e.g., if $r = 0.8$, accept 80% of the time). Roll a random number between 0 and 1 to decide.

	This process is repeated for a large number of iterations. You might also want to discard the first samples, because you started in a random spot, which may bias the results. I.e. we throw out the "warm-up" measures.
"""
MH_principle = PlutoUI.details("Metropolis-Hastings approach", MH_principle_content, open=true)
	
PlutoUI.details("Arrival rate estimation", [arrival_content; prior; likelihood; posterior;more_content;MH_principle_content], open=true)
end

# ╔═╡ 12241581-863f-4717-b825-ff0cf357cc9c
let
	# Function to calculate the log-likelihood (how likely the data is for a given lambda)
	function log_likelihood(lambda, data)
	    if lambda <= 0
	        return -Inf  # If lambda is negative or zero, it’s impossible, so return a very low value
	    end
	    sum_x = sum(data)  # Sum of all email counts (3 + 5 + 2 + 7 + 4 = 21)
	    n = length(data)   # Number of days (5)
	    # Log of Poisson likelihood: sum(x_i * log(lambda)) - n * lambda
	    return sum_x * log(lambda) - n * lambda
	end
	
	# Metropolis-Hastings algorithm to sample lambda values
	function metropolis_hastings(data, num_iterations, sigma)
	    lambda_current = 5.0  # Start with a guess of 5 emails per day
	    samples = Float64[]   # Empty list to store our samples
	    for t in 1:num_iterations
	        # Propose a new lambda by adding a random tweak
	        lambda_proposed = lambda_current + randn() * sigma
	        # Check if the proposed lambda fits our prior (0 to 10)
	        if lambda_proposed < 0 || lambda_proposed > 10
	            r = 0.0  # Reject if outside the range
	        else
	            # Calculate the acceptance ratio using log-likelihoods
	            log_r = log_likelihood(lambda_proposed, data) - log_likelihood(lambda_current, data)
	            r = exp(log_r)  # Convert back from log to regular scale
	        end
	        # Accept the new lambda with probability r
	        if rand() < r
	            lambda_current = lambda_proposed  # Move to the new lambda
	        end
	        push!(samples, lambda_current)  # Save the current lambda
	    end
	    return samples
	end
	Random.seed!(161)  # Make results repeatable
	
	# Our data
	data = [3, 5, 2, 7, 4]
	#data = rand(Poisson(4.5), 100)
	
	# Settings for the algorithm
	num_iterations = 100000 
	burn_in = 1000         # Ignore the first 1,000 samples
	sigma = 1.0            # How big the random tweaks are
	
	# Run the algorithm
	samples = metropolis_hastings(data, num_iterations, sigma)
	
	# Keep only the samples after burn-in
	posterior_samples = samples[burn_in+1:end]
	
	# Analyze the results
	posterior_mean = mean(posterior_samples)              # Average lambda
	credible_interval = quantile(posterior_samples, [0.025, 0.975])  # 95% range (empirical CI)
	mle = mean(data)                                      # Simple average for comparison
	
	# Print the results
	println("Posterior mean of λ: ", round(posterior_mean, digits=2))
	println("95% credible interval: [", round(credible_interval[1], digits=2), ", ", round(credible_interval[2], digits=2), "]")
	println("MLE estimator (sample mean): ", mle)

	# Plot results
	histogram(posterior_samples, label="sample posterior", normalize=true)
	x = range(minimum(posterior_samples), maximum(posterior_samples), length=100)
	α = (sum(data)+1)
	β = 1/length(data)
	plot!(x, pdf.(Gamma(α, β), x), label="Γ distribution")
end

# ╔═╡ a783183d-50dd-4c7c-80ba-65c9d858682c
md"""
**Note:** notice how we do not exactly obtain the same values for the point estimator. This is expected behavior, and results from the choice of the prior. It can be shown that our posterior approximatively follows a gamma distribution with parameters $\alpha=22$ and $\beta=5$, which leads to a theoretical value of $4.4$. For larger sample sizes the MLE and Bayesian point estimate of the parameter would converge.
"""

# ╔═╡ 4b81af14-bc99-475b-a52b-f1aaa1e60a1e
md"""
## Variance reduction
Every result we obtain using a Monte Carlo approach is a stochastic variable, so we do want to have an idea on the variability of this result, and more important, how to reduce it. We will consider the following problem: 
```math
I = \int_{0}^{1} e^x dx = e-1
```
!!! warning "Why reduce variance?"
	Lower variance means fewer samples for the same confidence, saving precious CPU time, sometimes by orders of magnitude!

"""

# ╔═╡ b18f806c-8b26-4c54-b4a3-1c1acc2867d0
md"""
### Standard Monte Carlo
If we just sample the space using a uniform distribution ($X\sim U(0,1)$), we would find the following estimate:
```math
I = \mathbb{E}[f(x)],
```
with $f(x) = e^x$. Based on $N$ i.i.d. samples drawn from $X$, we get an estimate:
```math
I \approx \frac{1}{N} \sum_{i=1}^{N} f(X_i).
```
The variance however is given by $Var (I) = Var(f(X))/N$, so if we want to reduce the variance by a factor of two, we actually need to double (!) the sample length.
"""

# ╔═╡ ab9e17e5-9d3d-4790-924b-9de1ff8d55c2
begin
	# function
	f(x) = exp.(x)
	
	# sample - standard Monte Carlo
	n_var = 2000 # number of estimates per sample length
	sample_lengths=100:10:1000
	var_est = Float64[]
	for n in sample_lengths
		I_est = Vector{Float64}(undef, n_var)
		for i in 1:n_var
			S = f(rand(n))
			I_est[i] = sum(S)/n
		end
		push!(var_est, var(I_est))
  	end	
	plot(sample_lengths, var_est, label="", ylabel="Variance", xlabel="sample length",ylims=(0, 0.0025),xlims=(100,1000))
	xticks!(100:100:1000)
end

# ╔═╡ 0ce6d4bf-37f3-445b-bce7-c4047c315ef5
md"""
### Antithetic variates
!!! info "Principle"
	The goal is to introduce negative correlation between pairs of samples in a way that doesn't change the expected value of the estimator but reduces its variance.

	Recall that for two random variables $Y_1$ and $Y_2$: 
	```math	
	Var(Y_1 + Y_2) = Var(Y_1) + Var(Y_2) + 2 * Cov(Y_1, Y_2)
	```
	
	If we can make $Cov(Y_1, Y_2)$ negative, then $Var(Y_1 + Y_2)$ will be smaller than $Var(Y_1) + Var(Y_2)$ (the variance if $Y_1$ and $Y_2$ were independent).

Suppose we want to generate a random variable $X$ from a distribution $F$. We typically do this using the inverse transform method:
1. Generate $U \sim U(0, 1)$;
2. Compute $X = F^{-1}(U)$, where $F^{-1}$ is the inverse cumulative distribution function (CDF).

With antithetical variates, for each $U$ we generate, we also use its "antithesis," $1-U$:
1. Generate $U_i \sim U(0, 1)$;
2. Create two samples: $X_{i1} = F^{-1}(U_i)$ and $X_{i2} = F^{-1}(1 - U_i)$.

Note that if $U \sim U(0,1)$, then $1-U \sim U(0,1)$. Therefore, $X_{i1}$ and $X_{i2}$ individually follow the same distribution. But, instead of $N$ independent samples, we generate $N/2$ pairs of antithetical samples.

!!! warning "On the negativity of the covariance"
	The covariance $Cov(f(X_{i1}), f(X_{i2}))$ is likely to be negative if the function $f(x)$ is monotonic. If $f(x)$ is not monotonic (e.g., symmetric), antithetical variates might not provide much benefit or could even increase variance.
"""

# ╔═╡ f58ffca5-cbfa-43e2-a145-c673887b97cf
md"""
### Stratification
!!! info "Principle"
	The domain is divided in $K$ disjoint subintervals ('strata', often of equal width). We then drawn a predetermined number of samples from each stratum (often $N/K$). The estimator is the average of the values over the stratified samples. By being more systematic in the data points, this approach leads to a variance reduction.
"""

# ╔═╡ 03457e65-1f4f-4ab8-9d56-a31d738ea633
md"""
### Importance sampling
!!! info "Principle"
	Importance sampling makes a Monte Carlo method more efficient by making the random sampling focus on what counts (e.g. rare events). Normally, we would sample from $p(x)$ to obtain values which are then evaluated in $f(x)$, and averaged out to obtain an estimate. But if $p(x)$ is tricky to sample from, or if $f(x)$ only matters in specific areas, most of your samples might be useless, leading to a slow or shaky estimate. Importance sampling fixes this by sampling from a different, easier distribution, called the proposal distribution ($q(x)$), that focuses on the "important" regions where $f(x)$ is big. To make up for using $q(x)$ instead of $p(x)$, you weigh each sample by $\frac{p(x)}{q(x)}$. Method overview:
	- Pick a proposal distribution $q(x)$ that is easy to sample from and ideally mimics where $f(x)$ is significant ("important region").
	- Draw samples $x_i$ from $q(x)$.
	- Calculate the weight $w_i = \frac{p(x_i)}{q(x_i)}$ for each sample
	- Estimate $\mathbb{E}_p[f(x)]$ as the average: $\frac{1}{N} \sum_{i=1}^N f(x_i) \cdot w_i$.
"""

# ╔═╡ 47830c86-6480-4228-b116-8ca72461a176
md"""
!!! warning "Requirements of q(x)"
	1. ``q(x)`` must be a valid PDF:  
    ```math
    q(x) \ge 0\quad \text{and}\quad \int q(x) dx = 1
	```
	2. ``q(x)`` must be non-zero wherever $f(x)p(x)$ is non-zero. 
	3. Ideally, ``q(x)`` should be "similar" in shape to $|f(x)p(x)|$ to reduce variance. The more $q(x)$ concentrates samples in regions where $f(x)p(x)$ is large, the better.
"""

# ╔═╡ 05d321bf-4cc2-4d97-86b8-1325c3d63dbc
md"""
!!! tip "Example 1"
	For the example from before (i.e. $\int_0^1 e^x dx$), we could propose the following function: $q(x)= 2x$.

	Quality checks:
	- ``\int_0^1 q(x)dx=1 \rightarrow`` OK
	- CDF: ``F_q(x) = \int_0^x q(t)dt = x^2``
	- to sample from $q(x)$: 
	  1. generate $U\sim U(0,1)$
	  2. use inverse CDF: $X^2 = U \rightarrow X = \sqrt{U}$
	- **Note:** ``q(0)=0``, and $f(0)p(0) = e^0 \cdot 1 = 1$! So this can lead to an infinite weight, which is sub-optimal and can lead to very high variance if samples near 0 are generated.
"""

# ╔═╡ 2476451f-eecb-4713-9023-c7d1e2f38c55
md"""
!!! tip "Example 2"
	For the example from before (i.e. $\int_0^1 e^x dx$), we could also propose the following function: $q(x)= 0.5 + x$.

	Quality checks:
	- ``\int_0^1 q(x)dx=1 \rightarrow`` OK
	- CDF: ``F_q(x) = \int_0^x q(t)dt = x^2/2 + x/2``
	- to sample from $q(x)$: 
	  1. generate $U\sim U(0,1)$
	  2. use inverse CDF: 
	```math
	x^2/2 + x/2 = U \rightarrow X = (-1 \pm \sqrt{1 + 8U}) / 2. 
	```
    
	However, we can only have values of $X$ in the interval $[0,1]$, so we take the positive root: $X = (-1 \pm \sqrt{1 + 8U}) / 2$.

	If we check the boundaries: $U=0\rightarrow X=0$, $U=0\rightarrow X=1$. This function is never zero-values in the relevant domain, which in principle makes it a better candidate.
"""

# ╔═╡ b11f2c5f-63f8-40bd-a90c-3598380860b4
md"""## Illustration"""

# ╔═╡ 0d8f3619-5af4-45f3-b358-636a655ce4a7
let
	# function
	f(x) = exp.(x)
	
	# standard Monte Carlo
	n_var = 2000 # number of estimates per sample length
	sample_lengths=100:10:1000
		
	var_est = Float64[]
	for n in sample_lengths
		I_est = Vector{Float64}(undef, n_var)
		for i in 1:n_var
			S = f(rand(n))
			I_est[i] = sum(S)/n
		end
		push!(var_est, var(I_est))
  	end	

	# antithetical variates Monte Carlo
	var_est_antithetical = Float64[]
	for n in sample_lengths
		I_est_a = Vector{Float64}(undef, n_var)
		n_av = n ÷ 2 # only require half
		for i in 1:n_var
			U_primary = rand(n_av)          # generate u_1, ..., u_{n/2}
			U_antithetic = 1.0 .- U_primary # generate 1-u_1, ..., 1-u_{n/2}
			S_primary = f(U_primary)
            S_antithetic = f(U_antithetic)
			I_est_a[i] = (sum(S_primary) + sum(S_antithetic)) / n
		end
		push!(var_est_antithetical, var(I_est_a))
	end
	
	# stratification Monte Carlo
	var_est_stratification = Float64[]
	K_strata = 10
	for n in sample_lengths
		I_est_s = Vector{Float64}(undef, n_var)
		n_s = n ÷ K_strata # number of measure per stratum to have save global number
		for i in 1:n_var
			# accumulator
			acc = 0.
			# inner stratum loop
			for k = 0:K_strata-1
				u = rand(n_s)
				x = (k .+ u) ./ K_strata
				acc += sum(f(x))
			end
			# update
			I_est_s[i] = acc / n
		end
		push!(var_est_stratification, var(I_est_s))
	end

	# importance sampling Monte Carlo
	q(x) = x .+ 0.5 

	var_est_importance = Float64[]
	for n in sample_lengths
		I_est_is = Vector{Float64}(undef, n_var)
		for i in 1:n_var
			# determin U
			U_for_IS = rand(n)
			# determin X
			X_is = (-1.0 .+ sqrt.(1.0 .+ 8.0 .* U_for_IS)) ./ 2.0
			# sampling + q compute
			S_is = f.(X_is)
			Q_is = q(X_is)
			# weight computation
			w = 1.0 ./ Q_is # note that p(x) = 1 in our case (uniform samling in [0,1])
			# actual estimates
			I_est_is[i] = sum(S_is .* w) / n
		end
		push!(var_est_importance, var(I_est_is))
	end

	# figure
	plot(sample_lengths, var_est, label="standard", ylabel="Variance", xlabel="total sample length",ylims=(1e-6, 0.0025),xlims=(100,1000), yscale=:log10, rightmargin=2mm)
	xticks!(100:100:1000)
	yticks!(10. .^(-6:-2))
	plot!(sample_lengths, var_est_antithetical, label="antithetical variates")
	plot!(sample_lengths, var_est_stratification, label="stratification")
	plot!(sample_lengths, var_est_importance, label="importance sampling: q(x)=x + 0.5")
	title!("Comparison")
end

# ╔═╡ 708ffc5b-83b6-48b2-a0d1-bdabd970ee9a
md"""
# Application
## Global clustering coefficient
In the one of the previous lectures, we discussed graphs. The clustering coefficient is a measure of the degree to which nodes in a graph tend to cluster together (i.e. form triangles)

!!! info "Global clustering coefficient"
	Given a graph $G(V,E)$ with nodes $v_i$ and edges $e_{ij}$, the global clustering coefficient $C$ is defined as:
	```math
	C = \frac{\text{number of closed triplets}}{\text{number of all triplets}}
	```

	For large, and dense graphs, computing the exact value can be very expensive, which is why we will resort to a Monte Carlo approach

### Standard Monte Carlo
For a standard approach, we would simply select a random triplet $(u,v,w)$ (in which the edges $e_{uv}$, and $e_{vw}$ exist), and evaluate if $e_{uw}$ also exists.


### Stratified 
"""

# ╔═╡ a0db54fa-9ee7-40dd-92f6-f29265f83c63
begin
	# helper function to generate a random triplet, returns node ids
	function random_triplet(G)
		v = rand(1:nv(G))
		nbrs   = neighbors(G, v)
	    if length(nbrs) < 2
	        return random_triplet(G)             # retry
	    end
	    u, w   = sample(nbrs, 2; replace=false)
	    return (u, v, w)
	end

	# helper function to evaluate the edge existance
	is_closed(G, u, w) = has_edge(G, u, w) ? 1 : 0

	# Standard Monte Carlo
	function MC_clustering(G, N)
		closed = 0
		for _ in 1:N
        	u,v,w = random_triplet(G)
        	closed += is_closed(G, u, w)
    	end
	    
		return closed / N
	end

	# Stratified Monte Carlo (strata based on degree of center node v)
    function MC_clustering_strata(G::AbstractGraph, N::Int, K::Int)
        if nv(G) == 0 return 0.0 end
        if K <= 0 throw(ArgumentError("K must be positive.")) end
        if N <= 0 return 0.0 end

        # get degree vector
        d = degree(G)

        # 1. Create Strata Mapping (nodes per stratum)
        # Strata are defined by the degree of the center node 'v' of a wedge
        strata_nodes_map = Dict(i => Vector{Int}() for i in 1:K)
        min_deg_val = minimum(d for d in d if d >=2; init=2) # Min degree that can form a wedge
        max_deg_val = maximum(d; init=2)

        # Handle case where all nodes have degree < 2 or max_deg_val == min_deg_val
        if max_deg_val <= min_deg_val || max_deg_val < 2
             # Effectively one stratum, or no valid wedges possible.
             # Fallback to global sampling if stratification isn't meaningful here.
             # Or, if all nodes have deg < 2, clustering coeff is 0.
             for v_node in vertices(G)
                if d[v_node] >= 2 # Only consider nodes that can be centers of wedges
                    push!(strata_nodes_map[1], v_node)
                end
             end
             # If strata_nodes_map[1] is empty, means no node can center a wedge
             if isempty(strata_nodes_map[1]) return 0.0 end

             # Set K_num_strata to 1 for the rest of the logic if it was >1
             K_num_strata = 1 
        else
            for v_node in vertices(G)
                deg_v = d[v_node]
                if deg_v < 2 continue end # This node cannot be the center of a wedge

                # Map degree to stratum index (1 to K)
                # fld: floor division
                stratum_idx = clamp(fld((deg_v - min_deg_val) * K, (max_deg_val - min_deg_val + eps(Float64))) + 1, 1, K)
                push!(strata_nodes_map[stratum_idx], v_node)
            end
        end


        # 2. Calculate Stratum Weights (W_j)
        # W_j = (sum of potential wedges centered in stratum_j) / (total potential wedges in G)
        stratum_weights = zeros(Float64, K)
        total_potential_wedges_in_G = 0.0

        for v_node in vertices(G)
            deg_v = d[v_node]
            if deg_v >= 2
                total_potential_wedges_in_G += deg_v * (deg_v - 1) / 2.0
            end
        end

        if total_potential_wedges_in_G == 0.0
            return 0.0 # No wedges in the graph, so clustering coeff is 0
        end

        for j in 1:K
            potential_wedges_in_stratum_j = 0.0
            for v_node_in_stratum in strata_nodes_map[j]
                deg_v = d[v_node_in_stratum]
                # degree must be >= 2 as per strata_nodes_map construction
                potential_wedges_in_stratum_j += deg_v * (deg_v - 1) / 2.0
            end
            if total_potential_wedges_in_G > 0 # Avoid division by zero
                stratum_weights[j] = potential_wedges_in_stratum_j / total_potential_wedges_in_G
            else
                stratum_weights[j] = 0.0
            end
        end

        # 3. Estimate p_j for each stratum and combine
        overall_weighted_closed_proportion = 0.0 # This will be our C_stratified

        # Allocate N proportionally to W_j
        samples_per_stratum_target = [round(Int, N * stratum_weights[j]) for j in 1:K]
        
        # Adjust samples if sum isn't N due to rounding
        # A simple way: add/subtract difference from the largest stratum or distribute
        current_sum_samples = sum(samples_per_stratum_target)
        diff_samples = N - current_sum_samples
        if diff_samples != 0 && K > 0
            # Distribute diff among strata (e.g., add to first few, or those with most weight)
            # For simplicity, add to strata with non-zero weights until diff is 0
            idx_adjust = 1
            while diff_samples != 0 && idx_adjust <= K
                if stratum_weights[idx_adjust] > 0 || samples_per_stratum_target[idx_adjust] > 0
                    if diff_samples > 0
                        samples_per_stratum_target[idx_adjust] += 1
                        diff_samples -=1
                    elseif diff_samples < 0 && samples_per_stratum_target[idx_adjust] > 0
                        samples_per_stratum_target[idx_adjust] -= 1
                        diff_samples +=1
                    end
                end
                idx_adjust = (idx_adjust % K) + 1 # Cycle through strata
            end
        end


        for j in 1:K
            if stratum_weights[j] == 0.0 || isempty(strata_nodes_map[j]) || samples_per_stratum_target[j] <= 0
                # No contribution from this stratum if no weight, no nodes, or no samples allocated
                continue
            end

            closed_in_stratum_j = 0
            actual_wedges_sampled_in_stratum_j = 0
            
            num_samples_for_this_stratum_j = samples_per_stratum_target[j]

            for _ in 1:num_samples_for_this_stratum_j
                # Sample a center node 'v_center' from the nodes in stratum j
                if isempty(strata_nodes_map[j]) break end # Should not happen if weight > 0
                v_center = rand(strata_nodes_map[j])

                nbrs_of_v = neighbors(G, v_center)
                # degree(v_center) is guaranteed to be >= 2 by stratum construction
                
                u, w = sample(nbrs_of_v, 2, replace=false)

                closed_in_stratum_j += is_closed(G, u, w)
                actual_wedges_sampled_in_stratum_j += 1
            end

            p_j = 0.0 # Proportion of closed wedges for stratum j
            if actual_wedges_sampled_in_stratum_j > 0
                p_j = closed_in_stratum_j / actual_wedges_sampled_in_stratum_j
            end

            overall_weighted_closed_proportion += stratum_weights[j] * p_j
        end
        
        return overall_weighted_closed_proportion
    end
end

# ╔═╡ a39321e9-96f9-49e8-abb3-17fe4ab3a20e
begin
	# repeatability
	Random.seed!(161)
	
	# generate graph
	G = barabasi_albert(4000, 5)       # 4000 vertices, avg deg ≈ 8
	# exact value
	C_exact = global_clustering_coefficient(G) # Note: the denser the graph, the longer this computation takes, you can verify this by increasing the second parameter of the barabasi_albert function
	
	N_total = 1000
	N_rep = 100
	C_MC = [MC_clustering(G, N_total) for _ in 1:N_rep]
	C_MC_S = [MC_clustering_strata(G, N_total, 20) for _ in 1:N_rep]

	@info "Exact:\nC: $(round(C_exact, digits=5))"

	rel_er_C_MC = abs( mean(C_MC) - C_exact)/ C_exact
	@info "Standard M:\nC: $(round(mean(C_MC), digits=5)) (rel error: $(round(rel_er_C_MC, digits=4))), variance: $(var(C_MC))" 

	rel_er_MC_S = abs( mean(C_MC_S) - C_exact)/ C_exact
	@info "Standard M:\nC: $(round(mean(C_MC_S), digits=5)) (rel error: $(round(rel_er_MC_S, digits=4))), variance: $(var(C_MC_S))" 
end

# ╔═╡ dcee775b-4283-4165-89db-b5fc87e0116c
begin
	# quick assessment of computational and memory cost
	@btime global_clustering_coefficient(G)
	@btime MC_clustering(G, N_total)   				# x108 speedup
	@btime MC_clustering_strata(G, N_total, 20)		# x45  speedup (also x2 in terms of memory)
	nothing
end

# ╔═╡ 4707b42d-8200-4ceb-a206-6b2e25e233ae
begin
	K_strata = 30
	eval_Ns = 10 .^ (1:5)
	C_estimate_mc  = Vector{Float64}(undef, length(eval_Ns))
	C_var_mc       = Vector{Float64}(undef, length(eval_Ns))
	C_estimate_mcs = Vector{Float64}(undef, length(eval_Ns))
	C_var_mcs      = Vector{Float64}(undef, length(eval_Ns))
	
	for (i, N_total) in enumerate(eval_Ns)
		# Classical estimate
		C_MC = [MC_clustering(G, N_total) for _ in 1:N_rep]
		C_estimate_mc[i] = mean(C_MC)
		C_var_mc[i] = var(C_MC)
		# Strata-based estimate
		C_MC_S = [MC_clustering_strata(G, N_total, K_strata) for _ in 1:N_rep]
		C_estimate_mcs[i] = mean(C_MC_S)
		C_var_mcs[i] = var(C_MC_S)
	end

	# add reference line
	p1 = plot(eval_Ns, repeat([C_exact],length(eval_Ns)), color=:black, linestyle=:dash, label = "exact", xscale=:log10, xticks=eval_Ns, xlabel="Total number of iterations", ylabel="Estimate", ylims=(C_exact*0.5,C_exact*1.5))
	scatter!(p1, eval_Ns, C_estimate_mc, label="Classic MC")
	scatter!(p1, eval_Ns, C_estimate_mcs, label="Stratified MC")

	p2 = plot( scale=:log10, xticks=eval_Ns, yticks = 10. .^ (-7:-2) , xlabel="Total number of iterations", ylabel="variance")
	scatter!(p2, eval_Ns, C_var_mc, label="Classic MC")
	scatter!(p2, eval_Ns, C_var_mcs, label="Stratified MC (K = $(K_strata))")

	plot(p1,p2, size=(800, 400), bottom_margin=3mm, left_margin=3mm)
	
end

# ╔═╡ 7b1be50c-9369-4ab6-8501-745f7f58080e
md"""
## Physics of the atomic bomb
### Introduction
One situation of great interest to Los Alamos in the 1940s, was the progress of free neutrons hurtling through a nuclear weapon as it began to explode. As Stanislaw Ulam, a mathematician who joined Los Alamos during the war and later helped to invent the hydrogenbomb, would subsequently note, “Most of the physics at Los Alamos could be reduced to the study of assemblies of particles interacting with each other, hitting each other, scattering, sometimes giving rise to new particles.”

Given the speed, direction, and position of a neutron and some physical constants, physicists could fairly easily compute the probability that it would, during the next tiny fraction of a second, crash into the nucleus of an unstable atom with sufficient force to break it up and release more neutrons in a process known as fission. One could also estimate the likelihood that neutron would fly out of the weapon entirely, change direction after a collision, or get stuck. But even in the very short time span of a nuclear explosion, these simple actions could be combined in an almost infinite number of sequences, defying even the brilliant physicists and mathematicians gathered at Los Alamos to simplify the proliferating chains of probabilities sufficiently to reach a traditional analytical solution.

The arrival of electronic computers offered an alternative: simulate the progress overtime of a series of virtual neutrons representing members of the population released by the bomb’s neutron initiator when a conventional explosive compressed its core to form a critical mass and trigger its detonation. Following these neutrons through thousands of random events would settle the question statistically, yielding a set of neutron histories that closely approximated the actual distribution implied by the parameters chosen. If the number of fissions increased over time, then a self-sustaining chain reaction was underway. The chain reaction would end after an instant as the core blew itself to pieces, so the rapid proliferation of free neutrons, measured by a parameter the weapon designers called “alpha,” was crucial to the bomb’s effectiveness in converting enriched uranium into destructive power.

### Model building
#### Neutron Reaction Rate Proportional to Neutron Flux and Target Area

Assume foil density ``n`` (atoms/cm3), width ``\Delta x``, bombarded with beam (area ``A``) of neutrons ``I`` (neutrons/s) with velocity ``v_n``.

Each nucleus in foil represents possible target area: ``\sigma = \pi R_0^2`` where ``R_0`` is nuclear radius. Total target area ~ ``A \Delta x n \sigma``

Rate of removing neutrons from ``I`` is proportional to: #neutrons crossing through ``A`` and total area presented by all targets:
```math
\frac{\mathrm d N}{\mathrm d t} = \frac{I}{A}\left(A \Delta x n \sigma\right)
```


#### Neutron reaction cross sections

Total microscopic neutron cross section is expressed as:
```math
\sigma = \frac{\mathrm d N}{\mathrm d t} \frac{1}{\frac{I}{A}\left(A \Delta x n \right)}
```

Defining neutron flux as: 
```math
\phi= \frac{I}{A} \textrm{(neutrons/s $cm^2$)}
```

Then
```math
\frac{\mathrm d N}{\mathrm d t} = \phi A \Delta x n \sigma
```

Neutron flux can also be defined as ``\phi= n_nv_n`` where ``n_n`` is neutron density per cm3 in beam, ``v_n`` relative velocity (cm/s) of neutrons in beam.

Cross section ``\sigma`` can be experimentally measured as function of energy: ``\sigma\left(E\right)``, expressed in “barns” (b) with 1b = 10e-24cm$^2$.

#### Neutron reaction cross sections

Cross sections ``\sigma\left(E\right)`` can be separated into different types of reactions – scattering, absorption, fission:
```math
\sigma\left(E\right) =\sigma_s\left(E\right)+ \sigma_a\left(E\right)+ \sigma_f\left(E\right)
```

Neutron cross section data is available from [NNDC](http://www.nndc.bnl.gov/sigma/index.jsp).
"""

# ╔═╡ eac9d6c6-9c58-4d29-8271-53e62049d1c1
let
	data = CSV.read("lectures/data/sigma_total.txt", DataFrame)
	plot(data[:,1], data[:,2], xaxis=:log, yaxis=:log, xlabel="E [eV]", ylabel="sigma [b]", label=L"σ_{total}")
	data = CSV.read("lectures/data/sigma_fission.txt", DataFrame)
	plot!(data[:,1], data[:,2], xaxis=:log, yaxis=:log, label=L"σ_{fission}")
	data = CSV.read("lectures/data/sigma_elastic.txt", DataFrame)
	plot!(data[:,1], data[:,2], xaxis=:log, yaxis=:log, label=L"σ_{elastic}")
	data = CSV.read("lectures/data/sigma_inelastic.txt", DataFrame)
	plot!(data[:,1], data[:,2], xaxis=:log, yaxis=:log, label=L"σ_{inelastic}")
	data = CSV.read("lectures/data/sigma_absorption.txt", DataFrame)
	plot!(data[:,1], data[:,2], xaxis=:log, yaxis=:log, label=L"σ_{absorption}")
	plot!(legendfontsize=12, legendposition=:bottomleft)
end

# ╔═╡ 6b58361b-d4c4-46cd-a5d1-87163bcf4074
md"""#### Attenuation of Neutron Beam
From conservation of neutrons in beam: number scattered, absorbed, reacted removed from beam: ``\mathrm d N = - \mathrm d I``

Since
```math
\frac{N}{I} = n\Delta x\sigma \leftarrow \begin{cases}
N= In\sigma \Delta x \\
- \mathrm d I = In\sigma \mathrm d x
\end{cases}
```

Integrated, this yields attenuation formula in terms of total reaction cross section and foil density:
```math
I\left(x\right) = I_0\mathrm e^{-n\sigma x}
```

``\frac{I\left(x\right)}{I_0} = \mathrm e^{-n\sigma x}`` is probability of non-interaction

####  Macroscopic Cross Section

For nuclear engineering calculations macroscopic neutron cross section ``\Sigma\left(E\right)= n\sigma\left(E\right)`` becomes more useful

``\Sigma\left(E\right)`` effectively has units of: #/cm3 x cm2 = #/cm

####  Probability of Interaction

Probability of neutron interaction event in ``\mathrm d x`` is expressed as
```math
p\left(x\right) \mathrm d x = \Sigma \mathrm e^{- \Sigma x} \mathrm d x
```

Average distance traveled without interaction, or mean free path:
```math
\lambda = \int_0^{+\infty}xp\left(x\right) \mathrm d x = \frac{1}{\Sigma}
```

Distance traveled without interaction follows an exponential law with parameter ``\Sigma``

#### Fission
"""

# ╔═╡ c502fa5f-d884-4dd8-ad0f-588fa5efa317
begin
	data = CSV.read("lectures/data/sigma_fission.txt", DataFrame)
	const Nₐ = 6.02214086e23 # atoms / mole
	const ρᵤ = 19.1          # g / cm3
	const mᵤ = 235.0439299   # g / mole
	const nᵤ = ρᵤ * Nₐ / mᵤ
	const k = 1.38064852e-23
	const q = 1.60217662e-19
	E = 300 * k / q # eV
	@show E
	i = findfirst(x -> x > E, data[:, 1])
	σ300K = data[i, 2] + (E - data[i, 1]) / (data[i-1, 1] - data[i, 1]) * (data[i-1, 2] - data[i, 2])
	E = 2e6 # eV
	i = findfirst(x -> x > E, data[:, 1])
	σ2e6eV = data[i, 2] + (E - data[i, 1]) / (data[i-1, 1] - data[i, 1]) * (data[i-1, 2] - data[i, 2])
	@show σ300K σ2e6eV # barn
	Σ300K = nᵤ * σ300K * 1e-24
	Σ2e6eV = nᵤ * σ2e6eV * 1e-24
	@show Σ300K Σ2e6eV # cm-1
	λ300K = 1 / Σ300K
	λ2e6eV = 1 / Σ2e6eV
	@show λ300K λ2e6eV; # cm
	σ300K, σ2e6eV, Σ300K, Σ2e6eV, λ300K, λ2e6eV
end

# ╔═╡ ee3b48d1-7e23-4bb2-b1c0-928c13be6d54
md"""Fission of U235 yields on average: 2.44 total neutrons (1, 2, 3 or 4 depending on reaction)

Neutrons are ejected isotropically.

So due to the spherical symmetry, the angle ``\theta`` with the radius is determined by

```math
\cos\theta \approx \mathcal U\left(\left[-1,1\right]\right)
```

The distance from the center of a neutron created at radius ``r``, flying in the direction ``\theta`` for a distance ``d`` (exponentially distributed) is given by

```math
r^\prime = \sqrt{r^2 + d^2 + 2rd\cos\theta}
```

and the time of flight

```math
\Delta t = \frac{d}{v} = \displaystyle\frac{d}{\sqrt\frac{2E}{m}}
```"""


# ╔═╡ b4fa15a8-0f1e-4971-99fb-cc05d8fe352a
begin
	v300K = sqrt(2 * 300 * k / 1.674929e-27) # m/s
	Δt300K = λ300K / v300K / 100
	v2e6eV = sqrt(2 * 2e6 * q / 1.674929e-27) # m/s
	Δt2e6eV = λ2e6eV / v2e6eV / 100
	@show v300K v2e6eV Δt300K Δt2e6eV;
	v300K, v2e6eV, Δt300K, Δt2e6eV
end

# ╔═╡ 06a5bacd-1f40-448f-803a-94eddc3535a2
md"""Energy spectrum of released neutrons is also available from [NNDC](http://www.nndc.bnl.gov/sigma/index.jsp) but we will use the empirical Watt distribution:

```math
P\left(E\right)=0.4865\sinh\left(\sqrt{2E}\right)\mathrm e^{-E}
```"""

# ╔═╡ 51f9fd3b-2c80-40c6-8c0b-dc1a155cda07
let 
	logE = -8:0.1:1.5
	E = 10 .^(logE)
	plot(E, 0.4865 .* sinh.(sqrt.(2 .* E)) .* exp.(-E), label="Watt distribution", xlabel="E [MeV]", ylabel="Prob")
end

# ╔═╡ 0f1b1228-c95b-4494-99a5-03ef1ac521a9
md"""1 eV = 1.60217662 10-19 J

Neutrons created by fission are fast neutrons. Scattering is important to increase reaction rate!

#### Scattering

Scattering in the center of mass frame:
```math
E_\textrm{out} = E_\textrm{in} \frac{1}{2}\left((1+\alpha) + (1-\alpha)\cos\phi \right)
```

where ``\displaystyle\alpha = \left(\frac{A-1}{A+1}\right)^2`` and A=235 for U235.

The scattering angle in the laboratory frame yields:
```math
\cos\psi = \frac{A\cos\phi + 1}{\sqrt{A^2+2A\cos\phi+1}}
```

The probability of a neutron (initial kinetic energy ``E_\textrm{in}``) colliding and resulting in final neutron kinetic energy ``E_\textrm{out}`` is
```math
P\left\{E_\textrm{in}\rightarrow E_\textrm{out}\right\}=\frac{4\pi\displaystyle\frac{\mathrm d \sigma_s\left(\phi\right)}{\mathrm d \phi}}{\sigma_s E_\textrm{in}\left(1-\alpha\right)}
```

The differential cross section can also is also available from [NNDC](http://www.nndc.bnl.gov/sigma/index.jsp), but we will suppose the scattering happens isotropically in a solid angle so ``\cos\phi`` is distributed uniformally in the interval ``\left[-1,1\right]`` and we use the previous formulas to calculate ``\psi`` and ``E_\textrm{out}``.

The new ``\theta^\prime`` is uniformally distributed in the interval ``\left[\theta-\psi, \theta+\psi\right]``.

#### Neutron Multiplication Factor

A numerical measure of a critical mass is dependent on the effective neutron multiplication factor ``k``, the average number of neutrons released per fission event that go on to cause another fission event rather than being absorbed or leaving the material. When ``k=1``, the mass is critical, and the chain reaction is self-sustaining. So for each neutron we should log the amount of neutrons it generates before it dies. Afterwards we can take the average value of all of these and get an idea of the multiplication factor ``k``.

#### Spontaneous Fission

U235 has a halflife of 7.037 10^8 years and generates 1.86 neutrons. Spontaneous fission occurs 0.0003 times per g per s."""

# ╔═╡ 1b34e902-bfbf-47a9-98eb-7f87d4321f7c
const numberofspontaneousfis = 0.0003 # / g / s

# ╔═╡ 4c22c619-6331-49a7-a12d-104cf7d26c28
ρᵤ * 4/3 * π * 9^3 * 0.0003

# ╔═╡ dbbb18a2-5f3f-4608-b6f7-ae6e842c357c
md"""

### Atomic bomb simulation

Some additional constants:
"""

# ╔═╡ 4f66ef3d-c86b-40b5-8a23-1bb66812f878
begin
	const mₙ = 1.008664916    # g / mole
	const Mₙ = mₙ / Nₐ * 1e-3 # kg
	const A = mᵤ / mₙ
	const α = (A - 1)^2 / (A + 1) ^2
	nothing
end

# ╔═╡ 981a3d88-27ba-423c-81ef-f1b9a55d28fb
md"""#### Distributions"""

# ╔═╡ 74f1c90a-5ad5-430c-be10-01b352895b17
begin
	const cosΘdistr = Uniform(-1, 1)
	const cosϕdistr = Uniform(-1, 1)

	const energy = 1e-3:1e-3:15
	function wattspectrum(energy) # MeV
		0.453 * sinh(sqrt(2.29*energy))*exp(-1.036*energy)
	end
	
	const spectrum = wattspectrum.(energy)
	const wattdistr = Categorical(spectrum ./ sum(spectrum))

	const numberofneutronsdistr = Categorical([0,0.6,0.36,0.04])
	const numberofneutronsspontaneousdistr = Categorical([0.2,0.74,0.06])
end;

# ╔═╡ daad654f-1e88-49de-9c48-9dbad61ac5eb
md"""#### Data"""

# ╔═╡ 0fac615f-40ce-4337-893c-f7c5c50cf431
begin
	σt = CSV.read("lectures/data/sigma_total.txt", DataFrame)
	σf = CSV.read("lectures/data/sigma_fission.txt", DataFrame)
	σa = CSV.read("lectures/data/sigma_absorption.txt", DataFrame)
	σi = CSV.read("lectures/data/sigma_inelastic.txt", DataFrame)

	function Σ(energy::Float64) # 1 / cm
	    i = findfirst(e -> e > energy, σt[:, 1])
	    σ = σt[i, 2] + (energy - σt[i, 1]) / (σt[i-1, 1] - σt[i, 1]) * (σt[i-1, 2] - σt[i, 2])
	    nᵤ * σ * 1e-24
	end;

	function ΔtΔl(energy::Float64)
	    Δl = -log(rand()) / Σ(energy)
	    v = sqrt(2 * energy * q / Mₙ) * 100
	    Δl / v, Δl
	end;
end;

# ╔═╡ b9e94fc8-2030-45fb-9949-21d118747589
md"""#### Types and Callbacks"""

# ╔═╡ 3314490b-78b9-4372-a1be-29d8cff9370d
begin
	struct Bomb
	    radius :: Float64             # cm
	    generated :: Vector{Int64}
	    neutrons :: Vector{Int64}
	    times :: Vector{Float64}      # s
	    function Bomb(radius::Real)
	        new(radius, Float64[], Int64[], Float64[])
	    end
	end;

	mutable struct Neutron
		r :: Float64                  # cm
		cosθ :: Float64
		energy :: Float64             # eV
		function Neutron(r::Float64, energy::Float64, cosθ::Float64 = rand(cosΘdistr))
			new(r, cosθ, energy)
		end
	end
	
	function Neutron(sim::Simulation, bomb::Bomb, r::Float64, energy::Float64=energy[rand(wattdistr)] * 1e6)
		neutron = Neutron(r, energy)
		time = now(sim)
		@info("$time: create neutron at position $r with cosθ = $(neutron.cosθ) and energy = $(neutron.energy) eV")
		push!(bomb.times, time)
		push!(bomb.neutrons, 1)
		Δt, Δl = ΔtΔl(neutron.energy)
		@callback collision(timeout(sim, Δt), bomb, neutron, Δl)
	end
	
	function collision(ev::AbstractEvent, bomb::Bomb, neutron::Neutron, Δl::Float64)
		sim = environment(ev)
		time = now(ev)
		r′ = sqrt(neutron.r^2 + Δl^2 + 2*neutron.r*Δl*neutron.cosθ)
		if r′ > bomb.radius
			@info("$(now(sim)): neutron has left the bomb")
			push!(bomb.times, time)
			push!(bomb.neutrons, -1)
			push!(bomb.generated, 0)
		else
			i = findfirst(e -> e > neutron.energy, σt[:, 1])
			σtot = σt[i, 2] + (neutron.energy - σt[i, 1]) / (σt[i-1, 1] - σt[i, 1]) * (σt[i-1, 2] - σt[i, 2])
			i = findfirst(e -> e > neutron.energy, σf[:, 1])
			σfis = σf[i, 2] + (neutron.energy - σf[i, 1]) / (σf[i-1, 1] - σf[i, 1]) * (σf[i-1, 2] - σf[i, 2])
			i = findfirst(e -> e > neutron.energy, σa[:, 1])
			σabs = σa[i, 2] + (neutron.energy - σa[i, 1]) / (σa[i-1, 1] - σa[i, 1]) * (σa[i-1, 2] - σa[i, 2])
			i = findfirst(e -> e > neutron.energy, σi[:, 1])
			i = i == 1 ? 2 : i
			σin = σi[i, 2] + (neutron.energy - σi[i, 1]) / (σi[i-1, 1] - σi[i, 1]) * (σi[i-1, 2] - σi[i, 2])
			rnd = rand()
			if rnd < σfis / σtot
				n = rand(numberofneutronsdistr)
				@info("$(now(sim)): fission with creation of $n neutrons")
				for _ in 1:n
					Neutron(sim, bomb, r′)
				end
				push!(bomb.times, time)
				push!(bomb.neutrons, -1)
				push!(bomb.generated, n)
			elseif rnd < (σabs + σfis) / σtot
				@info("$(now(sim)): neutron absorbed")
				push!(bomb.times, time)
				push!(bomb.neutrons, -1)
				push!(bomb.generated, 0)
			elseif rnd < (σin + σabs + σfis) / σtot
				@info("$(now(sim)): inelastic scattering")
				n = 1
				Neutron(sim, bomb, r′)
				push!(bomb.times, time)
				push!(bomb.neutrons, -1)
			else
				cosϕ = rand(cosϕdistr)
				cosψ = (A * cosϕ + 1) / sqrt(A^2 + 2 * A * cosϕ +1)
				neutron.r = r′
				neutron.energy *= 0.5 * (1 + α + (1 - α) * cosϕ)
				θ = acos(neutron.cosθ)
				ψ = acos(cosψ)
				θplusψ = θ + ψ
				θminψ = ψ < π / 2 ? θ - ψ : θ - ψ + 2π
				neutron.cosθ = cos(θplusψ + rand() * (θminψ - θplusψ))
				@info("$(now(sim)): elastic scattering at position $r′ with cosθ = $(neutron.cosθ) and energy = $(neutron.energy) eV")
				Δt, Δl = ΔtΔl(neutron.energy)
				@callback collision(timeout(sim, Δt), bomb, neutron, Δl)
			end
		end
		((sum(bomb.generated) > 500 && sum(bomb.neutrons) == 0) || (time > 1 && sum(bomb.neutrons) == 0) || sum(bomb.generated) > 1000) && throw(StopSimulation())
	end

	function spontaneousfission(ev::AbstractEvent, bomb::Bomb)
	    sim = environment(ev)
	    for _ in rand(numberofneutronsspontaneousdistr)
	        Neutron(sim, bomb, rand() * bomb.radius)
	    end
	    rate = ρᵤ * 4/3 * π * bomb.radius^3 * numberofspontaneousfis
	    @callback spontaneousfission(timeout(sim, -log(rand()) / rate), bomb)
	end;
end

# ╔═╡ 492ca8f0-433a-449d-aa60-a135561cb8c3
bomb = let
	Logging.disable_logging(LogLevel(-1000));
	myradius = 9
	sim = Simulation()
	bomb = Bomb(myradius)
	@callback spontaneousfission(timeout(sim, 0.0), bomb)
	run(sim)
	bomb
end;

# ╔═╡ 7a8fb70d-92b6-4c85-9ba1-cb9d2db3ef2f
@info "Mean neutrons generated: $(mean(bomb.generated))"

# ╔═╡ f33701e6-0e61-482d-8b11-c993a9472903
let
	i = findlast(x->x==0, cumsum(bomb.neutrons))
	i = i === nothing ? 1 : i
	plot(bomb.times[i+1:end], cumsum(bomb.neutrons)[i+1:end], seriestype=:scatter, ylabel="N", xlabel="time [s]",label="")
end

# ╔═╡ 95895ea0-617f-4588-8066-e289dbed7bbc
md"""
### Monte Carlo approach
Now that we can run a single simulation, we can use this to determine the critical radius.
"""

# ╔═╡ 8c321132-b034-4e9b-a511-127c2736e49b
begin
	const RUNS = 100
	const RADII = 5:12;
	Logging.disable_logging(LogLevel(1000));
end;

# ╔═╡ a358bf3f-d917-4c50-80b2-5078e70e4b64
ks = let
	ks = zeros(Float64, RUNS, length(RADII))
	for (i, r) in enumerate(RADII)
		Threads.@threads for j in 1:RUNS # use multithreading if available  (each run is independent)
			sim = Simulation()
			bomb = Bomb(r)
			@callback spontaneousfission(timeout(sim, 0.0), bomb)
			run(sim)
			ks[j, i] = mean(bomb.generated)
		end
	end
	ks
end;

# ╔═╡ 60a5ccaa-8c82-4eef-beef-ef4239bb09a9
begin
	# data plot
	boxplot(reshape(collect(RADII), 1, length(RADII)), ks, alpha=0.25, label="", color=:lightblue)
	# for extra legend entry
	boxplot!([],[], alpha=0.25, label="Distribution")
	# mean neutrons generated
	scatter!(RADII, [mean(ks, dims=1) ...], color=:black, label=L"\langle k \rangle")
	# visuals
	plot!(xlabel="R [cm]", ylabel=L"k", legend=:bottomright, xticks=collect(RADII), title="Evolution ($(RUNS) simulations per radius)")
end

# ╔═╡ Cell order:
# ╟─4665a540-e8c8-466e-a2bc-3e74983bd683
# ╟─78afe080-f64f-4835-8f77-80ec906c2f13
# ╠═88b449e2-8ba3-4202-a22c-56be1ee7297b
# ╟─dc08f693-5ebc-44e8-b4b2-48e48aeee5c9
# ╟─59c0990c-f11d-4895-9cdd-32d9d644e617
# ╟─2d78885b-1673-4c75-a5c9-8ca7b4b9237e
# ╠═f2445950-a23b-4e98-b72a-37c28f0e894c
# ╠═40908b8a-6ed8-4442-b8bd-34c058b16de7
# ╟─0a7d94b3-1485-4377-9b49-20e79fdb3d4b
# ╠═91c493a7-a4bc-4284-956e-86567dc100d4
# ╟─5496024e-7376-420d-b13c-e157c574553e
# ╠═769c8fe3-9162-4cc9-82c5-3ce7a2c4805f
# ╟─4c7434d6-2e5b-4c45-af15-649b65caa875
# ╟─6e1d9ce1-d90b-4b9b-9e8e-9f474535c868
# ╟─b90b8319-b2f9-4948-a500-a7b6518db502
# ╟─6cc32888-d93f-473f-b4dc-0c21cb69608e
# ╟─12241581-863f-4717-b825-ff0cf357cc9c
# ╟─a783183d-50dd-4c7c-80ba-65c9d858682c
# ╟─4b81af14-bc99-475b-a52b-f1aaa1e60a1e
# ╟─b18f806c-8b26-4c54-b4a3-1c1acc2867d0
# ╟─ab9e17e5-9d3d-4790-924b-9de1ff8d55c2
# ╟─0ce6d4bf-37f3-445b-bce7-c4047c315ef5
# ╟─f58ffca5-cbfa-43e2-a145-c673887b97cf
# ╟─03457e65-1f4f-4ab8-9d56-a31d738ea633
# ╟─47830c86-6480-4228-b116-8ca72461a176
# ╟─05d321bf-4cc2-4d97-86b8-1325c3d63dbc
# ╟─2476451f-eecb-4713-9023-c7d1e2f38c55
# ╟─b11f2c5f-63f8-40bd-a90c-3598380860b4
# ╟─0d8f3619-5af4-45f3-b358-636a655ce4a7
# ╟─708ffc5b-83b6-48b2-a0d1-bdabd970ee9a
# ╟─a0db54fa-9ee7-40dd-92f6-f29265f83c63
# ╠═a39321e9-96f9-49e8-abb3-17fe4ab3a20e
# ╠═dcee775b-4283-4165-89db-b5fc87e0116c
# ╟─4707b42d-8200-4ceb-a206-6b2e25e233ae
# ╟─7b1be50c-9369-4ab6-8501-745f7f58080e
# ╠═eac9d6c6-9c58-4d29-8271-53e62049d1c1
# ╟─6b58361b-d4c4-46cd-a5d1-87163bcf4074
# ╠═c502fa5f-d884-4dd8-ad0f-588fa5efa317
# ╟─ee3b48d1-7e23-4bb2-b1c0-928c13be6d54
# ╠═b4fa15a8-0f1e-4971-99fb-cc05d8fe352a
# ╠═06a5bacd-1f40-448f-803a-94eddc3535a2
# ╠═51f9fd3b-2c80-40c6-8c0b-dc1a155cda07
# ╟─0f1b1228-c95b-4494-99a5-03ef1ac521a9
# ╠═1b34e902-bfbf-47a9-98eb-7f87d4321f7c
# ╠═4c22c619-6331-49a7-a12d-104cf7d26c28
# ╟─dbbb18a2-5f3f-4608-b6f7-ae6e842c357c
# ╠═4f66ef3d-c86b-40b5-8a23-1bb66812f878
# ╟─981a3d88-27ba-423c-81ef-f1b9a55d28fb
# ╠═74f1c90a-5ad5-430c-be10-01b352895b17
# ╟─daad654f-1e88-49de-9c48-9dbad61ac5eb
# ╠═0fac615f-40ce-4337-893c-f7c5c50cf431
# ╟─b9e94fc8-2030-45fb-9949-21d118747589
# ╠═3314490b-78b9-4372-a1be-29d8cff9370d
# ╠═492ca8f0-433a-449d-aa60-a135561cb8c3
# ╠═7a8fb70d-92b6-4c85-9ba1-cb9d2db3ef2f
# ╠═f33701e6-0e61-482d-8b11-c993a9472903
# ╟─95895ea0-617f-4588-8066-e289dbed7bbc
# ╠═8c321132-b034-4e9b-a511-127c2736e49b
# ╠═a358bf3f-d917-4c50-80b2-5078e70e4b64
# ╟─60a5ccaa-8c82-4eef-beef-ef4239bb09a9
