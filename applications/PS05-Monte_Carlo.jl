### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

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

# ╔═╡ 07acef08-8996-4583-93d5-9381bd79684b
p_bs = black_scholes_pricing(S0, mu, sigma, T, K, CallOrPut)

# ╔═╡ 894b3d8c-4b4c-45d4-848e-d622780c153f
let
	# Make a comparison of Monte Carlo and Black-Scholes prices
	println("Monte Carlo Price: ", p_mc)
	println("Black-Scholes Price: ", p_bs)
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
	
	    #alpha_dist = Uniform(-pi/2, pi/2)
	    #tan_bijection = Bijectors.BijectorFunction(x -> tan(x), y -> atan(y))
	
	    #tan_alpha_dist = transformed(alpha_dist, tan_bijection)
	
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
	p2 = histogram(samples_theta1, bins=nbins, title="Posterior of θ1", xlabel="θ1", ylabel="Density", legend=false, normalize=:pdf)
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
# ╟─a0139976-10d5-4525-aa42-ae6103dbb362
