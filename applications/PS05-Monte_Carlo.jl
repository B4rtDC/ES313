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

# ╔═╡ bb35ea5b-7629-4831-9c21-0658d0979cee
begin
	# Pkg needs to be used to force Pluto to use the current project instead of making an environment for each notebook
	using Pkg
	# this is redundant if you run it through start.jl, but to make sure...
	while !isfile("Project.toml") && !isdir("Project.toml")
        cd("..")
    end
    Pkg.activate(pwd())
end

# ╔═╡ 5493a468-0c7a-4d63-bb0e-1adbf8d408ce
begin
	using Random
	using Plots, StatsPlots, LaTeXStrings, Measures, StatsBase
	using Statistics
	using Distributions
	using Graphs
	using BenchmarkTools
	using CSV, DataFrames
	using ConcurrentSim
	using Logging
	using PlutoUI
	using LinearAlgebra
	PlutoUI.TableOfContents()
end

# ╔═╡ ce6d0508-8283-11f0-2bcb-9b53de934eb4
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

# ╔═╡ 763fcc5e-94c5-4406-922e-3393b2f7b8c3
md"""
# Monte Carlo methods
As you will have discovered during the lectures, the term *Monte Carlo* covers a range of techniques that use repeated sampling to solve a complex problem. It can briefly be summarised as:

!!! tip "Monte Carlo"
	Monte Carlo methods are mathematical techniques that use repeated random sampling to estimate numerical results for problems that are difficult to solve analytically. 

	The core idea is to define a domain of inputs, randomly generate samples from that domain according to a probability distribution, perform computations on these samples, and then aggregate the results to approximate quantities such as integrals, expectations, or probabilities.

	By relying on the law of large numbers, Monte Carlo approximations improve in accuracy as the number of random samples increases.
"""

# ╔═╡ fc76551d-d553-4c69-a3e2-81b599671e80
md"""
## Options Pricing in Finance

We found that some students are drawn to financial topics for their projects. Unfortunately, none have managed to predict the market so far, so no Mark Zuckerberg–style school leavers just yet.

Nevertheless, Monte Carlo simulation has a very interesting application in the financial markets, which we will discover today.

First, let's cover some basic financial principles:
"""

# ╔═╡ 260fb4a7-9ee3-4344-abe6-0301c4864f6c
let
	intro_content = md"""
		!!! info "Definition"
			Quantitative finance is the application of mathematics, especially probability, statistics, and calculus, to model and understand financial markets. The aim is to describe how money, assets, and risks evolve over time in order to price securities, measure risk, and make informed investment decisions.  
		"""
	
	tv_content = md"""
A central idea is the **time value of money**: one euro today is worth more than one euro tomorrow, because it can be invested.  

!!! info "Risk-free interest rate"
	```math
	r_f
	```

	This is the return on a hypothetical investment with no risk of default, often approximated using government bonds. It acts as the "baseline growth rate" of money.

!!! info "Compound interest"
	If you invest an amount $P$ at an annual interest rate $r$, compounded **continuously**, the value after $t$ years is:
	```math
	V(t) = P e^{rt}
	```
	
	This exponential growth formula is the foundation of discounting and present-value calculations.
"""

	uv_content = md"""
Financial markets are uncertain: asset prices move unpredictably.  
This randomness is modeled mathematically using **stochastic processes**.  

!!! info "Volatility"
	```math
		\sigma 
	```

	A measure of how much the price of an asset fluctuates.  
	- High volatility → larger swings (higher risk and potential reward).  
	- Low volatility → more stability.  

In models like **geometric Brownian motion** (which we will use today), volatility governs the "speed" of random fluctuations in asset prices.
		"""

	rr_content = md"""
Investors expect compensation for taking risks.  
A common principle is:

```math
\text{Expected Return Rate} \approx \text{Risk-Free Rate} + \text{Risk Premium}
```

or
```math
		\mathbb{E}[R_i] = r_f + \pi_i
```

This trade-off between risk and reward is central to portfolio theory and asset pricing.
		"""

	more_content = md"""
With these components quantitative finance provides tools to:

- **Price derivatives** (e.g. the Black–Scholes model for options).  
- **Manage portfolios** by optimizing the balance between risk and return.  
- **Value bonds and interest-rate products** using models of the term structure.  
- **Assess risk** with measures such as Value at Risk (VaR) or Expected Shortfall.  
"""

	tv = PlutoUI.details("Time Value of Money and Interest Rates", tv_content, open=false)
	uv = PlutoUI.details("Uncertainty and Volatility", uv_content, open=false)
	rr = PlutoUI.details("Risk and Return", rr_content, open=false)

	PlutoUI.details("Introduction to Quantitative Finance", [intro_content, tv, uv, rr, more_content], open=true)
end	

# ╔═╡ dba762fa-2296-44fa-86d3-b7b8a187ee4d
md"""
In this application, we will cover the pricing of financial options:

!!! info "Options"
	An **option** is a financial contract granting the holder the right, but not the obligation, to buy or sell an underlying asset at a specified *strike price* within a specific time frame.

	There are two main types of options:
	* A **call** option gives the right to *buy* the asset.
	* A **put** option gives the right to *sell* the asset.
		
	Options differ by when the holder can exercise them:
	* **European options** can be exercised only at expiration (maturity).
	* **American options** can be exercised *any time* up to and including the expiration date, offering more flexibility.



One frequently used method of modeling stock prices, is with the [**Black-Scholes**](https://en.wikipedia.org/wiki/Black–Scholes_model) model, a mathematical model for the dynamics of a financial market containing derivative investment instruments. This model makes several assumptions, which we will not all cover here. However, one of the assumptions is the **Random walk**: 

!!! info "Random Walk"
	The instantaneous log return of the stock price is an infinitesimal random walk with drift; more precisely, the stock price follows a geometric Brownian motion, and it is assumed that the drift and volatility of the motion are constant.


Thus, the properties of the [**Geometric Brownian Motion (GBM)**](https://en.wikipedia.org/wiki/Geometric_Brownian_motion) can be used to simulate the stock prices. These prices are assumed to evolve continuously, with random fluctuations capturing market uncertainty. The GBM model defines that the logarithmic returns of the stock price follow a normal distribution, leading to the stock price itself following a lognormal distribution over time.

For this application we will consider European options with a fixed interest and volatility. We will cover two approaches:
* Through MC simulation
* Through mathematical derivation

The interested reader is encouraged to consult the references provided.
"""

# ╔═╡ ccaab93e-f9cf-4901-b247-4ae7f42c5e5f
md"""
### GBM

!!! info "Mathematical Model"
	An option on equity may be modelled with one source of uncertainty: the price of the underlying stock in question. Here the price of the underlying instrument $S_t$ is modelled such that it follows a geometric Brownian motion with constant drift $\mu$ ($=r$) and volatility $\sigma$. So
	```math
	dS_t = \mu S_t dt + \sigma S_t dW_t
	```
	where $W_t$ is a so-called *Wiener process* conforming to standard Brownian motion. $dW_t$ is found via random sampling from a normal distribution.

	The discrete approximation then takes the form, over a timestep $\Delta t$:
	```math
	S_{t+\Delta t} = S_t \times e^{\left(\left( \mu - \frac{\sigma^2}{2} \right) \Delta t + \sigma \sqrt{\Delta t} Z_t \right)}
	```
	where $Z_t$ is a sample from a standard normal distribution.

This brings us to following MC steps:

!!! tip "MC steps"
	1. *Initialize*: Set the initial price $S_0$, drift $\mu$, volatility $\sigma$ and simulation horizon $T$.
	2. *Discretize*: Steps $\Delta t$
	3. *Simulate multiple paths*: Run the simulation multiple times and get multiple sequences.
	4. *Analyze*: Extract relevant information, *in casu* option prices.

The option pricing can then be obtained.

!!! info "Option Pricing"
	The price you should charge for an option can then easily be computed using:
	* **Call**:
	```math
	P_i = \max(S_i - K, 0)
	```
	Leading to
	```math
	P = \bar{\boldsymbol{P}} \times e^{-r T}
	```
	
	* **Put**:
	```math
	P_i = \max(K - S_i, 0)
	```
	Leading to
	```math
	P = \bar{\boldsymbol{P}} \times e^{-r T}
	```
	where $i$ refers to the index of your simulation instance and the exponential term is included for discounting the intrinsic value back to present value.
"""

# ╔═╡ 332c5503-5337-4f9f-942e-f1abe4746090
"""
    mc_stock_price(S0, mu, sigma, T, n_steps, n_rep)

Simulates the evolution of stock prices using the Geometric Brownian motion model via Monte Carlo simulation.

# Arguments
- `S0`: Initial stock price.
- `mu`: Expected return (drift).
- `sigma`: Volatility of the stock.
- `T`: Total time horizon (in years).
- `n_steps`: Number of time steps.
- `n_rep`: Number of simulation repetitions.

# Returns
- `prices`: A matrix of simulated stock prices of size (n_rep, n_steps+1).
"""
function mc_stock_price(S0, mu, sigma, T, n_steps, n_rep)
	# Set a random seed
	Random.seed!(42)
	
    prices = zeros(n_rep, n_steps+1)
    prices[:, 1] .= S0
    
	dt = T / n_steps
    
	mudt = (mu - 0.5 * sigma^2) * dt
    sigdt = sigma * sqrt(dt)
    
	for i in 1:n_rep
        for j in 1:n_steps
            prices[i, j+1] = prices[i, j] * exp(mudt + sigdt * randn())
        end
    end
    return prices
end

# ╔═╡ 4c624322-5a1d-4ebd-ba6c-f2f83284093b
md"""
We can now establish the price you should charge/pay for an option given a variety of possible outcomes
"""

# ╔═╡ 9a85c43a-4d88-48e3-b569-a13e410375e8
md"""
Given the current use case, we can also use the classical Black-Scholes formula as a comparison:
!!! info "Black-Scholes Price Formula"
	The **Black–Scholes model** gives closed-form solutions for the fair value of European call and put options. It assumes constant volatility, continuous compounding at the risk-free rate, and lognormally distributed asset prices.
	```math
	d_1 = \frac{\ln\!\left(\tfrac{S_0}{K}\right) + \left(r + \tfrac{1}{2}\sigma^2\right)T}{\sigma\sqrt{T}}, 
	\quad
	d_2 = d_1 - \sigma \sqrt{T}
	```
	with:

	* Variable $S_0$: current price of the underlying asset. 
	* Variable $K$ : strike price  
	* Variable $r$ : interest rate  
	* Variable $\sigma$ : volatility of the underlying asset  
	* Variable $T$ : time to maturity  
	* Variable $N(\cdot)$ : cumulative distribution function (CDF) of the standard normal distribution

	The price for a **call** option is:
	```math
	C = S_0 \, N(d_1) - K e^{-rT} N(d_2)
	```

	The price for a **put** option is:
	```math
	P = K e^{-rT} N(-d_2) - S_0 \, N(-d_1)
	```
	where you see the discounting exponential to todays value.

"""

# ╔═╡ 8f1f9d83-bc20-43b6-adbc-cdc58cefd33a
md"""
## Bayesian Inference
One of the applications you covered during the lectures, is Bayesian inference. To reiterate:

!!! info "Basic Proba"
	We learned that:

	```math
	P(A \cap B) = P(A | B) P(B)
	```

	And at the same time:

	```math
	P(B \cap A) = P(B | A) P(A)
	```

	Thus:
	```math
	P(A | B) = \frac{P(B|A)P(A)}{P(B)}
	```

The expressions for continuous distributions are analogous, which leads directly to Bayesian inference:


!!! info "Bayesian Inference"
	Bayesian inference is a statistical method for updating our knowledge about unknown parameters based on observed data. It combines a prior belief about the parameters with the likelihood of the observed data to produce a posterior distribution, which represents the updated belief after considering the evidence.

	```math
	P(\theta | y ) = \frac{P( y  | \theta ) \cdot P(\theta)}{P(y)},
	```
	where $\theta$ are the parameters, $y$ represents the data, $P(\theta | y)$ represents the posterior, $P( y  | \theta )$ the likelihood and $P(\theta)$ the prior.

	This framework allows continuous refinement of beliefs as new data becomes available, making Bayesian inference a powerful tool for statistical modeling and decision-making.
"""

# ╔═╡ e95fb99e-d4a6-4115-bb0e-b744f2de34ef
md"""
## Model Fitting
In this practical session, we will use Bayesian inference for an extremely common problem in the engineering sciences: model fitting. We can show that a Bayesian approach offers considerable advantages with respect to the traditional deterministic methods:
- In stead of point estimates, you obtain a distribution.
- You can incorporate prior knowledge into the model based on physical limitations.

### Linear Regression

We will create a synthetic dataset with randomly generated noise:
"""

# ╔═╡ 2354a6e7-f0b5-4c16-a8ce-d6537dd3a013
begin
	# Set a random seed for reproducibility
	Random.seed!(42)

	# Generate synthetic data
	# Set the parameters
	N = 100
	theta0 = 1
	theta1 = 2
	sigma = 0.3

	# Create x and y coordinates, with normally distributed noise added to the y component.
	x = range(0, 1; length=N)
	y = theta0 .+ theta1 .* x .+ randn(N) .* sigma

	# Plot the results
	scatter(x, y; title="Synthetic Data", xlabel="x", ylabel="y", grid=true, legend=false)
end

# ╔═╡ 2add76c6-5a92-41f2-8fe2-4f6a2c030753
begin
	# We introduce the parameters for our simulation:
	S0 = 100 # Initial Stock Value
	r = 0.05 # Expected return
	mu = r # To avoid confusion
	sigma_v = 0.25 # Volatility
	T = 1.0 # 1 year
	n_steps = 365*24 # hourly steps
	n_rep = 100 # Amount of repetitions of the simulation

	# Run the MC simulation
	prices = mc_stock_price(S0, mu, sigma, T, n_steps, n_rep)

	# Show the results
	plot(prices', legend=false, xlabel="Time Step", ylabel="Stock Price", title="Monte Carlo Simulations of Stock Prices", alpha=0.8, size=(1000,600))
end

# ╔═╡ ee99ed21-05bd-4136-a490-e298298ee831
md"""
With our prior knowledge of the scattered data, we anticipate that a linear function would be a perfect fit to the model. We create a Bayesian model to fit the data:

!!! tip "Model"
	* **The model**: 
	```math
	y = \theta_0 + \theta_1 x + \epsilon
	```

	where we assume gaussian noise for $\epsilon$.

	* **Bayes**: 
	```math
	P(\boldsymbol{\theta}, \sigma | \boldsymbol{y}) \propto P(\boldsymbol{y} | \boldsymbol{\theta}, \sigma) P(\boldsymbol{\theta}) P(\sigma)
	```
	where we have 2 priors, for $\boldsymbol{\theta}$ and for $\sigma$.

	* **Likelihood**: 
	```math
	\boldsymbol{y} \sim \mathcal{N}(\mu, \sigma)
	```
	where ``\mu = \theta_0 + \theta_1 x``
"""

# ╔═╡ c33b6c5a-d838-4ad7-b9e2-e145bf66c2b4
let
	slope_content = md"""
If we use the angle $\alpha$ of our straight line rather than the slope $\theta_1$ (i.e. ``\theta_1 = \tan \alpha``), it is easier to choose a prior:
```math
\alpha \sim \mathcal{U}(-\pi/2, +\pi/2)
```
To compute the PDF of $\theta_1 = \tan(\alpha)$ given a prior on $\alpha$ (e.g., $\alpha \sim \mathcal{U}(-\pi/2, +\pi/2)$), you use the change of variables formula for transforming random variables:

Let $f_\alpha(\alpha)$ be the PDF of $\alpha$. For the transformation $\theta_1 = \tan(\alpha)$, the PDF of $\theta_1$ is:
```math
f_{\theta_1}(\theta_1) = f_\alpha(\arctan(\theta_1)) \left| \frac{d}{d\theta_1} \arctan(\theta_1) \right| = f_\alpha(\alpha) \cdot \frac{1}{1 + \theta_1^2}
```

For a uniform prior $\alpha \sim \mathcal{U}(-\pi/2,+\pi/2)$, the density is $f_\alpha(\alpha) = \frac{1}{\pi}$ for $\alpha$ in that interval, so:
```math
f_{\theta_1}(\theta_1) = \frac{1}{\pi} \cdot \frac{1}{1 + \theta_1^2}
```


for all real $\theta_1$, since $\arctan(\theta_1)$ maps $\mathbb{R}$ to $(-\pi/2, +\pi/2)$.

This means $\theta_1$ follows a standard Cauchy distribution if $\alpha$ is uniform over $(-\pi/2, +\pi/2)$.

**In summary**: If you sample $\alpha$ uniformly on $(-\pi/2, +\pi/2)$ and work with $\theta_1 = \tan(\alpha)$, $\theta_1$ is distributed according to the standard Cauchy PDF:
```math
f_{\theta_1}(\theta_1) = \frac{1}{\pi} \cdot \frac{1}{1 + \theta_1^2}
```
"""

	intercept_content = md"""
		For the intercept we take a very broad Gaussian:
		```math
		\theta_0 \sim \mathcal{N}(0,20)
		```
		"""

	std_content = md"""
		For the standard deviation $\sigma$ of the likelihood, we take a broad [Half-Cauchy](https://en.wikipedia.org/wiki/Cauchy_distribution) distribution:
		```math
		\sigma \sim \mathcal{HC}(0,3)
		```
		"""

	slope = PlutoUI.details("Slope", [slope_content], open=false)
	intercept = PlutoUI.details("Intercept", [intercept_content], open=false)
	std = PlutoUI.details("Std", [std_content], open=false)
	PlutoUI.details("Priors",[slope, intercept, std], open=true)
end

# ╔═╡ 5b617b5d-723a-4292-90be-71dc34284801
md"""
We apply the Metropolis-Hastings sampling approach (as seen during the lectures) to sample from the distributions of $\boldsymbol{y}$ and $\sigma$. A great example to the practical implementation of MH-sampling (and other methods) can be found [here](https://chi-feng.github.io/mcmc-demo/app.html?algorithm=RandomWalkMH&target=banana).
"""

# ╔═╡ 4329f67a-861a-4893-a9c3-ca3c7a99e04b
begin
	"""
	    log_prior(theta0, theta1, sigma)
	
	Computes the log prior probability for the parameters of the Bayesian linear regression model.
	
	# Arguments
	- `theta0`: Intercept parameter.
	- `theta1`: Slope parameter.
	- `sigma`: Noise standard deviation.
	
	# Returns
	- The sum of log prior probabilities for `theta0`, `theta1`, and `sigma`:
	    - `theta0` ~ Normal(0, 20)
	    - `theta1` ~ Cauchy(0, 1)
	    - `sigma` ~ HalfCauchy(β=3)
	"""
	function log_prior(theta0, theta1, sigma)
	    log_pdf_theta0 = logpdf(Normal(0, 20), theta0)
	
	    log_pdf_theta1 = logpdf(Cauchy(0, 1), theta1)
	
	    base_dist = Cauchy(0,3)
	
	    half_cauchy = truncated(base_dist, 0, Inf)
	    log_pdf_sigma = logpdf(half_cauchy, sigma)
	
	    return log_pdf_theta0 + log_pdf_theta1 + log_pdf_sigma
	end

	"""
	    log_likelihood(x, y, theta0, theta1, sigma)
	
	Computes the log likelihood of the observed data `y` given the predictors `x` and model parameters
	for Bayesian linear regression.
	
	# Arguments
	- `x`: Array of predictor variable values.
	- `y`: Array of observed response variable values.
	- `theta0`: Intercept parameter.
	- `theta1`: Slope parameter.
	- `sigma`: Noise standard deviation.
	
	# Returns
	- The sum of log likelihoods for each data point, assuming
	  `y_i ~ Normal(theta0 + theta1 * x_i, sigma)`.
	"""
	function log_likelihood(x, y, theta0, theta1, sigma)
	    mu = theta0 .+ theta1 .* x
	    return sum(logpdf.(Normal.(mu, sigma), y))
	end
	
	"""
    metropolis_hastings(x, y, num_iterations, sigma_mh, log_prior, log_likelihood)

	Runs the Metropolis-Hastings MCMC algorithm to sample from the posterior distribution of the parameters
	of a Bayesian linear regression model.
	
	# Arguments
	- `x`: Array of predictor variable values.
	- `y`: Array of observed response variable values.
	- `num_iterations`: Number of MCMC iterations to run.
	- `sigma_mh`: Standard deviation of the proposal distribution for each parameter.
	- `log_prior`: Function that computes the log prior probability of the parameters.
	- `log_likelihood`: Function that computes the log likelihood of the data given the parameters.
	
	# Returns
	- `samples_0`: Array of sampled values for θ₀ (intercept).
	- `samples_1`: Array of sampled values for θ₁ (slope).
	- `samples_sigma`: Array of sampled values for σ (noise standard deviation).
	"""
	function metropolis_hastings(x, y, num_iterations, sigma_mh, log_prior, log_likelihood)
	    # Initialize parameters
	    theta0_current = 1.0
	    theta1_current = 1.0
	    sigma_current = 0.3  # Known noise level
	
	    samples_0 = Float64[]
	    samples_1 = Float64[]
	    samples_sigma = Float64[]
	
	    for t in 1:num_iterations
	        # Propose new parameters
	        theta0_proposed = theta0_current + randn() * sigma_mh
	        theta1_proposed = theta1_current + randn() * sigma_mh
	        sigma_proposed = sigma + randn() * sigma_mh
	
	        if theta1_proposed < 0 || sigma_proposed < 0
	            # Reject the proposal
	            continue
	        end
	
	        # Compute acceptance ratio
	        log_acceptance_ratio = log_likelihood(x, y, theta0_proposed, theta1_proposed, sigma_proposed) + log_prior(theta0_proposed, theta1_proposed, sigma_proposed) -
	                                (log_likelihood(x, y, theta0_current, theta1_current, sigma_current) + log_prior(theta0_current, theta1_current, sigma_current))
	
	        # Accept or reject the proposal
	        if log(rand()) < log_acceptance_ratio
	            theta0_current = theta0_proposed
	            theta1_current = theta1_proposed
	            sigma_current = sigma_proposed
	        end
	
	        # Store the samples
	        push!(samples_0, theta0_current)
	        push!(samples_1, theta1_current)
	        push!(samples_sigma, sigma_current)
	    end
	
	    return samples_0, samples_1, samples_sigma
	end
end

# ╔═╡ e26aa995-3355-4664-96b7-efd6b0b206a5
begin
	# Settings for the algorithm
	num_iterations = 1000000
	burn_in = 2000
	sigma_mh = 0.3
	
	# Run the algorithm
	samples_theta0, samples_theta1, samples_sigma = metropolis_hastings(x, y, num_iterations, sigma_mh, log_prior, log_likelihood)
	
	# Get rid of the burn_in
	samples_theta0 = samples_theta0[burn_in+1:end]
	samples_theta1 = samples_theta1[burn_in+1:end]
	samples_sigma = samples_sigma[burn_in+1:end]
end

# ╔═╡ 7bf3a052-c1bc-46b3-8e6a-0185afe6df74
md"""
For the analysis of the results, we will follow a dual approach:
!!! tip "Analysis"
	* First and foremost we represent our data as a histogram, on which we identify the mean and confidence interval.
	* Secondly, we must verify whether or not our sampling was succesful. This implies making sure that the algorithm did not get stuck in a local maximum. We will do this by plotting the 'trace'. A trace plot shows the sampled values of a parameter across the iterations of the MCMC algorithm. It helps visualize how the Markov chain explores the parameter space over time. A good trace plot looks “noisy” without obvious trends, oscillating around a stable mean, indicating that the chain has reached its target (stationary) distribution and mixes well. Poor trace plots may show trends, slow movement, or get stuck, which signal issues like lack of convergence or poor mixing.
"""

# ╔═╡ 10ede4a2-1703-4c27-801d-c7502a88997d
let
	# Create the histograms
	nbins = 100
	
	# θ₀
	mean_theta0 = mean(samples_theta0)
	ci_theta0 = quantile(samples_theta0, [0.025, 0.975])
	p1 = histogram(samples_theta0, bins=nbins, title="Posterior of \$\\theta_0\$", xlabel="θ0", ylabel="Density", legend=false, normalize=:pdf)
	vline!(p1, [mean_theta0], color=:red, label="Mean")
	vline!(p1, ci_theta0, color=:blue, linestyle=:dash, label="95% CI")
	
	# θ₁
	mean_theta1 = mean(samples_theta1)
	ci_theta1 = quantile(samples_theta1, [0.025, 0.975])
	p2 = histogram(samples_theta1, bins=nbins, title="Posterior of \$\\theta_1\$", xlabel="θ1", ylabel="Density", legend=false, normalize=:pdf)
	vline!(p2, [mean_theta1], color=:red, label="Mean")
	vline!(p2, ci_theta1, color=:blue, linestyle=:dash, label="95% CI")
	
	# σ
	mean_sigma = mean(samples_sigma)
	ci_sigma = quantile(samples_sigma, [0.025, 0.975])
	p3 = histogram(samples_sigma, bins=nbins, title="Posterior of σ", xlabel="σ", ylabel="Density", legend=false, normalize=:pdf)
	vline!(p3, [mean_sigma], color=:red, label="Mean")
	vline!(p3, ci_sigma, color=:blue, linestyle=:dash, label="95% CI")

	# Plot the trace of the MCMC samples
	p4 = plot(samples_theta0, title="Trace of \$\\theta_0\$", xlabel="Iteration", ylabel="θ0", legend=false)
	p5 = plot(samples_theta1, title="Trace of \$\\theta_1\$", xlabel="Iteration", ylabel="θ1", legend=false)
	p6 = plot(samples_sigma, title="Trace of σ", xlabel="Iteration", ylabel="σ", legend=false)

	# Plot the histograms and the traces on one figure
	plot(p1, p4, p2, p5, p3, p6, layout=(3, 2), size=(1200,800))
end

# ╔═╡ 20856d2f-b26e-4c7e-a283-8dbb53af7b9c
begin
	nbins = 200
	
	h1 = fit(Histogram, samples_theta0; nbins=nbins)
	h2 = fit(Histogram, samples_theta1; nbins=nbins)
	h3 = fit(Histogram, samples_sigma; nbins=nbins)
	
	# find the bin with the maximum count
	imax1 = argmax(h1.weights)
	imax2 = argmax(h2.weights)
	imax3 = argmax(h3.weights)
	
	# extract the MAP estimate as the center of that bin
	map_theta0 = (h1.edges[1][imax1] + h1.edges[1][imax1+1]) / 2
	map_theta1 = (h2.edges[1][imax2] + h2.edges[1][imax2+1]) / 2
	map_sigma = (h3.edges[1][imax3] + h3.edges[1][imax3+1]) / 2

	# Print the MAP estimates
	println("MAP estimate for θ0: ", map_theta0)
	println("MAP estimate for θ1: ", map_theta1)
	println("MAP estimate for σ: ", map_sigma)
end

# ╔═╡ 9cedbe14-a962-46fd-b271-e6ca78930e38
let
	# Plot the MAP fit
	plt = plot(x, map_theta0 .+ map_theta1 .* x, color=:red, linewidth=2, label="MAP Fit", title="Fitted Data with Posterior Samples", xlabel="x", ylabel="y")

	# Plot the synthetic dataset
	scatter!(plt, x, y, color=:blue, label="Data", markersize=1)

	# Plot (some) of the other options obtained through sampling
	M = length(samples_theta1) ÷ 1000
	for n in 1:M:length(samples_theta1)
	    plot!(plt, x, samples_theta0[n] .+ samples_theta1[n] .* x, color=:gray, alpha=0.02, linewidth=1, legend=false)
	end
	plot(plt, size=(1000,800))
end

# ╔═╡ 73f63ce0-82a4-4eb8-8809-de240e2675bc
md"""
## Particle Filter - Spinning Rod State Estimation

Another prime example of the use of Monte Carlo simulation, is the functioning of the particle filter. A "filter" is an algorithm that estimates the current, hidden state of a system (like a robot's position) by combining a prediction of how that state evolves over time with noisy observations, continually updating that estimate as new data arrives. As the name suspects, a particle filter achieves this goal by dispersing the hidden state of a system over multiple particles. The "best" state estimate can be retrieved through statistical inference.

In this example, we will apply the particle filter to estimate the state of a pendulum (2D), of which only one dimension can be measured. This example is on the applications by Dr. Hae-In Lee, Cranfield University.

Before we explain the mathematical details of a particle filter, let us first look at an example provided by the [University of Texas](https://amrl.cs.utexas.edu/interactive-particle-filters/) which helps grasp the practical use case.

We will now build a **particle filter** from scratch and use it to track the angle and angular velocity of a spinning rod from noisy, highly non-linear measurements.

The problem is depicted on the following figure:
"""

# ╔═╡ 14266c3f-9111-41d5-8e5b-2bc0073c7ce6
LocalResource("./applications/img/pendulum.svg", :width => 800)

# ╔═╡ 1b9f8e83-24e2-40c9-abef-f9d3dd8701e7
md"""
### Problem definition — System dynamics

A weightless rigid rod of length $L$ is pivoted at one end and carries a point mass at the other. It makes an angle $\theta$ with the horizontal, and its instantaneous angular acceleration obeys

$$\ddot\theta(t) = \frac{1}{L}\big(-g + w(t)\big)\cos\theta(t)$$

where $g$ is gravity and $w(t)$ is a zero-mean, white, Gaussian "driving" disturbance (variance $\sigma_w^2$). Discretising with time step $\Delta t$ gives the state-space model, with state $x_k = [\theta_k,\ \dot\theta_k]^T$:

$$\theta_k = \mathrm{mod}\Big(\theta_{k-1} + \Delta t\,\dot\theta_{k-1} + \tfrac{\Delta t^2}{2L}(-g+w_{k-1})\cos\theta_{k-1},\ 2\pi\Big)$$
$$\dot\theta_k = \dot\theta_{k-1} + \tfrac{\Delta t}{L}(-g+w_{k-1})\cos\theta_{k-1}$$

The `mod(·, 2π)` wrap-around is exactly the kind of non-linearity a Kalman filter cannot represent with a Gaussian — it is trivial for a particle filter, since each particle is just propagated through the (noise-driven) state transition.

### Problem definition — Measurement model

We only ever observe the length of the rod **projected** onto a vertical axis, $L|\sin\theta_k|$. Two sensor types are modelled:

**Gaussian sensor**

$$z_{k} = L|\sin\theta_k| + v_k, \qquad v_k \sim \mathcal N(0,\sigma_v^2)$$

$$p(z_k \mid x_k) = \frac{1}{\sqrt{2\pi R}}\exp\!\left(-\tfrac12 R^{-1}\big(z_k - L|\sin\theta_k|\big)^2\right), \qquad R=\sigma_v^2$$

**Quantised (digital) sensor**, resolution $\delta$

$$z_k = \mathcal Q_\delta\big(L|\sin\theta_k|\big), \qquad \mathcal Q_\delta(x) = (n-1)\delta \text{ for the integer } n \text{ s.t. } (n-1)\delta < x \le n\delta$$

$$p(z_k \mid x_k) = \begin{cases} 1 & \text{if } z_k < L|\sin\theta_k| \le z_k + \delta \\ 0 & \text{otherwise}\end{cases}$$

In other words, a quantised reading only tells us that the true projection lies *somewhere* in a bin of width $\delta$ — every $\theta$ consistent with that bin is equally likely, and every $\theta$ outside it is impossible. Both likelihoods are needed for the particle weighting step later on.


!!! info "Why a particle filter for this problem?"

	A recursive Bayesian estimator updates a belief about the state $x_k$ using
	
	$$p(x_k \mid Z_{k-1}) = \int p(x_k \mid x_{k-1})\, p(x_{k-1}\mid Z_{k-1})\, dx_{k-1} \qquad \text{(prediction)}$$
	
	$$p(x_k \mid Z_k) = \frac{p(z_k\mid x_k)\, p(x_k \mid Z_{k-1})}{\int p(z_k \mid x_k)\, p(x_k\mid Z_{k-1})\, dx_k} \qquad \text{(update)}$$
	
	These integrals are only tractable in closed form for the linear-Gaussian case (the Kalman filter). Our pendulum problem breaks that assumption in three ways:
	
	1. The measurement $z_k = L|\sin\theta_k|$ is **strongly non-linear** and even non-monotonic in $\theta_k$.
	2. The angle $\theta_k$ **wraps around** at $2\pi$, which a Gaussian cannot represent.
	3. The resulting posterior is often **multi-modal** (several equally plausible angles explain the same projection) and sometimes **highly skewed** — a mean/covariance summary (as used by the EKF) is a poor description of it.

A **particle filter** sidesteps all of this by representing the posterior as a large *set of weighted samples* ("particles") instead of a closed-form density. We will:

!!! tip "Tasks"

	1. Simulate the true pendulum trajectory and two types of noisy sensor (Gaussian noise vs. a quantised/digital sensor),
	2. Implement the predict &rarr; weight &rarr; resample particle filter loop,
	3. Visualise how the particle cloud bifurcates and re-converges as the angle becomes observable/unobservable,
	4. Compare the result against an Extended Kalman Filter (EKF) to see exactly where the Gaussian assumption breaks down, and
	5. As an appendix, compare a few numerical integration schemes to see why the discrete dynamics model (Eq. 2 below) is built the way it is.
"""

# ╔═╡ 9e43da0a-eab5-4cf2-8dee-2d8f92788ed6
md"""
### Simulation flags and parameters

* `animation_enabled` — build the live particle-cloud animation (and export a GIF) at the end of the run.
* `gaussian_update_enabled` — `true` uses the Gaussian likelihood, `false` uses the quantisation likelihood.
* `comparison_EKF` — also run an Extended Kalman Filter over the same measurements for comparison.

The parameters are defined in following table:

| variable | meaning | value |
|:---------|:--------|:------|
| dt | time step (s) | 0.05 |
| L | pendulum length (m) | 3 |
| Q | process noise variance (m²/s⁴) | 10 |
| - | initial true angle (rad) | 0.3 |
| - | initial estimated angle (rad) | $U(0, 2\pi)$ |
| tf | simulation time (s) | 10 |
| g | gravitational constant (m/s²) | 9.81 |
| R | measurement noise variance (m²) | 0.02 |
| - | initial true angular velocity (rad/s) | 2 |
| - | initial estimated angular velocity (rad/s) | $N(2.4, 0.4^2)$ |
"""

# ╔═╡ 5665f7b4-e7e8-4d0e-bba3-dabce34a6d77
begin
	# Simulation settings (flags)
	const animation_enabled = true
	const gaussian_update_enabled = true
	const comparison_EKF = true
	
	# Set the rng seed for reproducibility
	Random.seed!(1234)
end

# ╔═╡ 4ccceb6d-8d2c-4f21-8bd7-124b0f67c2cf
md"""
**Equations to Code**

`funsys` implements the discrete dynamics model above: given a state `x = [θ, θ̇]` and a scalar draw of process noise `w`, it returns the next state, wrapping `θ` into $[0,2\pi)$ with `mod`.

`funmeas_Gauss` and `funmeas_Quant` implement the two measurement models respectively, and `funpos` converts a state into Cartesian $(x,y) = (L\cos\theta, L\sin\theta)$ coordinates purely for plotting the rod tip.
"""

# ╔═╡ a93db58d-14d1-4350-a73a-19e909427e4e
begin
	# Define the scenario
	# time
	dt = 0.05 # time step
	tf = 10.0 # final simulation time
	t = 0:dt:tf # time vector
	numSteps = length(t) # number of time steps
	
	# parameters
	L = 3.0
	g = 9.81
	delta = 1.0 # Resolution of the quantization error
	
	# system / measurement equations
	funsys(x, w) = [
	    mod(x[1] + dt*x[2] + dt^2/(2*L)*(-g + w)*cos(x[1]), 2π);
	    x[2] + dt/L*(-g + w)*cos(x[1])
	]   # x[1] = θ, x[2] = θ̇
	
	funmeas_Gauss(x, v) = abs.(L .* sin.(x[1, :])) .+ v
	
	funmeas_Quant(x) = (floor.(L .* abs.(sin.(x[1, :])) ./ delta)) .* delta
	
	# ensure funpos returns a 2 x numSteps matrix
	funpos(x) = vcat((L .* cos.(x[1, :]))', (L .* sin.(x[1, :]))')
	end

# ╔═╡ ae081a80-322b-4207-9676-4cb2f3f05b3a
md"""

**Simulating the true trajectory**

We roll the dynamics model forward once, starting from $\theta_0=0.3$ rad, $\dot\theta_0=2$ rad/s, drawing a fresh Gaussian process-noise sample $w_{k-1}\sim\mathcal N(0,Q)$ at every step. This `trueState` trajectory is the ground truth the filter will try to recover — it is **not** available to the filter itself, only used afterwards to judge estimation error.
"""

# ╔═╡ 711c2db9-8b28-425a-8b19-fc3cf3fb4bbb
begin
	# Generate true states:
	trueState = [0.3; 2].*ones(2, numSteps) # initialize state matrix
	procNoise = sqrt(10).*randn(1, numSteps) # process noise
	for i in 2:numSteps
	    trueState[:, i] = funsys(trueState[:, i-1], procNoise[i-1])
	end
	truePos = funpos(trueState)
end

# ╔═╡ 4ade7deb-f3cd-4e54-a7d1-cb8580d37aec
md"""

**Simulating the sensor readings**

From the true trajectory we generate both a Gaussian-noise measurement stream and a quantised measurement stream. `measurements` is whichever of the two the filter will actually consume, selected by the `gaussian_update_enabled` flag set above.
"""

# ╔═╡ 324f6b86-81c0-469f-ac1e-de8fcc0b2b39
begin
	# Generate measurements:
	measNoise = sqrt(0.02).*randn(numSteps) # measurement noise (vector, not matrix)
	measGauss = funmeas_Gauss(trueState, measNoise) # Gaussian measurements
	measQuant = funmeas_Quant(trueState) # Quantized measurements
	measurements = gaussian_update_enabled ? measGauss : measQuant
end

# ╔═╡ 8aee80e0-da25-4438-9ca5-1803d725385b
md"""

**Making a first figure**

The plot below overlays the true projected length $L|\sin\theta_k|$ with both simulated sensor outputs. Notice how the quantised sensor "staircases" around the true curve, while the Gaussian sensor scatters continuously around it — these two very different error structures are exactly why the likelihood function used in the update step matters so much.
"""

# ╔═╡ 7c1e3a47-0614-40d8-9274-e5d583054a48
begin
	# Make a figure
	plot(t, L*abs.(sin.(trueState[1, :])), label="True position", linewidth=2, color=:black, size=(800, 400), grid=true)
	plot!(t, measGauss, label="Measurements (Gaussian)", color=:red, markersize=4)
	plot!(t, measQuant, label="Measurements (Quantized)", color=:blue, markersize=4)
	xlabel!("Time [s]")
	ylabel!("Position [m]")
	title!("Pendulum position measurements")
end

# ╔═╡ 31b39d05-147b-4b46-97b4-f10d57299e0f
md"""
### The particle filter algorithm

A particle filter represents the posterior $p(x_k\mid Z_k)$ by a set of $N$ weighted samples $\{x_k^{(i)}, w_k^{(i)}\}_{i=1}^N$ instead of a closed-form density. Each recursion step has three parts:

!!! info "Particle Filter"
	1. **Prediction.** Pass every posterior particle from step $k-1$ through the system model with an independently drawn process-noise sample:

	   $$x_k^{*(i)} = f\big(x_{k-1}^{(i)},\, w_{k-1}^{(i)}\big), \qquad w_{k-1}^{(i)} \sim p(w_{k-1})$$
	2. **Weighting.** Evaluate how likely each *prior* particle is given the new measurement $z_k$, and normalise:

	$$\tilde w_k^{(i)} = p\big(z_k \mid x_k^{*(i)}\big), \qquad w_k^{(i)} = \frac{\tilde w_k^{(i)}}{\sum_j \tilde w_k^{(j)}}$$
	3. **Resampling.** Draw $N$ new, *equally weighted* particles from the discrete distribution defined by $w_k^{(i)}$, so that particles with high weight are duplicated and particles with negligible weight are discarded. This combats the fact that after many steps almost all the probability mass would otherwise sit on a single particle (*degeneracy*).

The helper functions below implement the numerical building blocks we need before writing the main loop.

**Helper functions**

* **`wrap_to_pi`** maps an angular difference into $(-\pi,\pi]$. We need this whenever we compute an *error* between two angles — a raw subtraction like $6.2 - 0.1 = 6.1$ rad would hugely overstate an error that is really only about $0.18$ rad once you account for the $2\pi$ wrap-around.
* **`getPDF_PF`** turns a set of particle samples into a normalised histogram over a grid of $\theta$ values, purely so that we can visualise the evolving posterior density as a 3-D surface.
* **`resample`** implements the resampling step. We will use **systematic resampling**: we draw a *single* random offset $u_0\sim U\!\big(0,\tfrac1N\big)$ and place $N$ evenly spaced points $u_0, u_0+\tfrac1N, u_0+\tfrac2N,\dots$ along $[0,1)$, then we look each one up on the same cumulative-weight staircase (particle $i$ is selected with probability $w_k^{(i)}$).
"""

# ╔═╡ 7081956d-d929-45b0-b87c-b776dd7824db
begin
	function wrap_to_pi(angle)
	    return mod(angle + π, 2π) - π
	end

	function getPDF_PF(xp, tblx)
	    N = length(xp)
	    dx = tblx[2] - tblx[1]
	    ndata = length(tblx)
	    pdf = zeros(ndata)
	    area = 0.0
	
	    for i in 1:(ndata-1)
	        bin1 = tblx[i]
	        bin2 = tblx[i+1]
	
	        for j in 1:N
	            if bin1 <= xp[j] < bin2
	                pdf[i] += 1
	            end
	        end
	
	        area += pdf[i] * dx
	    end
	
	    pdf /= area
	
	    return pdf
	end

	function resample(w, oldParticle_state)
	    N = length(w)
	    cdf = cumsum(w)
	    # systematic resampling: O(N)
	    u0 = rand() / N
	    positions = u0 .+ (0:(N-1)) ./ N
	    idx = searchsortedfirst.(Ref(cdf), positions)
	    return oldParticle_state[:, idx]
	end
end

# ╔═╡ 16b57ff5-cbc6-4ac4-90ac-8bf4d95ffc04
md"""
### Initialising the particle set

We produce following initial state estimate:

$$\theta_1 \sim U(0,2\pi), \qquad \dot\theta_1 \sim \mathcal N(2.4,\ 0.4^2), \qquad \theta_1 \perp \dot\theta_1$$

Every particle starts with equal weight $1/N$. Try changing `μ_θ̇_init` / `σ_θ̇_init` (or the `2*pi*rand(...)` line for $\theta$) and re-running the notebook to see how a poorer initial guess affects the convergence speed of the filter.
"""

# ╔═╡ ce2b2348-97fc-4eeb-9a4a-8cb1294eb562
begin
	# Filter parameters
	Q = 10.0 # Process noise variance
	R_gauss = 0.02 # Measurement noise variance (Gaussian)
	numParticles = 1000 # Number of particles
	
	μ_θ̇_init = 2.4 # Initial mean of angular velocity particles
	σ_θ̇_init = 0.4 # Initial mean of angle particles
	
	# Initialize particles
	particle_w = zeros(numParticles, numSteps)
	particle_state = zeros(2, numParticles, numSteps)
	particle_w[:, 1] .= 1.0 / numParticles
	particle_state[:,:, 1] .= [2*pi*rand(1,numParticles);
	                             μ_θ̇_init .+ σ_θ̇_init * randn(1,numParticles)]
	particle_pos = funpos(particle_state[:,:,1])
end

# ╔═╡ 586a277c-81cb-4dab-aac1-93c24762f046
md"""
**Bookkeeping**

We pre-allocate arrays to store, at every time step: the point estimate `estState`, the absolute angular error `error`, and a grid `my_pdf` used later to visualise the posterior density surface.

Because $\theta$ wraps around $2\pi$, the point estimate of the angle is **not** the arithmetic mean of the particles' angles (imagine half the particles at $0.05$ rad and half at $6.23$ rad — their arithmetic mean is $\approx\pi$, which is nowhere near either cluster!). Instead we use the **circular mean**,
$$\hat\theta_k = \mathrm{mod}\Big(\operatorname{atan2}\big(\overline{\sin\theta^{(i)}},\ \overline{\cos\theta^{(i)}}\big),\ 2\pi\Big),$$
which correctly handles the wrap-around. This computation happens later, inside the main filter loop — here we just allocate the arrays and record the (still uniform, so not very meaningful) estimate at $k=1$.
"""

# ╔═╡ 740cb485-49ba-4b9c-955f-4f513bc26e64
begin
	# For the plots:
	theta = 0:0.01:2π
	estState = zeros(2, numSteps)
	error = zeros(numSteps)
	my_pdf = zeros(length(theta), numSteps)
	estState[:, 1] = mean(particle_state[:, :, 1], dims=2)[:]
	estPos = funpos(estState[:, 1])
	
	error[1] = abs(wrap_to_pi(estState[1, 1] - trueState[1, 1]))
end

# ╔═╡ 9bc6a36f-b51e-4f08-aabc-11fb26ca4374
"""
    options_pricing(S0, mu, sigma, T, n_steps, n_rep, CallOrPut, K)

Prices a European call or put option using Monte Carlo simulation of geometric Brownian motion.

# Arguments
- `S0`: Initial stock price.
- `mu`: Expected return (drift).
- `sigma`: Volatility of the stock.
- `T`: Time to maturity (in years).
- `n_steps`: Number of time steps in the simulation.
- `n_rep`: Number of simulation repetitions.
- `CallOrPut`: Option type, either `"Call"` or `"Put"`.
- `K`: Strike price of the option.

# Returns
- The estimated present value of the option.
"""
function options_pricing(S0, mu, sigma, T, n_steps, n_rep, CallOrPut, K)
    prices = mc_stock_price(S0, mu, sigma, T, n_steps, n_rep)
    S_T = prices[:, end]
    if CallOrPut == "Call"
        payoffs = max.(S_T .- K, 0)
    elseif CallOrPut == "Put"
        payoffs = max.(K .- S_T, 0)
    else
        error("CallOrPut must be either 'Call' or 'Put'")
    end
    discounted_payoff = exp(-r * T) * mean(payoffs)
    return discounted_payoff
end

# ╔═╡ c5bc1373-4a94-4791-af34-503ac9b7c88c
begin
	K = 110
	CallOrPut = "Call"
	
	p_mc = options_pricing(S0, mu, sigma, T, n_steps, n_rep, CallOrPut, K)
end

# ╔═╡ c7e33eda-d911-4693-afe7-149f4fedef8d
"""
    black_scholes_pricing(S0, mu, sigma, T, K, CallOrPut)

Prices a European call or put option using the Black-Scholes formula.

# Arguments
- `S0`: Initial stock price.
- `mu`: Expected return.
- `sigma`: Volatility of the stock.
- `T`: Time to maturity (in years).
- `K`: Strike price of the option.
- `CallOrPut`: Option type, either `"Call"` or `"Put"`.

# Returns
- The theoretical price of the option.
"""
function black_scholes_pricing(S0, mu, sigma, T, K, CallOrPut)
    d1 = (log(S0 / K) + (mu + 0.5 * sigma^2) * T) / (sigma * sqrt(T))
    d2 = d1 - sigma * sqrt(T)
    if CallOrPut == "Call"
        price = S0 * cdf(Normal(0, 1), d1) - K * exp(-mu * T) * cdf(Normal(0, 1), d2)
    elseif CallOrPut == "Put"
        price = K * exp(-mu * T) * cdf(Normal(0, 1), -d2) - S0 * cdf(Normal(0, 1), -d1)
    else
        error("CallOrPut must be either 'Call' or 'Put'")
    end
    return price
end

# ╔═╡ 07acef08-8996-4583-93d5-9381bd79684b
p_bs = black_scholes_pricing(S0, mu, sigma, T, K, CallOrPut)

# ╔═╡ 894b3d8c-4b4c-45d4-848e-d622780c153f
let
	# Make a comparison of Monte Carlo and Black-Scholes prices
	println("Monte Carlo Price: ", p_mc)
	println("Black-Scholes Price: ", p_bs)
end

# ╔═╡ 7c4e6239-5871-4d94-9e68-519ae2040c38
md"""
**Live preview of the initial particle cloud**

If `animation_enabled` is `true`, this draws the pendulum's circular track, the true rod-tip position, the (still uniformly-distributed) initial particle cloud, and the current point estimate. The same axes/handles are reused as a starting point when building the full animation at the end of the notebook.
"""

# ╔═╡ 81c2e36d-8414-4af7-9831-6a5054b198e2
begin
	if animation_enabled
	    fig1 = plot(size=(600,600), xlim=(-L-0.5, L+0.5), ylim=(-L-0.5, L+0.5), aspect_ratio=1, legend=false, title="Particle Filter Pendulum Simulation")
	    plot!(fig1, L.*cos.(theta), L.*sin.(theta), color=:lightgray, linewidth=1)
	    # wrap single-point coordinates in 1-element arrays so Plots treats them as series
	    fig_truePos = plot!(fig1, [truePos[1,1]], [truePos[2,1]], seriestype=:scatter, color=:black, markersize=6, label="True Position")
	    fig_partPos = plot!(particle_pos[1, :], particle_pos[2, :], seriestype=:scatter, color=:blue, markersize=2, alpha=0.3, label="Particles")
	    fig_estPos = plot!([estPos[1]], [estPos[2]], seriestype=:scatter, color=:red, markersize=4, label="Estimated Position")
	end
end

# ╔═╡ 662a2f36-066d-4a99-8492-562d8bffdd61
md"""
### Running the particle filter

!!! tip "Running the particle filter"
	For every time step $k=2,\dots$ and every particle $p=1,\dots,N$:
	
	1. **Predict** — propagate the particle through `funsys` with its own random process-noise draw $w\sim\mathcal N(0,Q)$.
	2. **Weight** — compute the residual $z_k - L|\sin\theta^{*(p)}_k|$ and turn it into a likelihood using *either* the Gaussian pdf *or* the quantisation indicator.
	
	After the particle loop: normalise the weights, resample, and finally record the circular-mean point estimate and its wrapped error against the ground truth.

**On bifurcation:** because $L|\sin\theta|$ is the same for $\theta$ and $\pi-\theta$ (and for their reflections through $2\pi$), a *single* Gaussian-noise measurement is generally consistent with **up to four** distinct angles. Whenever the true angle passes near $\theta=0,\pi/2,\pi,3\pi/2$ the particle cloud visibly splits ("bifurcates") into multiple clusters, each explaining the measurement equally well; the cloud collapses back onto a single mode only once the trajectory (through $\dot\theta$) makes the other modes physically implausible.

**On the quantisation resolution δ:** a coarser $\delta$ makes the likelihood indicator accept a *wider* band of $\theta$ values as consistent with each reading, so the posterior stays flatter/wider and less certain; a finer $\delta$ sharpens the posterior but also makes it easier for *every* particle to fall outside the (now very thin) accepted interval, risking degeneracy if $N$ is too small.
"""

# ╔═╡ e1550aac-b8cd-480c-8798-73d9e3b67dc5
begin
	# Filter
	for i = 2:numSteps
	    for p = 1:numParticles
	        # Prediction step
	        particle_state[:, p, i] = funsys(particle_state[:, p, i-1], sqrt(Q)*randn())
	
	        # Update step
	        residual = measurements[i] - L*abs(sin(particle_state[1, p, i]))
	        if gaussian_update_enabled
	            # Gaussian measurement likelihood, Eq. 4
	            particle_w[p, i] = pdf(Normal(0, sqrt(R_gauss)), residual)
	        else
	            # Quantisation measurement likelihood, Eq. 6
	            z_q = measurements[i]
	            Ls = L*abs(sin(particle_state[1, p, i]))
	            particle_w[p, i] = (Ls > z_q && Ls <= z_q + delta) ? 1.0 : 0.0
	        end
	    end
	    # Normalise weights (guard against total degeneracy: all weights zero)
	    if sum(particle_w[:, i]) > 0
	        particle_w[:, i] ./= sum(particle_w[:, i])
	    else
	        particle_w[:, i] .= 1.0/numParticles
	    end
	    # Resampling step (systematic resampling)
	    particle_state[:, :, i] = resample(particle_w[:, i], particle_state[:, :, i])
	    # Point estimate: circular mean for θ (handles 2π wrap-around), arithmetic mean for θ̇
	    estState[1, i] = mod(atan(mean(sin.(particle_state[1, :, i])), mean(cos.(particle_state[1, :, i]))), 2π)
	    estState[2, i] = mean(particle_state[2, :, i])
	    error[i] = abs(wrap_to_pi(estState[1, i] - trueState[1, i]))
	end
end

# ╔═╡ 7f8151ff-ab9e-4c7a-b1e7-a10f4348659e
md"""
**Posterior density grid**

To draw the 3-D "evolution of the posterior pdf" surfaces, we convert the particle cloud at *every* time step into a normalised histogram over a fixed $\theta$-grid using `getPDF_PF`. This is purely a post-processing / plotting step and is kept out of the main filtering loop above for clarity (and so the loop above focuses only on what the filter actually needs to run).
"""

# ╔═╡ 2354d2e5-23f8-4afd-8518-43e5972e570e
# Get the PDFs for all time steps
for i = 1:numSteps
    my_pdf[:, i] = getPDF_PF(particle_state[1, :, i], collect(theta))
end

# ╔═╡ 1a430aeb-50b1-45d4-9341-663b7c29db45
md"""
### Results — point estimates and error

The figure below reproduces the true and estimated angle, the true and estimated angular velocity, and the absolute (wrapped) estimation error over time. We wrap this in a small helper `plot_summary` so it can be reused later, once the EKF has also been run.
"""

# ╔═╡ 4b3ced3e-1368-433a-8c71-2bf75162cfc3
begin
	function plot_summary(; pf_state=nothing, pf_error=nothing, ekf_state=nothing, ekf_error=nothing)
	    p1 = plot(t, trueState[1, :], label="True", color=:black, linewidth=2, ylabel="Angle (rad)")
	    pf_state  !== nothing && plot!(p1, t, pf_state[1, :],  label="PF",  color=:blue)
	    ekf_state !== nothing && plot!(p1, t, ekf_state[1, :], label="EKF", color=:red)
	
	    p2 = plot(t, trueState[2, :], label="True", color=:black, linewidth=2, ylabel="Angular Velocity (rad/s)")
	    pf_state  !== nothing && plot!(p2, t, pf_state[2, :],  label="PF",  color=:blue)
	    ekf_state !== nothing && plot!(p2, t, ekf_state[2, :], label="EKF", color=:red)
	
	    p3 = plot(xlabel="Time (s)", ylabel="|Estimation Error| (rad)")
	    pf_error  !== nothing && plot!(p3, t, pf_error,  label="PF",  color=:blue)
	    ekf_error !== nothing && plot!(p3, t, ekf_error, label="EKF", color=:red)
	
	    plot(p1, p2, p3, layout=(3,1), size=(800,900))
	end
	
	plot_summary(pf_state=estState, pf_error=error)
end

# ╔═╡ c52a83cf-654a-45e5-97b8-bada2843e3fb
md"""
### Results — evolution of the posterior density

This 3-D surface shows the full particle-based posterior $p(\theta_k \mid Z_k)$ over time (not just its mean), with the true angle trajectory overlaid in red. This is the key strength of the particle filter: unlike a Kalman filter, which can only ever report a mean and covariance, the particle filter retains the *entire shape* of the (possibly multi-modal) posterior — you can literally see it bifurcate and re-converge. Try lowering `numParticles` to see what happens when you use too few parameters.
"""

# ╔═╡ e49765f4-c393-447a-a7ef-a94f7cb5fcea
begin
	function plot_pdf_surface(pdf_grid, theta_true; ptitle="Posterior pdf of angle")
	    zmax = maximum(pdf_grid)
	    zmax = (isnan(zmax) || zmax == 0.0) ? 1.0 : zmax
	    
	    # 1. Render the 3D surface
	    plt = surface(t, theta, pdf_grid, xlabel="Time [s]", ylabel="Angle θ [rad]",
	                  zlabel="Probability density", title=ptitle, size=(800,600), colormap = :jet)
	    
	    # 2. Overlay the true angle trajectory in 3D
	    # Offset z slightly above zmax so the line isn't hidden inside/under the surface
	    z_line = fill(zmax * 1.05, length(t)) 
	    plot!(plt, t, theta_true, z_line, label="True angle", color=:red, linewidth=3)
	
	    xlims!(plt, (minimum(t), maximum(t)))
	    ylims!(plt, (minimum(theta), maximum(theta)))
	    zlims!(plt, (0.1, zmax * 1.1))
	    
	    return plt
	end
	
	# Call the updated function passing your true angle trajectory
	plot_pdf_surface(my_pdf, trueState[1, :], ptitle="Particle filter — posterior pdf of angle")
end

# ╔═╡ 82ffa121-d52a-4a78-b0b1-c37f9bbc35ef
md"""
### Animation

`plot_setup(i)` draws a single animation frame at time step `i`: the circular track the rod tip moves along, the true position, the current particle cloud (each particle's rod-tip position), and the point estimate. Running the next two cells repeatedly steps through the frames one at a time inside the notebook; the final cell renders and saves the *whole* animation as a GIF.
"""

# ╔═╡ b4f70804-b0ec-41a9-99a2-3660ee0735cc
function plot_setup(step_number)
    i = step_number
    plt = plot(size=(600,600), xlim=(-L-0.5, L+0.5), ylim=(-L-0.5, L+0.5), aspect_ratio=1, legend=false, title="Particle Filter Pendulum Simulation - Step $i")
    plot!(plt, L.*cos.(theta), L.*sin.(theta), color=:lightgray, linewidth=1)
    plot!(plt, [0, truePos[1,i]], [0, truePos[2,i]], linestyle=:dash, color=:black, lw=1, label="True Position")

    # get particle positions and ensure 1D vectors for plotting
    ps = particle_state[:, :, i]                     # 2 x numParticles
    particle_pos = funpos(ps)                        # 2 x numParticles
    xpart = vec(particle_pos[1, :])
    ypart = vec(particle_pos[2, :])
    scatter!(plt, xpart, ypart, markersize=2, color=:red, alpha=1.0, markerstrokecolor=:red, markerstrokewidth=0, label="Particles")

    estPos = funpos(reshape(estState[:, i], 2, 1))   # 2 x 1
    plot!(plt, [estPos[1]], [estPos[2]], seriestype=:scatter, color=:red, markersize=4, label="Estimated Position")

    return plt
end

# ╔═╡ 901ede82-9269-4263-99b2-609a3b6e3d12
md"""
Use the slider to change the simulation step.
"""

# ╔═╡ fe84a44c-ce0a-4c8d-866a-4dfd1c90af59
@bind ix Slider(1:200, default=0, show_value=true)

# ╔═╡ 27fc9dc6-7d2d-4554-a9c1-cda45bc70c37
plot_setup(ix)

# ╔═╡ 38e03857-7fb9-4172-95d4-9547001f8001
md"""
### Extra - Comparison with an Extended Kalman Filter

The EKF applies the ordinary Kalman filter recursions to a **linearisation** of the (non-linear) system and measurement models around the current state estimate:

* **Process Jacobian**, obtained by differentiating the dynamics model w.r.t. $x=[\theta,\dot\theta]$ at $w=0$:

  $$F(x) = \begin{bmatrix}1+\dfrac{\Delta t^2}{2L}g\sin\theta & \Delta t \\[4pt] \dfrac{\Delta t}{L}g\sin\theta & 1\end{bmatrix}$$

* **Measurement Jacobian**: differentiate $h(\theta)=L|\sin\theta|$ w.r.t. $\theta$:
$$H(x) = \begin{bmatrix}\dfrac{\partial h}{\partial \theta} & 0\end{bmatrix} = \begin{bmatrix}L\cos\theta\cdot\mathrm{sign}(\sin\theta) & 0\end{bmatrix}$$

(the $\mathrm{sign}(\sin\theta)$ term appears because of the absolute value; strictly speaking $|\sin\theta|$ is non-differentiable exactly at $\theta = 0,\pi$, so this is a *subgradient* there).

We then run the standard predict/update EKF recursion:

$$P_k^- = F P_{k-1} F^T + G Q G^T, \qquad K = P_k^- H^T (H P_k^- H^T + R)^{-1}, \qquad \hat x_k = \hat x_k^- + K\big(z_k - h(\hat x_k^-)\big), \qquad P_k = (I-KH)P_k^-$$

reusing the **same** measurement stream (`measurements`) and the **same** assumed noise variance `R_gauss` that the particle filter used for its Gaussian likelihood — even when `gaussian_update_enabled = false` and the sensor is actually the quantised one.
"""

# ╔═╡ 55e2d76d-d5cb-40af-b74b-aa9bfc72acc9
begin
	# Process Jacobian, F
	proc_jacobian(x) = [1 + dt^2/(2*L)*g*sin(x[1])   dt;
	                     dt*g/L*sin(x[1])              1.0]
	
	# Measurement Jacobian, H = ∂(L|sinθ|)/∂θ
	meas_jacobian(x) = [L*cos(x[1])*sign(sin(x[1]))   0.0]
	
	function run_ekf(measurements, trueState)
	    # Initialise
	    x = [π; μ_θ̇_init]
	    P = [π^2 0.0; 0.0 σ_θ̇_init^2]
	
	    estState_EKF = zeros(2, numSteps)
	    error_EKF = zeros(numSteps)
	    pdf_EKF = zeros(length(theta), numSteps)
	    estState_EKF[:, 1] = x
	    error_EKF[1] = abs(wrap_to_pi(estState_EKF[1, 1] - trueState[1, 1]))
	
	    for i in 2:numSteps
	        # --- Prediction (noise-free propagation of the mean, then linearise about it) ---
	        x = funsys(x, 0.0)
	        F = proc_jacobian(x)
	        G = [dt^2/2; dt] ./ L
	        P = F*P*F' + G*Q*G'
	
	        # --- Update ---
	        residual = measurements[i] - L*abs(sin(x[1]))
	        H = meas_jacobian(x)
	        S = (H*P*H')[1, 1] + R_gauss
	        K = vec(P*H') ./ S
	        x = x .+ K .* residual
	        x[1] = mod(x[1], 2π)
	        P = (I - K*H)*P
	
	        # --- Save for plotting ---
	        estState_EKF[:, i] = x
	        error_EKF[i] = abs(wrap_to_pi(estState_EKF[1, i] - trueState[1, i]))
	        pdf_EKF[:, i] = pdf.(Normal(x[1], sqrt(max(P[1,1], 1e-9))), theta)
	    end
	
	    return estState_EKF, error_EKF, pdf_EKF
	end
	
	if comparison_EKF
	    estState_EKF, error_EKF, pdf_EKF = run_ekf(measurements, trueState)
	end
end

# ╔═╡ d1cf17d1-5b91-416b-9a5c-8d33439a0b1f
if comparison_EKF
    plot_summary(pf_state=estState, pf_error=error, ekf_state=estState_EKF, ekf_error=error_EKF)
end

# ╔═╡ a7880826-836d-4a0b-a872-4fcf7c52edbc
if comparison_EKF
    plot_pdf_surface(pdf_EKF, trueState[1, :], ptitle="EKF — posterior pdf of angle (Gaussian approximation)")
end

# ╔═╡ 6441e9aa-a25c-4485-b939-bfa87d3a7194
md"""
!!! danger "Difficulties arising in the EKF"

	Running the two filters side-by-side highlights exactly the limitations the introduction warned about:
	
	* **Single-Gaussian bottleneck.** The EKF's posterior is *always* one Gaussian bump (see the smooth, unimodal EKF surface above versus the particle filter's bifurcating one). When the measurement is briefly consistent with several angles at once, the EKF cannot represent that ambiguity — it just picks one linearisation and commits to it, which can lock onto the *wrong* mode.
	* **No wrap-around.** $\theta$ genuinely lives on a circle, but the EKF's state and covariance live in $\mathbb R^2$; we patch the mean with `mod(·, 2π)` after every update, but the covariance itself has no concept of wrap-around, so uncertainty near the $0/2\pi$ boundary is not modelled correctly.
	* **Vanishing/near-singular Jacobian.** $H(x) = L\cos\theta\cdot\mathrm{sign}(\sin\theta)$ is exactly (or near) zero whenever $\theta$ is close to $0,\ \pi/2,\ \pi,\ 3\pi/2$ — precisely the points where $|\sin\theta|$ has a maximum or minimum. Right there the linearised measurement becomes locally *uninformative* (a small change in $\theta$ barely changes $h(\theta)$), so the EKF's Kalman gain shrinks and it temporarily stops correcting its estimate — visible as flat stretches in the EKF error plot.
	* **Model mismatch under quantisation.** When `gaussian_update_enabled = false`, the true measurement likelihood is a *uniform* distribution over a bin, not Gaussian at all — yet the EKF still assumes Gaussian noise with variance `R_gauss`. This is an approximation baked into the comparison and is itself a source of extra EKF error.

None of these are fundamental obstacles for the particle filter, which is precisely the point of the exercise.
"""

# ╔═╡ ac843054-1734-4f1d-b4a6-e764598cb975
md"""
### Conclusion

**Strengths of the particle filter**, demonstrated above:

* No linear/Gaussian assumption — it handled the non-linear $L|\sin\theta|$ measurement and the $2\pi$ wrap-around without any special-casing.
* It gives the *complete* posterior shape, not just a mean and covariance — essential here since the posterior is frequently multi-modal.
* It was very easy to code: only a system-model function and a likelihood function were needed, no Jacobians, no matrix inversions.
* It never needed to invert the measurement function $h$ (which is not even invertible: many $\theta$ map to the same projection) — the EKF, by contrast, degrades exactly where $h$ is least invertible.
* It can accommodate hard constraints (e.g. the $\mathrm{mod}\,2\pi$ wrap, or the quantisation sensor's all-or-nothing likelihood) directly in the model.

**Challenges**, also demonstrated above:

* *Degeneracy*: with too few particles (try shrinking `numParticles`), most of the weight can collapse onto very few samples after resampling, and the true mode can be lost entirely between steps.
* Representing a genuinely high-dimensional or very peaked posterior can require a very large $N$, which is computationally expensive — the reason more advanced particle filters (e.g. with smarter proposal distributions) exist.
* Cheaper linear-Gaussian filters like the EKF remain attractive when their assumptions approximately hold — the trade-off is accuracy and robustness (particle filter) versus computational cost and simplicity (EKF).
"""

# ╔═╡ a0139976-10d5-4525-aa42-ae6103dbb362
md"""
## Estimating ``\pi``

During the lectures you saw this statement:

!!! info
	Another way of estimating $\pi$ is dropping point in a square, and analyse the number of points that fall within the inscribed circle.

!!! tip
	You can implement this very easily.
	1. Run the MC simulation.
	2. Make a figure representing your simulation.
	3. Show the result.

"""

# ╔═╡ Cell order:
# ╟─ce6d0508-8283-11f0-2bcb-9b53de934eb4
# ╟─bb35ea5b-7629-4831-9c21-0658d0979cee
# ╠═5493a468-0c7a-4d63-bb0e-1adbf8d408ce
# ╟─763fcc5e-94c5-4406-922e-3393b2f7b8c3
# ╟─fc76551d-d553-4c69-a3e2-81b599671e80
# ╟─260fb4a7-9ee3-4344-abe6-0301c4864f6c
# ╟─dba762fa-2296-44fa-86d3-b7b8a187ee4d
# ╟─ccaab93e-f9cf-4901-b247-4ae7f42c5e5f
# ╠═332c5503-5337-4f9f-942e-f1abe4746090
# ╠═2add76c6-5a92-41f2-8fe2-4f6a2c030753
# ╠═9bc6a36f-b51e-4f08-aabc-11fb26ca4374
# ╟─4c624322-5a1d-4ebd-ba6c-f2f83284093b
# ╠═c5bc1373-4a94-4791-af34-503ac9b7c88c
# ╟─9a85c43a-4d88-48e3-b569-a13e410375e8
# ╠═c7e33eda-d911-4693-afe7-149f4fedef8d
# ╠═07acef08-8996-4583-93d5-9381bd79684b
# ╠═894b3d8c-4b4c-45d4-848e-d622780c153f
# ╟─8f1f9d83-bc20-43b6-adbc-cdc58cefd33a
# ╟─e95fb99e-d4a6-4115-bb0e-b744f2de34ef
# ╠═2354a6e7-f0b5-4c16-a8ce-d6537dd3a013
# ╟─ee99ed21-05bd-4136-a490-e298298ee831
# ╟─c33b6c5a-d838-4ad7-b9e2-e145bf66c2b4
# ╟─5b617b5d-723a-4292-90be-71dc34284801
# ╠═4329f67a-861a-4893-a9c3-ca3c7a99e04b
# ╠═e26aa995-3355-4664-96b7-efd6b0b206a5
# ╟─7bf3a052-c1bc-46b3-8e6a-0185afe6df74
# ╠═10ede4a2-1703-4c27-801d-c7502a88997d
# ╠═20856d2f-b26e-4c7e-a283-8dbb53af7b9c
# ╠═9cedbe14-a962-46fd-b271-e6ca78930e38
# ╟─73f63ce0-82a4-4eb8-8809-de240e2675bc
# ╟─14266c3f-9111-41d5-8e5b-2bc0073c7ce6
# ╟─1b9f8e83-24e2-40c9-abef-f9d3dd8701e7
# ╟─9e43da0a-eab5-4cf2-8dee-2d8f92788ed6
# ╠═5665f7b4-e7e8-4d0e-bba3-dabce34a6d77
# ╟─4ccceb6d-8d2c-4f21-8bd7-124b0f67c2cf
# ╠═a93db58d-14d1-4350-a73a-19e909427e4e
# ╟─ae081a80-322b-4207-9676-4cb2f3f05b3a
# ╠═711c2db9-8b28-425a-8b19-fc3cf3fb4bbb
# ╟─4ade7deb-f3cd-4e54-a7d1-cb8580d37aec
# ╠═324f6b86-81c0-469f-ac1e-de8fcc0b2b39
# ╟─8aee80e0-da25-4438-9ca5-1803d725385b
# ╠═7c1e3a47-0614-40d8-9274-e5d583054a48
# ╠═31b39d05-147b-4b46-97b4-f10d57299e0f
# ╠═7081956d-d929-45b0-b87c-b776dd7824db
# ╟─16b57ff5-cbc6-4ac4-90ac-8bf4d95ffc04
# ╠═ce2b2348-97fc-4eeb-9a4a-8cb1294eb562
# ╟─586a277c-81cb-4dab-aac1-93c24762f046
# ╠═740cb485-49ba-4b9c-955f-4f513bc26e64
# ╟─7c4e6239-5871-4d94-9e68-519ae2040c38
# ╠═81c2e36d-8414-4af7-9831-6a5054b198e2
# ╟─662a2f36-066d-4a99-8492-562d8bffdd61
# ╠═e1550aac-b8cd-480c-8798-73d9e3b67dc5
# ╟─7f8151ff-ab9e-4c7a-b1e7-a10f4348659e
# ╠═2354d2e5-23f8-4afd-8518-43e5972e570e
# ╟─1a430aeb-50b1-45d4-9341-663b7c29db45
# ╠═4b3ced3e-1368-433a-8c71-2bf75162cfc3
# ╟─c52a83cf-654a-45e5-97b8-bada2843e3fb
# ╠═e49765f4-c393-447a-a7ef-a94f7cb5fcea
# ╟─82ffa121-d52a-4a78-b0b1-c37f9bbc35ef
# ╠═b4f70804-b0ec-41a9-99a2-3660ee0735cc
# ╟─901ede82-9269-4263-99b2-609a3b6e3d12
# ╟─fe84a44c-ce0a-4c8d-866a-4dfd1c90af59
# ╠═27fc9dc6-7d2d-4554-a9c1-cda45bc70c37
# ╟─38e03857-7fb9-4172-95d4-9547001f8001
# ╠═55e2d76d-d5cb-40af-b74b-aa9bfc72acc9
# ╠═d1cf17d1-5b91-416b-9a5c-8d33439a0b1f
# ╠═a7880826-836d-4a0b-a872-4fcf7c52edbc
# ╟─6441e9aa-a25c-4485-b939-bfa87d3a7194
# ╟─ac843054-1734-4f1d-b4a6-e764598cb975
# ╠═a0139976-10d5-4525-aa42-ae6103dbb362
