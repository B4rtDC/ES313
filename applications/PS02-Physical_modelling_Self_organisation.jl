### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ dab1dfbe-5e52-11f0-05a0-df522fb51dd7
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

# ╔═╡ cdecef07-e0f9-4372-b1c0-d284d763bb83
# Dependencies
begin
	using NativeSVG # SVG plotting library
	using Plots    # for random related activities
	using Printf   # for fancy text rendering
	using FileIO
	using ImageMagick
	using Graphs
	using SimpleWeightedGraphs
	using GraphPlot
	using Random
	using LinearAlgebra
	using Statistics
	using Distributions
end

# ╔═╡ a94f7808-4801-45a7-a612-d44282258303
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

# ╔═╡ be2db4dd-9ace-4985-8414-65124e48e7d3
md"""
# Image Segmentation with Cellular Automata

In the lecture notes on physical modelling and self-organisation, a variety of subjects have been extensively covered to introduce you to the possibilities of cellular automata.

In this application, we will apply a CA to a very specific task in image segmentation.

Authors from the University of Guadalajara wrote an article on this application, which can be found at the following link: [Image Segmentation with Cellular Automata](https://www.sciencedirect.com/science/article/pii/S2405844024071834)

Image segmentation is a computer vision technique aimed at dividing an image into distinct and meaningful regions based on similar visual characteristics. The process of image segmentation is often hindered by noise and other undesirable artifacts.

The authors propose a new segmentation approach based on the CA model.

!!! tip "CA segmentation approach"
    The approach consists of 3 phases:
    1. Eliminate noise in a 3×3 grid.
    2. Eliminate noise in a 5×5 grid.
    3. Assign each element a state chosen from a set of predefined states.

The referenced paper clearly showcases the segmentation capabilities of the model. Yet, you might still ask yourself: *So what?*

One very relevant application can be found in the preprocessing of star images onboard spacecraft. The most accurate way for a satellite to determine its attitude (i.e. orientation) is by using star trackers. These are small optical sensors mounted on the satellite platform. Typically three units are used. Their primary purpose is the detection of star patterns, which assume fixed positions in an ICRF (International Celestial Reference Frame). By matching the perceived image to the known positions of these stars, the attitude of the spacecraft can be determined with arcsecond precision.

The entire pipeline from an image to the final attitude solution is a complex process. Therefore, we will focus only on the first step: segmenting the image and reducing noise levels.
"""

# ╔═╡ 8a7b7b90-bc6e-4cbf-bd66-a000acb56a92
md"""
## Loading the image
In a first step we will load the image (from within the repository) to Pluto. As we are not interested in the color components, we will transform the image to a grayscale and then to a matrix of floats.
"""

# ╔═╡ 8d5d3300-4cad-4adc-b865-1631a20a9ed6
begin
	star_image = load("./applications/img/star_image.png")
	(height, width) = size(star_image)
	plot(star_image, title="Star Image", size=(width,height), aspect_ratio=:equal)
end

# ╔═╡ 98417593-413e-465c-b46b-99e287fc24d4
begin
	star_image_gray = Gray.(star_image)
	star_image_array = Float64.(Array(star_image_gray))
end

# ╔═╡ 7f090510-017b-4f42-b3fa-43c67119f6b5
md"""
## Encoding the rules

Go over the referenced paper and extract the rules of the CA. You should perceive the pixel intensity as the physical phenomenon we are studying. 
!!! warning "Pixel Scale"
	For the sake of consistency, rescale the pixel intensities to have a value between 0 and 255.

### Rule 1

|    |    |    |
|----|----|----|
| $x_1$ | $x_2$ | $x_3$ |
| $x_4$ | $x_0$ | $x_5$ |
| $x_6$ | $x_7$ | $x_8$ |

We first introduce the helper function as follows:

``C(a, b) = \begin{cases} 1   & \text{if } a < b \\ -1  & \text{if } a > b \\ 0   & \text{if } a = b \\ \end{cases}``

This is then used to determine following value in the vicinity of the point ``x_0``, where ``k`` indicates the number of the iteration:


``M_{3 \times 3}(x_0) = \operatorname{sign} \left( \sum_{i=1}^8 C(x_0, x_i) \right)``

The value of ``M_{3 \times 3}(x_0)`` is then used to apply a simple rule:

``\begin{aligned} R_1: & \quad \text{If } M_{3 \times 3}(x_0) = 1 \quad \text{then}  \quad x_0(k+1) = x_0(k) + 1 \\ R_2: & \quad \text{If } M_{3 \times 3}(x_0) = -1 \quad \text{then} \quad x_0(k+1) = x_0(k) - 1 \\ R_3: & \quad \text{If } M_{3 \times 3}(x_0) = 0 \quad \text{then} \quad x_0(k+1) = x_0(k) \end{aligned}``

This step is applied *iter1* times.

### Rule 2

|       |       |       |       |        |
|-------|-------|-------|-------|--------|
| $x_1$ | $x_2$ | $x_3$ | $x_4$ | $x_5$  |
| $x_6$ | $x_7$ | $x_8$ | $x_9$ | $x_{10}$ |
| $x_{11}$ | $x_{12}$ | $\mathbf{x_0}$ | $x_{13}$ | $x_{14}$ |
| $x_{15}$ | $x_{16}$ | $x_{17}$ | $x_{18}$ | $x_{19}$ |
| $x_{20}$ | $x_{21}$ | $x_{22}$ | $x_{23}$ | $x_{24}$ |

Rule 2 is similar to rule 1, yet the size of the neighborhood around the cell is increased:

``M_{5\times 5}(x_0) = \operatorname{sign} \left( \sum_{i=1}^{24} C(x_0, x_i) \right)``

This step is applied *iter2* times.

### Rule 3

In a last step, the elements of the CA undergo a process that results in the identification of regions or objects characterized by homogeneous intensities and clearly defined edges. Each element is assigned a final state. This is achieved through the division of the range of intensity levels or states into a smaller number of segments. The amount of segments can be chosen manually. We will call this value ``n``.

``x_0(k+1) = \text{round}\left(\frac{x_0(k)}{n}\right)``

"""

# ╔═╡ 7c680a64-e34a-46a2-ba09-26c415eeb57e
md"""
!!! tip "Assignment"
	- Write the functions necessary to apply stages 1, 2 and 3 of the cellular automaton.
	- Apply this segmentation to the provided image.
	- Compare the original image to the segmented image. What do you see? How do the parameters *iter1*, *iter2* and ``n`` impact your result?
	- What are the (dis)advantages of the approach cfr. the referenced paper?
"""

# ╔═╡ 99430b49-895c-4b88-8433-f5b6fd885b8e
md"""
# Forest Fires

The forest fire model is probably the most illustrative model of self-criticality.

## Model Summary

The forest-fire model simulates a square grid where each site represents a patch of land. Over time:
- Trees **grow** in empty sites.
- **Lightning** randomly strikes and sets trees on fire.
- Fires **spread** to neighboring trees.
- Burnt trees become **empty**.

Over many steps, this process self-organizes — producing **fire size distributions** that follow a power law.

!!! info "Cell States"
	Each site can be in one of three states:
	- `0`: Empty
	- `1`: Tree
	- `2`: Burning

!!! info "Model Parameters"
	* `G` (`g x g`): The size of the grid.
	* `f_s`: The sparking frequency.
	* `N_s`: The number of steps to run the simulation.
	* `N_f`: The number of fires with area (see infra).
	* `A_f`: The area of each fire. (I.e. the amount of trees consumed per fire).

!!! info "Model Rules"
	1. **Tree Growth**: At each and every timestep, a tree is 'dropped' on a randomly selected site. If it is unoccupied, the tree is planted.
	2. **Lightning Strike**: 
	   With sparking frequency `f_s`, a random site is struck:
	   - If it holds a tree, it catches fire.
	   - The fire spreads to **4-connected neighbors** (up/down/left/right).
	The sparking frequency can also be seen as the inverse number of random tree drops before a lightning strikes.
	3. **Burning Update**:  
	   All burning trees (`2`) become **empty** (`0`) in the next time step.
	4. **Repeat** for many steps.

For large time intervals, the number of trees lost in ‘fires’ is approximately equal to the number of trees planted. However, the number of trees on the grid will fluctuate. The frequency–area distribution of ‘fires’ is a statistical measure of the behaviour of the system. This model is probabilistic (stochastic) in that the sites are chosen randomly. It is a cellular-automata model in that only nearest-neighbour trees are ignited by a ‘burning’ tree. In terms of the definition of self-organized critical behaviour, the steady-state input is the continuous planting of trees. The avalanches in which trees are lost are the ‘forest fires’. A measure of
the state of the system is the fraction of sites occupied by trees. This ‘density’ fluctuates about a ‘quasi-equilibrium’ value.

!!! tip "Assignment"
	Find a method to implement the forest fire phenomenon.
	* Make sure to visualise the evolution of your forest.
	* Make a function of `N_f/N_s` as a function of `A_f` with:
		* `G` = (128,128)
		* `1/f_s` = [125, 500, 2000]
		* `N_s` = 1e8
	  Represent the figure on a logarithmic axis.
	* What are the advantages and shortcomings of your implementation?
	* What could you alter to the model to make it more realistic?
"""

# ╔═╡ Cell order:
# ╟─a94f7808-4801-45a7-a612-d44282258303
# ╟─dab1dfbe-5e52-11f0-05a0-df522fb51dd7
# ╠═cdecef07-e0f9-4372-b1c0-d284d763bb83
# ╟─be2db4dd-9ace-4985-8414-65124e48e7d3
# ╟─8a7b7b90-bc6e-4cbf-bd66-a000acb56a92
# ╠═8d5d3300-4cad-4adc-b865-1631a20a9ed6
# ╠═98417593-413e-465c-b46b-99e287fc24d4
# ╟─7f090510-017b-4f42-b3fa-43c67119f6b5
# ╟─7c680a64-e34a-46a2-ba09-26c415eeb57e
# ╟─99430b49-895c-4b88-8433-f5b6fd885b8e
