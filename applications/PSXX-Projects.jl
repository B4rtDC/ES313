### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ a795cad3-33a6-4664-a4b4-52b083ed4308
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
	using PlutoUI
	PlutoUI.TableOfContents(depth=2)
end

# ╔═╡ fc0426fc-d2b6-4751-9c48-ecf31a7b5a3b
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

# ╔═╡ abd51e4f-6e18-461a-9882-a79a405bc1e2
md"""
# General introduction

## Overview
For this assignment, you’ll select a project to design and develop a model based on one of the provided themes. Each project is outlined in a generic manner, allowing you the flexibility to define the specific focus and scope. Background resources are provided to inspire your approach, though they often extend beyond the level of detail expected here.

!!! info "Key Requirements"

	1. **Problem definition**: Clearly define the context or problem you will study. This should include the problem's practical relevance and any relevant parameters.
	2. **Desired outcome**: Specify what you aim to quantify or measure. This should be an achievable outcome for the model to generate results that inform your understanding of the problem.
	3. **Model construction**: Describe your model’s structure, parameters, and constraints. Discuss any limitations, simplifications, or hypotheses you've accepted in order to make the problem manageable.
	4. **Model analysis**: Carry out a thorough analysis of your model. This may include:
	   - Comparative studies (e.g., comparing with established results or similar models)
	   - Sensitivity analyses to understand how changes in parameters affect results
	   - Optimization of key parameters, if applicable
	5. **Conclusion and Discussion**: Summarize your findings. Reflect on the model's performance, the reliability of its outcomes, and the limitations of your approach.

### Project presentation and evaluation

!!! info "Oral presentation (30 minutes)"
	You will present your project, highlighting key aspects without going into extensive code details. However, you should cover:
	- **Essential Data Structures and Algorithms**: Explain the choice and role of key elements.
	- **Model Demonstrations**: Share minimum working examples that showcase model functionality and performance.
	- **Codebase Submission**: Provide your full codebase, as it will be part of the evaluation.

!!! info "Grading criteria"
	Your project will be assessed on:
	- **Conceptual Approach**: The originality and clarity of your approach to the problem.
	- **Modeling and Analysis**: The soundness and depth of your modeling and analysis methods.
	- **Model Exploitation**: The quality of results derived from your model and any optimizations or insights you provide.
	- **Conclusions**: The robustness of your conclusions based on the analysis.

Approach each stage with both creativity and rigor!

### Suggested References for Inspiration
* [Mathematical Modeling and Simulation of Systems](https://link.springer.com/book/10.1007/978-3-031-30251-0)
* [Modeling and Simulation - An Application-Oriented Introduction](https://link.springer.com/book/10.1007/978-3-642-39524-6)
* [Modeling and Simulation in Engineering](https://www.mdpi.com/books/book/6451-modeling-and-simulation-in-engineering)
* [Engineering Principles of Combat Modeling and Distributed Simulation](https://www.wiley.com/en-us/Engineering+Principles+of+Combat+Modeling+and+Distributed+Simulation-p-9781118180310)
* [Introduction to Transportation Analysis, Modeling and Simulation - Computational Foundations and Multimodal Applications](https://link.springer.com/book/10.1007/978-1-4471-5637-6)

"""

# ╔═╡ 07965656-a4fe-449c-898b-2fed7e755c42
md"""
# 2025 Project Ideas
## Simulation-based improvement of medical examination throughput
This project aims to model and simulate the medical examination pathway for SAO/DOO candidates to improve efficiency. 
The current system, using predefined groups and schedules, reportedly experiences variable loads leading to both idle time and congestion. 
Students will collect operational data, build and validate a simulation model, and experiment with alternative process configurations 
(e.g., scheduling logic, group sizes) to propose evidence-based recommendations for reducing bottlenecks and improving overall throughput.
This project will be conducted in collaboration with the staff of MHQA.

## Environmental Impact of Renewable Energy Adoption

The focus is on understanding how the increased integration of renewable energy sources like solar and wind into an existing electricity grid affects environmental outcomes, particularly CO2 emissions, grid stability, and energy reliability. Key parameters include renewable energy penetration rate, energy demand profiles, storage capacity, and variability in renewable generation.

(Suggested) outcome:
* The reduction in overall CO2 emissions as renewable share increases.
* Impacts on grid stability metrics such as supply-demand balance and frequency of power shortages.
* The levels of energy storage capacity needed to maintain grid reliability.
* Trade-offs between environmental benefits and operational challenges.

(Suggested) model:
* A discrete-time simulation model of the electricity grid (with a lot of simplifications).
* Components:
  * Power generation units.
  * Energy storage (batteries)
  * Demand profile.
* Parameters:
  * Penetration level of renewables.
  * Capacity and efficiency of storage.
  * Variability patterns of renewables.
* Constraints and simplifications:
  * The grid is assumed balanced if supply meets demand in each timestep.
  * Transmission losses and market dynamics are simplified or omitted.
  * Storage is modeled with generic efficiency and capacity limits.

You can perform a *sensitivity analysis* on your model and perform comparative studies.

## Water resource management

You will have noticed that last summer, there were (again) talks about water shortages, whereas last year (2024) it hardly ever stopped raining and the ground became oversaturated. It seems like Belgium has some difficulties when it comes to water management and retaining water. Investigate whether you are able to model this phenomenon with the information that is publically available and suggest a mitigation strategy. Focus primarily on the so-called *quick wins*.

## Smart Energy Management

There are increasing advancements in the field of efficient energy management and resource optimization. For example, the goal is to use solar energy at the times it is produced and when energy prices (under a variable pricing contract) are at their lowest. Develop a simulation framework that allows you to model various home energy components, such as solar panels, home batteries, a bidirectional electric vehicle, and major appliances (e.g., air conditioning, washing machine, oven, etc.). Your objective is to design an optimal system that minimizes energy costs while maximizing overall home energy efficiency.

## Teaching Schedule Optimization

This challenge recurs every academic year: designing a course schedule that accommodates the availability of all involved personnel, including teaching staff, military instructors, PTI staff, and others. The goal is to produce a timetable that avoids conflicts and overlaps while maximizing efficiency, minimizing unwanted gaps between sessions, grouping consecutive blocks of lectures (N) and exercises (F) on the same day where possible, and respecting individual constraints. Develop an optimization model that takes as input the availability schedules of all personnel and outputs a conflict-free, efficient course timetable. The model should be user-friendly, with straightforward input requirements and easy-to-interpret scheduling results.
"""

# ╔═╡ 69a9e78f-1150-4914-9772-d8feedd13fd0
md"""
# 2024 Project Ideas

## Wargaming
Wargaming is a tool for analyzing strategic decision-making in conflict scenarios. By digitizing a wargame model, we can run rapid simulations and perform statistical analysis on various strategies. Several wargames (boardgames) are made available by DefCol. Having this readily available would be very helpful for both educators and trainees. Moreover, when done properly, this could even be combined with reinforcement learning, to obtain the "perfect strategist".
Analysis could include the use of statistical methods to identify successful strategies under different conditions.

**Note:** multiple projects possible

### Suggested References
* games available at the department 
* additional POC: Mr DEPROUW Maxime (MWMW/DefCol)

## Modelling sports races
Mathematical modelling can used to create digital equivalents of car races of skiing, which in turn can be optimised

### Suggested References
* [A Mathematical Model for Nordic Skiing](https://arxiv.org/pdf/2410.02767)
* [Planning Formula One race strategies using discrete-event simulation](https://www.tandfonline.com/doi/full/10.1057/palgrave.jors.2602626)
* [A mathematical model for simulating cycling: applied to track cycling](https://link.springer.com/article/10.1007/s12283-018-0283-0)

## Computer networks
Computer networks rely on multiple layers, each with unique protocols and constraints. Modeling and simulating these networks allows us to analyze performance, identify bottlenecks, and optimize communication pathways. Projects in this area may focus on network performance under various conditions or on simulating specific protocols to analyze effectiveness and limitations. 

For example, you can study a specific  network layer or protocol, such as transport layer protocols (TCP, UDP), routing in the network layer, or specific application protocols. You can then focus on practical relevance, such as enhancing data throughput, minimizing latency, or optimizing packet routing. Additionally, load balancing in networks can also be studied.


### Suggested References
* [Computer networking - A top-down Approach](https://github.com/TimorYang/Computer-Networking-Keith-Ross/blob/main/book/Kurose,%20James%20F._Ross,%20Keith%20W%20-%20Computer%20networking_%20a%20top-down%20approach-Pearson%20(2017).pdf)
* [Load Balancing](https://samwho.dev/load-balancing/)

## Opinion dynamics
People sometimes change their opinions when they discuss things with each other. Mathematics (including graph theory) can be used to study opinion changes in simplifications of real-life situations, and explore how people influence each other through their social interactions. These models can help us learn how to promote the spread of accurate information and reduce the spread of inaccurate information. 

### Suggested References
* [Opinion dynamics in social networks: From models to data](https://arxiv.org/pdf/2201.01322)
* [Using Mathematics to Study How People Influence Each Other’s Opinions](https://kids.frontiersin.org/articles/10.3389/frym.2024.1253153/)


## Mission planning of a CubeSat
The KU Leuven is building a Small modular satellite (this type is also known as a CubeSat) named CubeSpec to perform asteroseismology of massive stars from a low earth orbit (a satellite circling the earth at an altitude of roughly 500 km). For this purpose the spectrograph must be pointed accurately at these massive stars given a minimal exposure time and an appurtenant revisit frequency. Knowing the mission priorities, an ordered target list is provided. In an ICRF (inertial celestial reference frame) system, these targets remain fixed in position. Using the available packages for orbit propagation, use discrete event simulation and optimisation to find if the minimal mission criteria are respected.

### Suggested References
* [SatelliteToolbox.jl] (https://github.com/JuliaSpace/SatelliteToolbox.jl)
* [CubeSpec] (https://fys.kuleuven.be/ster/instruments/cubespec) and all references at the bottom of the page, in particular the following:
* [The CubeSpec space mission. I. Asteroseismology of massive stars from time-series optical spectroscopy: Science requirements and target list prioritisation] (https://ui.adsabs.harvard.edu/abs/2022A%26A...658A..96B/abstract)

## Downlinking Geo Intelligence Data
An Earth sensing satellite such as CSO (Composante Spatiale Optique) collects geo-intelligence images over areas of interest to the intelligence services. When it overflies a region of interest, it captures images. As soon as the satellite has collected this information, it must be downlinked to a ground-station in allied territory. This can be done when the satellite overflies a region within sight of the station.

Satellite properties: You can find or estimate the image processing time, the maximal on-board memory, the required downlink time and bandwith and the orbit characteristics of such a satellite.

Use this information to answer the question related to a (semi-) realistic scenario: Imagine we wish to gain information related to the activities of a given dictator in a given Corean country (e.g. when he takes his train). Imagine the only ground station is located in France (Toulouse). When would we be able to acquire this information in Belgium? What would be the amount of images we can downlink? Would one ground station suffice? Is it interesting to use one of France's oversea territories to place a second ground station? What would be the impact? Perform a sensitivity analysis to demonstrate these impacts.

### Suggested References
* [SatelliteToolbox.jl] (https://github.com/JuliaSpace/SatelliteToolbox.jl)
* [CSO] (https://space.skyrocket.de/doc_sdat/cso-1.htm)
* [Mathematical Programming for Earth Observation Satellite Mission Planning] (https://link.springer.com/chapter/10.1007/978-1-4757-3752-3_7)
* [Three Scheduling Algorithms Applied to the Earth Observing Systems Domain] (https://www.researchgate.net/publication/227447254_Three_Scheduling_Algorithms_Applied_to_the_Earth_Observing_Systems_Domain)

## Airport Ground Handling
Simulate the turnaround process for airplanes at an airport (unloading and loading passengers, refueling, baggage handling, etc.) Minimize the total turnover time while making sure that all conditions are met. Introduce disturbances such as random delays (e.g. mechanical issues). Once the individual plane process is in place, zoom out to a small scale airport and cover the overall process.

### Suggested References
* [Modelling of Ground Handling Operations at Airport](https://ilot.lukasiewicz.gov.pl/kones/2010/3_2010/2010_kwasiborska_modelling_of_ground.pdf)

## Supermarket Checkout Simulation
You have witnessed the tendency to start placing self-checkouts at supermarkets to increase efficiency and reduce the needed staff. Whilst they do not need a dedicated employee per register, they do need one for oversight, in aiding the client in case of problems or to perform random checks. You also have shops where you can scan your items whilst doing shopping.

Construct a model for this purpose that represents as closely as possible a real-life scenario with conventional registers and self checkouts. Use e.g. a nearby shop for inspiration. Try to maximise efficiency and reduce the total cost, whilst keeping track of customer satisfaction.

### Suggested References
* [Data-Driven Simulation Modeling of the Checkout Process in Supermarkets: Insights for Decision Support in Retail Operations] (https://www.researchgate.net/publication/347806816_Data-Driven_Simulation_Modeling_of_the_Checkout_Process_in_Supermarkets_Insights_for_Decision_Support_in_Retail_Operations)

## Public Transit System Simulation
Take the layout of the subway/tube/undergound public transit system of a major city of your liking. Choose a city of which there is reference to this information. Try to find, using a given number of stops and crowd density (in function of a timetable) an optimal schedule to limit passenger waiting times and overcrowding.

### Suggested References
* [Simulation models for public transportation: a state-of-the-art review](https://www.sciencedirect.com/science/article/pii/S1877050922023304)

## Train Station Simulation
The Brussels North-South connection is the bussiest railroad of the country. Almost 1/3 of all Belgian trains pass through this station on a daily basis. The biggest bottleneck is the station of Brussels-Central, where only 6 tracks are available. Place yourself in the position of a train traffic manager and find a way to run the station as efficiently as possible. For actual data, refer to the website of the NMBS/SNCB. Bear in mind that not all trains are equally important. International trains will have priority over local trains.

As you will have discovered by now, trains often tend to be delayed due to a variety of reasons: persons on the tracks, malfunctions in the signaling, trains broken down, etc. Find a way to model these disturbances and percieve the backlash of such an event. Use this to perform a sensitivity analysis.

### References
* Question asked for POC at Infrabel
* [NMBS/SNCB] (https://www.belgiantrain.be/nl)
* [Infrabel] (https://infrabel.be/nl)

## Electric Car Charging
The amount of electric cars in all sorts and sizes is strongly increasing. These cars all need to be charged when not in use, demanding high amounts of power from the grid. Knowing that these cars are usually used for commuting, their battery only needs to be recharged partially or every few days. You will have users who like to always leave the garage with a full charge, others will be less disciplined.

Construct a model indicating the amount of power required by these cars and the strain it puts on the electricity grid. Consider the case of a brown out (almost no electricity produced by neither wind nor solar (cloudy and windless day)) where still the cars need to be recharged. Make predictions pertaining to the evolution of the amount of cars in the coming years and the addition of solar arrays. Is our current supply equipped to deal with this evolution?

### Suggested References
* [Electric vehicle charging stations: Model, algorithm, simulation, location, and capacity planning] (https://www.sciencedirect.com/science/article/pii/S2405844024051843)
* [Dynamic modeling and real-time management of a system of EV fast-charging stations] (https://www.sciencedirect.com/science/article/abs/pii/S0968090X21002023)
* [Analyse van het elektriciteitsverbruik in België/ Consommation d’électricité en Belgique : analyse] (https://nl.wikipower.be/blog/analyse-van-het-elektriciteitsverbruik-in-belgie/)
* [PROSPECTIEVE STUDIE ELEKTRICITEIT] (https://economie.fgov.be/sites/default/files/Files/Energy/Prospectieve-studie-elektriciteit-Monitoringverslag-over-de-bevoorradingszekerheid-december-2019.pdf)
* [ETUDE PROSPECTIVE ELECTRICITE] (https://economie.fgov.be/sites/default/files/Files/Energy/Etude-prospective-electricite-rapport-monitoring-securite-approvisionnement-decembre-2019.pdf)

## Traffic Flow Optimization (Oosterweel)
In the list of the 2023 topics, you can find following concept:

*Traffic congestion is a common problem in urban areas. Mathematical modeling and simulation can be used to optimize traffic flow, reduce congestion, and improve overall transportation efficiency. 
This project could involve modeling traffic patterns, simulating different traffic management strategies, and identifying the most effective solutions. Additionaly, you might also consider
the impact of connected and autonomous vehicles on traffic flow.*

**Update:** Revise this idea and apply it to the evolution of the 'Oosterweel' works around Antwerp. E.g. a temporary bridge (the bypass) is currently under construction to be able to bring down the old bridge. Knowing the trafic flows in and around Antwerp, this reduced capacity will have a (near) devastating impact on mobility. Prove this by using simulation. Make predictions of the impact of other stages of the works (the opening of the tunnel) on the overall car/truck mobility in and around Antwerp. Make your study with horizon 2033.


### References:
* [An Introduction to Traffic Flow Theory](https://link.springer.com/book/10.1007/978-1-4614-8435-6)
* [Decision making process on the Antwerp Oosterweel link: lessons learnt] (https://biblio.ugent.be/publication/2955629)
* [OOSTERWEEL CONNECTION] (https://www.eib.org/en/projects/pipelines/all/20160779)
* [Oosterweelverbinding.be] (https://www.oosterweelverbinding.be)

## Sports Tournament Scheduling and Optimization
Model the scheduling and logistics of a sports tournament (e.g. the World Cup Football) with multiple teams, venues and constraints (resting days, availability). Optimize the schedule to ensure fairness, minimize travel distance/cost and maximize the audience engagement (i.e. accessibility for a geographically dispersed audience at reasonable timeslots). Also consider constraints such as unexpected delays, possible withdrawals, extra time and broadcasting limitations.

### References:
* [FIFA Wolrd Cup 26] (https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026)
* [Scheduling in Sports] (https://www.sciencedirect.com/science/article/abs/pii/S0304020808734789)
* [Scheduling in sports: An annotated bibliography] (https://www.sciencedirect.com/science/article/abs/pii/S0305054809001543)



## Virtual Machine Design and Hardware Simulation

Virtual machines (VMs) simulate computer systems, allowing us to explore core concepts of computer architecture and software portability. In this project, you’ll design a VM capable of running assembly programs, and extend it with features that allow comparisons of different hardware architectures, simulation of peripheral devices, and testing frameworks.

**Potiential objectives**:
1. **Hardware Emulation**: Implement VM versions with different architectural features (e.g., RISC vs. CISC, variations in cache sizes and clock speeds). Study how these factors influence program efficiency, memory use, and overall performance.
   
2. **Performance Testing and Benchmarking**: Develop unit tests for instruction implementations and build performance benchmarks for common tasks to evaluate VM speed and efficiency under various configurations. Conduct stress tests by running complex or recursive programs and analyze memory usage, register values, and response times.

3. **Simulation of Peripheral Devices**: Integrate simulated peripherals like disk storage, network interfaces, and graphical outputs. Test how these devices interact with the VM's core and optimize the model to support direct memory access (DMA) and interrupt handling.

4. **Hardware vs. Virtual Comparison**: Compare the VM’s performance to that of physical hardware (if accessible), analyzing differences in execution time, efficiency, and system requirements. This may involve observing how identical tasks perform on different architectures.

5. **Testing Framework Development**: Construct a framework for running and debugging LC-3 assembly programs on your VM. Include debugging features such as step-through execution and logging to help identify performance bottlenecks or coding issues.

6. **Visualization Tools**: Implement visualization tools that provide real-time insights into memory allocation, register values, and instruction flow, aiding in model debugging and optimization.

### Suggested References
* [Write your Own Virtual Machine](https://www.jmeiners.com/lc3-vm/)
* [Virtual Machines: Architectures, Implementations, and Applications](https://old.hotchips.org/wp-content/uploads/hc_archives/hc17/1_Sun/HC17.T1P1.pdf)
* [Computer Systems: A Programmer’s Perspective](https://csapp.cs.cmu.edu/)
* [An Overview of Virtual Machine Architectures](https://personal.utdallas.edu/~mxk055100/courses/cloud11f_files/smith-vm-overview.pdf)
* [Computer networking, a top down approach](https://github.com/kowsertusher/Book/blob/master/Computer.Networking%20A%20Top-Down%20Approach%206th%20Edition.pdf)

"""

# ╔═╡ 94c57b2d-24c1-45d6-aba4-77aefd4da9bf
md"""
# 2023 project ideas
Below you can find a list of possible projects. 
Almost all of these are described in a very generic way and will require some research on your behalf. 
Some background and/or similar studies are provided for each project, most of these being more complex than what is expected of you.

**Expectation:**:
1. Describe the setting or the problem you study
2. Describe the desired outcome of the study
3. Describe the model you built, including its limitations and accepted hypotheses. 
4. Describe your analysis
5. Describe the outcome or suggestions

### Generic references for inspiration
* [Mathematical Modeling and Simulation of Systems](https://link.springer.com/book/10.1007/978-3-031-30251-0)
* [Modeling and Simulation - An Application-Oriented Introduction](https://link.springer.com/book/10.1007/978-3-642-39524-6)
* [Modeling and Simulation in Engineering](https://www.mdpi.com/books/book/6451-modeling-and-simulation-in-engineering)
* [Engineering Principles of Combat Modeling and Distributed Simulation](https://www.wiley.com/en-us/Engineering+Principles+of+Combat+Modeling+and+Distributed+Simulation-p-9781118180310)
* [Introduction to Transportation Analysis, Modeling and Simulation - Computational Foundations and Multimodal Applications](https://link.springer.com/book/10.1007/978-1-4471-5637-6)

## Optimizing RMA services
Different services within the RMA are managed by Sodexo (restaurant, kitchen, bar, cleaning, gardening etc.). When modeled properly, you can use simulation to optimize the use of resources (personnel, equipment, etc.) or identify bottlenecks for these services. 
The local Sodexo manager is willing to cooperate and provide data and insights in the current situation. Different projects are possible, depending on your interest. 
1. The flux and waiting times in the mess hall: ss the number of people on the site of the RMA is steadily increasing, this poses additional challenges in terms of the organization of the flow of the people coming in for breakfast/lunch/dinner. For this setting, you could combine:
    * historical data (provided)
    * a comprehensive analysis of the flows and the processes of the mess hall (provided + own insights)
    * an accurate estimate of client arrival (provided/own insights)
    to determine the bottlenecks in the current layout and propose innovative solutions (e.g. layout modifications, extensions, staffing…) to reduce the time spent “in the system”.
2. The cafeteria of the RMA (bar) is used for different activities: coffee breaks in the morning, sandwiches at lunch, receptions related to activities and serving drinks in the evening to the people on site. Like the mess hall, this system is increasingly being stressed due to increased demand. For this setting, you could combine:
    * historical data (provided)
    * a comprehensive analysis of the flows and the processes of cafeteria (provided + own insights)
    * an accurate estimate of client arrival (provided/own insights)
    to determine the bottlenecks in the current layout and propose innovative solutions (e.g. layout modifications, extensions, staffing, planning…) to reduce the time spent “in the system”.
3. The entire RMA needs regular housekeeping. The specific requirements vary in function of the size of the room, its flooring (carpet/tiles/other), the cleaning technique etc. There are some guidelines and data available regarding the time required for cleaning. The location where the equipment is stored, as well as the schedule can have a significant impact on the total time spent cleaning. For this setting you could consider:
    * the actual composition of the rooms (size, flooring etc.)
    * the current approach to scheduling the housekeeping
    * expert knowledge regarding time spent on cleaning
    * historical data to simulate occasional occupation
    to determine where potential gains can be made to reduce the total time spent on housekeeping.


## Traffic Flow Optimization
Traffic congestion is a common problem in urban areas. Mathematical modeling and simulation can be used to optimize traffic flow, reduce congestion, and improve overall transportation efficiency. 
This project could involve modeling traffic patterns, simulating different traffic management strategies, and identifying the most effective solutions. Additionaly, you might also consider
the impact of connected and autonomous vehicles on traffic flow.

### References:
* [An Introduction to Traffic Flow Theory](https://link.springer.com/book/10.1007/978-1-4614-8435-6)
* [Predictive Intelligent Transportation: Alleviating Traffic Congestion in the Internet of Vehicles](https://www.mdpi.com/1424-8220/21/21/7330)
* [Automated vehicle-involved traffic flow studies: A survey of assumptions, models, speculations, and perspectives](https://www.sciencedirect.com/science/article/pii/S0968090X21001224)


## Epidemic Modeling
Mathematical modeling and simulation can be used to understand the spread of diseases and evaluate the effectiveness of different control strategies. 
This project could involve modeling the spread of a specific disease, simulating different intervention strategies, and identifying the most effective approaches.

### References:
* [Mathematical Models in Infectious Disease Epidemiology](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7178885/)
* [Mathematical Models in Epidemiology](https://link.springer.com/book/10.1007/978-1-4939-9828-9)
* [Mathematical modeling of infectious disease dynamics](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3710332/)



## Supply Chain Optimization
Supply chains are complex systems that can be optimized using mathematical modeling and simulation. 
This project could involve modeling a specific supply chain, simulating different management strategies, and identifying the most effective solutions.

### References:
* [Supply Chain Simulation: A System Dynamics Approach for Improving Performance](https://link.springer.com/book/10.1007/978-0-85729-719-8)



## Climate Change Modeling
Mathematical modeling and simulation can be used to understand the impacts of climate change and evaluate the effectiveness of different mitigation strategies. 
You could consider modeling climate change scenarios, simulating different mitigation strategies, and identifying the most effective approaches.

### References:
* [Climate Change Modeling Methodology](https://link.springer.com/book/10.1007/978-1-4614-5767-1)



## Financial Market Simulation
Mathematical modeling and simulation can be used to understand financial markets and evaluate different investment strategies. 
For this project you could involve modeling financial market dynamics, simulating different investment strategies, and identifying the most effective approaches.

### References:
* [Financial Market Complexity](https://academic.oup.com/book/9066)
* [Modeling the Financial Market](https://link.springer.com/chapter/10.1007/978-3-319-00327-6_5)



## Network Security
Mathematical modeling and simulation can be used to understand network security threats and evaluate different defense strategies.
 This project could involve modeling network security threats, simulating different defense strategies, and identifying the most effective approaches.

### References:
* [Modeling and Simulation of Computer Networks and Systems](https://www.sciencedirect.com/book/9780128008874/modeling-and-simulation-of-computer-networks-and-systems)
* [Network Security: A Decision and Game-Theoretic Approach](https://www.cambridge.org/core/books/network-security/15A3FBFC81FE78648C8DB2FC1C74159B)


## Quantum Computing Simulation
Quantum computing is a rapidly growing field that promises to revolutionize computing. 
Mathematical modeling and simulation can be used to understand quantum computing systems and evaluate different quantum algorithms. 
This project could involve modeling a quantum computing system, simulating different quantum algorithms, and identifying the most effective approaches.

### References:
* [Quantum Computing: A Gentle Introduction](https://s3.amazonaws.com/arena-attachments/1000401/c8d3f8742d163b7ffd6ae3e4e4e07bf3.pdf)
* [Quantum Computing for Computer Scientists](https://www.cambridge.org/core/books/quantum-computing-for-computer-scientists/8AEA723BEE5CC9F5C03FDD4BA850C711)



## Predictive Maintenance in Manufacturing
Predictive maintenance techniques are designed to help determine the condition of in-service equipment in order to predict when maintenance should be performed. 
This approach promises cost savings over routine or time-based preventive maintenance. 
This project could involve modeling a specific manufacturing process, simulating different maintenance strategies, and identifying the most effective solutions.

### References:
* [Predictive Maintenance in Dynamic Systems: Advanced Methods, Decision Support Tools and Real-world Applications](https://link.springer.com/book/10.1007/978-3-030-05645-2)



## Ecosystem and Population Dynamics
Mathematical modeling and simulation can be used to understand ecosystem and population dynamics. 
This project could involve modeling a specific ecosystem or population, simulating different management strategies, and identifying the most effective approaches.

### References:
* [Mathematical Models in Population Biology and Epidemiology](https://link.springer.com/book/10.1007/978-1-4614-1686-9)
* [Population Dynamics and Projection Methods](https://link.springer.com/book/10.1007/978-90-481-8930-4)
* [Dynamic Population Models](https://link.springer.com/book/10.1007/1-4020-5230-8)
* [Data-Driven Mathematical Modeling Approaches for COVID-19: a survey](https://arxiv.org/abs/2309.17087)


## Water Resource Management
Water resource management is the activity of planning, developing, distributing and managing the optimum use of water resources. 
In the (near) future, it will become an increasingly scarse resource.
This project could involve modeling a specific water resource system, simulating different management strategies, and identifying the most effective solutions.

### References:
* [Water Resource Systems Planning and Management - An Introduction to Methods, Models, and Applications](https://link.springer.com/book/10.1007/978-3-319-44234-1)



## Telecommunication Networks
Telecommunication networks are complex systems that can be optimized using mathematical modeling and simulation. 
This project could involve modeling a specific telecommunication network, simulating different management strategies, and identifying the most effective solutions.

### References:
* [Modeling and Simulation of Computer Networks and Systems](https://www.sciencedirect.com/book/9780128008874/modeling-and-simulation-of-computer-networks-and-systems)


## Agricultural Systems
Mathematical modeling and simulation can be used to optimize agricultural systems. 
This project could involve modeling a specific agricultural system, simulating different management strategies, and identifying the most effective solutions.

### References:
* [Brief history of agricultural systems modeling](https://www.sciencedirect.com/science/article/pii/S0308521X16301585)
* [Agricultural Systems Modeling and Simulation](https://www.taylorfrancis.com/books/edit/10.1201/9781482269765/agricultural-systems-modeling-simulation-robert-peart-david-shoup)



## Air Traffic Management
Air traffic management is a complex system that can be optimized using mathematical modeling and simulation. 
This project could involve modeling a specific air traffic management system, simulating different management strategies, and identifying the most effective solutions.

### References:
* [Applied Game Theory to Enhance Air Traffic Control Training](https://coetthp.org/wp-content/uploads/HF002-Applied-Game-Theory-to-Enhance-ATC-Training-Final-Report.pdf)
* [Research on Game Theory of Air Traffic Management Cyber Physical System Security](https://www.mdpi.com/2226-4310/9/8/397)



## Waste Management
Waste management involves the activities and actions required to manage waste from its inception to its final disposal. 
This project could involve modeling a specific waste management system, simulating different management strategies, and identifying the most effective solutions.

### References:
* [Modeling the problem of locating collection areas for urban waste management. An application to the metropolitan area of Barcelona](https://www.sciencedirect.com/science/article/pii/S0305048305000289)



## Cybersecurity
Cybersecurity involves protecting systems, networks, and programs from digital attacks. 
This is a very large domain with room for multiple projects. A project could involve modeling a specific cybersecurity system, simulating different defense strategies, 
and identifying the most effective solutions.

### References:
* [Cybersecurity - Attack and Defense Strategies](https://www.packtpub.com/product/cybersecurity-attack-and-defense-strategies-third-edition/9781803248776)
* [The mathematical model of cyber attacks on the critical information system](https://iopscience.iop.org/article/10.1088/1742-6596/1202/1/012013/meta)
* [Mathematical Model of Cyber Intrusion in Smart Grid](https://ieeexplore.ieee.org/document/8715946)



## Disaster Management
Disaster management involves preparing, supporting, and rebuilding society when natural or human-made disasters occur. 
This project could involve modeling a specific disaster scenario, simulating different management strategies, and identifying the most effective solutions.

### References:
* [Optimising crowd evacuations: Mathematical, architectural and behavioural approaches](https://www.sciencedirect.com/science/article/pii/S0925753520301429)
* [Modeling and Simulation Agent-based of Natural Disaster Complex Systems](https://www.sciencedirect.com/science/article/pii/S1877050913008144)

"""

# ╔═╡ 5126163e-0f60-4712-97fd-5a085af91744
md"""
# 2022 project ideas
## Renewable energy production
Wind farms are used to generate renewable energy. Both wind direction and wind strength are variable. To account for this, one can adjust the orientation of the wind turbines so that they are perpendicular to the wind direction. An undesirable effect of this is that one turbine may be in the wake of another. As a result, the airflow received by the downstream turbine is typically more turbulent and its average speed is lower, reducing its efficiency. Turning the upstream turbine slightly (yaw angle) can attenuate this downstream effect. The efficiency of a turbine that is not perpendicular to the wind direction is naturally lower. This leads to an overall optimization problem where one has to dynamically control the different wind turbines taking into account the current wind direction.

### References:
* [Replacing wakes with streaks in wind turbine arrays](https://onlinelibrary.wiley.com/doi/full/10.1002/we.2577)
* [Application of a LES technique to characterize the wake deflection of a wind turbine in yaw](https://onlinelibrary.wiley.com/doi/epdf/10.1002/we.380)
* [Measurements on a Wind Turbine Wake: 3D Effects and Bluff Body Vortex Shedding](https://onlinelibrary.wiley.com/doi/epdf/10.1002/we.156)


## Renewable energy production (2)
Hydroelectric is another form of renewable energy. Water reservoirs are created by placing one or multiple dams on a river. These reservoirs drive a turbine which powers a generator. There are multiple challenges involved with hydroelectric power. The rainfall or water supply is seldom constant over the year. Placing multiple (not coordinated) dams on a river can have a large impact on the downstream ecosystems, power generation and flow. Proper management of the systems of dams on the network can lead to substantial increases in overall power generation.

### References:
* [Forecast-informed hydropower optimization at long and short-time scales for a multiple dam network](https://aip.scitation.org/doi/abs/10.1063/1.5124097)
* [Optimal Control Method of Electric Power Generation in Multi Level Water Dams](https://link.springer.com/chapter/10.1007/978-3-642-16444-6_42)
* [Application of the Harmony Search optimization algorithm for the solution of the multiple dam system scheduling](https://link.springer.com/article/10.1007/s11081-011-9183-x)

## Renewable energy production (3)
Solar energy is becoming ever more visible in our environment. The optimal placement and configuration of a solar panel installation is not so trivial. Different effect play a role such as shading, panel orientation, solar angle evolution. Given a specific case, you could consider how to develop the optimal layout (accounting for seasonal variability). 

### References:
* [Spatial layout optimization for solar photovoltaic (PV) panel installation](https://www.sciencedirect.com/science/article/abs/pii/S0960148119319718)
* [An optical-energy model for optimizing the geometrical layout of solar photovoltaic arrays in a constrained field](https://www.sciencedirect.com/science/article/abs/pii/S0960148119319123)
* [Solar Array System Layout Optimization for Reducing Partial Shading Effect](http://przyrbwn.icm.edu.pl/APP/PDF/130/a130z1p014.pdf)


## Optimal deployment of law enforcement forces
During large scale events (e.g. sport events, european summit, protest) additional law enforcement forces are deployed. Just as in a military context, the form of deployment of troops can have a major impact on the successful control of a mass of people. Possibly historical data can be used for this (cooperation police Antwerp). 

### References:
* [Devising and Optimizing Crowd Control Strategies Using Agent-Based Modeling and Simulation](https://ieeexplore.ieee.org/document/9108875)
* [Simulating Crowd Behavior Using Artificial Potential Fields: An Agent-Based Simulation Approach](https://jstinp.um.ac.ir/article_42613_592bf75c5efc86ff6bcb6dfca776914b.pdf)
* [Crowd Simulation](https://link.springer.com/content/pdf/10.1007/978-3-319-65202-3.pdf)

## CCTV camera placement
One of the means used to deter crime and to detect traffic violations are CCTV cameras. The optimal placement of these cameras is a challenge. (cooperation police Antwerp).

### References:
* [On the real-world applicability of state-of-the-art algorithms for the optimal camera placement problem](https://ieeexplore.ieee.org/abstract/document/8820295)
* [On the optimal placement of cameras for surveillance and the underlying set cover problem](https://www.sciencedirect.com/science/article/abs/pii/S1568494618305829)

## DES for logistics
Discrete event simulation can be used in multiple domains of logistics (in the broad sense). For a specific application you could consider this approach.

### References:
* [Discrete event simulation of multimodal and unimodal transportation in the wood supply chain: a literature review](https://www.silvafennica.fi/article/9984/author/18687)
* [Predicting the effect of nurse–patient ratio on nurse workload and care quality using discrete event simulation](https://sci-hub.st/https://doi.org/10.1111/jonm.12757)
* [Modeling Electric Vehicle Charging Demand with the Effect of Increasing EVSEs: A Discrete Event Simulation-Based Model](https://www.mdpi.com/1996-1073/14/13/3734)
* [Using discrete-event simulation to compare congestion management initiatives at a port terminal](https://www.sciencedirect.com/science/article/abs/pii/S1569190X21000769)
* [Modeling and discrete event simulation in industrial systems considering consumption and electrical energy generation](https://www.sciencedirect.com/science/article/abs/pii/S0959652619309576)
* [Full-Scale Discrete Event Simulation of an Automated Modular Conveyor System for Warehouse Logistics](https://link.springer.com/chapter/10.1007/978-3-030-29996-5_4)

## Cellular automata
Cellular automata (cf. Conway's game of life) have been around for a while. At the same time, they still are being used in research for different types of applications.

### References:
* [A review of assessment methods for cellular automata models of land-use change and urban growth](https://www.tandfonline.com/doi/abs/10.1080/13658816.2019.1684499)
* [Cellular automata for simulating land-use change with a constrained irregular space representation: A case study in Nanjing city, China](https://journals.sagepub.com/doi/abs/10.1177/2399808320949889)
* [Modelling urban change with cellular automata: Contemporary issues and future research directions](https://journals.sagepub.com/doi/full/10.1177/0309132519895305)
* [A Modified Cellular Automaton Model for Accounting for Traffic Behaviors during Signal Change Intervals](https://www.hindawi.com/journals/jat/2018/8961454/)
* [On the consistency of urban cellular automata models based on hexagonal and square cells](https://journals.sagepub.com/doi/abs/10.1177/2399808319898501)
* [Modeling and analyzing malware diffusion in wireless sensor networks based on cellular automaton](https://journals.sagepub.com/doi/full/10.1177/1550147720972944)

## Pedestrian dynamics
Simple mathematical model for pedestrian dynamics can capture a number of features that are observed in actual pedestrian flows on walkways. For example, when obstacles get in their way, either physical obstacles or other pedestrians, walkers experience a repulsive social force, that alters their velocity and current direction to avoid collision. This alone is sufficient to produce a variety of patterns that are reminiscent of actual pedestrian dynamics. The explorable is a simplified variant of a series of beautiful models introduced by Dirk Helbing that have found a wide range of application, e.g. panic dynamics, crowd turbulence, traffic jams and more.

### References
* [Social force model for pedestrian dynamics](https://journals.aps.org/pre/abstract/10.1103/PhysRevE.51.4282)
* [Simulating dynamical features of escape panic](https://www.nature.com/articles/35035023)
* [Modelling the evolution of human trail systems](https://www.nature.com/articles/40353)
* [Social Self-Organization](https://link.springer.com/book/10.1007/978-3-642-24004-1)
"""

# ╔═╡ 023da279-7a42-4cb1-addb-613d1363a282
md"""
# 2021 project ideas:
Below you can find a list of possible projects. Almost all of these are described in a very generic way and will require some research on your behalf. Some background and/or similar studies are provided for each project, most of these being more complex than what is expected of you.

**Aim of the project**:
1. Describe the setting or problem
2. Describe the desired outcome of the study
3. Describe the model you built, including its limitations and accepted hypotheses. 
4. Describe your analysis
5. Describe the outcome or suggestions

Note that for a project with a deterministic outcome, the use of simulation might not be required.
"""

# ╔═╡ 42968b6f-a86f-48dd-b354-d06dfd53624c
md"""
## Swarming (multiple projects)
The use of drone swarms has several applications in a military context. Drones can be equipped with different payloads such as high explosives, sensors (ISR), jammers, etc. Currently, all major military countries are conducting research on both the use of and the defense against drone swarms.

### Possible topics:
- **command and control (C2) of a drone swarm**: for the technology to be scalable, each element of the swarm should be cheap, so you will have a limited amount of control drones that are used for relaying communications with the HQ. The movement patterns of drones in different cases can be studied and optimised.
- **use of a drone swarm for ISR purposes**: drone swarms can be used to [gather intelligence](https://www.timesofisrael.com/in-apparent-world-first-idf-deployed-drone-swarms-in-gaza-fighting/) in addition to more traditional assets. Given a specific scenario and an ISR capacity, determine optimal use cases.
- **defense against a drone swarm**: given an adversarial drone swarm attack, determine optimal techniques of defense (weapon system and/or engagement method).
- **attack using a drone swarm**:  given an adversial defense system, determine optimal techniques/patterns/tactics to maximise the impact of the attack.

### References:
* [General info](https://www.vifindia.org/article/2020/april/27/drone-swarms-bracing-up-with-the-new-threat)
* [More details](http://unsworks.unsw.edu.au/fapi/datastream/unsworks:45320/SOURCE02?view=true)
"""

# ╔═╡ d3195ce3-cc34-458f-a526-f346591b34b2
md"""
## Mine hunting
Mine Counter Measure (MCM) is a general capability that can include several types of missions required to complete a specific operational intent:
- General or detailed survey to prepare Mine Warfare (MW) operations,
- Surveillance or exploration to assess Mine Warfare risk,
- Reconnaissance and Mine avoidance to avoid mine threat,
- Clearance to sanitize,
- Masking and jamming to prevent mine action,
- Provocation and discredit to deceive mine logic.

### Possible projects
- **optimise sweep patterns to maximise detection**: the detection probability of a mine depends on its position with respect to the sonar and the composition of the seabed. Simulate a minefield and try to optimise the sweeping settings to finetune the detection rate.
- **optimise mine field**: different types of (deep) sea mines exist. Given a set of mines, evaluate the composition/layout of a minefield for maximum effect.

### References
- [Synthetic Aperture and 3D Imaging for Mine Hunting Sonar](https://hal.archives-ouvertes.fr/hal-00504862/document)
- [Minhunting sonar perfomance](https://apps.dtic.mil/sti/pdfs/ADA342568.pdf)
- [Modern mines](https://cimsec.org/modern-naval-mines-not-your-grandfathers-weapons-that-wait/)
"""

# ╔═╡ 8bc9e310-3151-4c49-b009-04b4cc1a4a84
md"""
## Airfield destruction
Destroying or rendering unusable an enemy airfield can have a major impact on the course of a conflict (think of the Six Day War). Typically, ballistic missiles and cruise missiles are used, each with a different effect and a different cost. A military airfield usually has a defense system against missiles and rockets where the interception rate is different for each weapon system. 
### Possible project
Consider an airport with its different components: the runway, the critical infrastructure (POL + control tower) and the different airplanes. You could look at Kleine Brogel or Florennes air base for inspiration. Determine the effect of using a specific set of weapon systems (ballistic & guided munitions, with submunitions or not with different CEP) and consider the optimal/ideal/minimal configuration that allows you to take out the airfield.

### References
* [Defense systems](https://www.boeing.com/defense/missile-defense/)
"""

# ╔═╡ 279eda92-e1cf-480e-a093-e17625046125
md"""
## Digital communication

### Possible projects
* **TCP/IP**: simulate the TCP/IP model for data transfer and look up the limits with respect to data troughput for given hardware.
* **routing**: analyse how well routing works using different routing protocols on a (dynamic) network.
* **tactical radio network**: compare different scheduling algorithms to maximise data throughput in a tactical radio network.

### References
* [Basic on internet and IP routing, TCP/IP](https://www.khanacademy.org/computing/computers-and-internet/xcae6f4a7ff015e7d:the-internet)
* [Routing protocol](https://en.wikipedia.org/wiki/Routing_protocol)
* [Scheduling](https://en.wikipedia.org/wiki/Scheduling_(computing)#Scheduling_disciplines)
"""

# ╔═╡ cb784ac1-7dde-4163-a325-379f87ccb18b
md"""
## Fine-tuning a grading system
Some universities allow a student to fail a course and still be able to go to the next year or be exempt from retaking the exam. A mishap in an otherwise good course can be forgiven as a result. The "optimal" ground rules of such a system are far from trivial. After all, there are conflicting interests to be realized. One wishes, on the one hand, to limit the number of students who can abuse the system and, on the other hand, to ensure that the majority of students can benefit from the system. In addition, for practical reasons, one may wish to limit the overall number of resits.

### Possible project
By using historical data over several years, it is possible to establish a multinomial distribution that describes the results of students in an academic bachelor. You can use this input to adjust the parameters of your system, taking into account a conflicting desired results (e.g. $<1\%$ “freeloaders”, limiting number of resits, maximal fair pardons).

### References
"""

# ╔═╡ a7659bd3-796b-4155-b01f-1d9ef6b42f12
md"""
## Chemistry
In the various chemistry courses, you have studied the reactions between molecules by means of kinetics. A reaction was modelled using a differential equation. However, it is also possible to model kinetics using stochastic methods. 

### Possible projects
Compare a stochastic model  (there are multiple in the reference) with a numerical method that you already know for some known reactions. In addition, use an optimisation method to fine-tune your reaction.

### References
* [Stochastic chemical kinetics](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5425731/)
"""

# ╔═╡ 57e9e568-4bb7-43d1-91cf-0711cc2fa905
md"""
## Finance
Modeling and simulation is widely used in the financial sector. Different techniques can be used.
### Possible projects
* **Portfolio optimisation of crypto currencies in combination with discrete even simulation**: We have already briefly discussed portfolio optimisation in the practical applications. However, the crypto market is much more volatile, so here it may be worthwhile to combine these optimisations with discrete event simulation and real data.
* **Insurance solvency**: Use Monte Carlo simulation or another suited method for a specific insurance to find an optimal balance between insurance premium and solvency.
* **Global trade embargo effects:** In today's world, nations are less likely to declare war on another country, but first try to achieve their goals through diplomatic or economic means. The global trade network has been extensively studied and data is freely available. Study the effect of a trade embargo on a particular country and consider possible unexpected alliances (where you can consider trade as an optimisation problem).
### References
* [Solvency ratio](https://en.wikipedia.org/wiki/Solvency_ratio)
* [Monte Carlo in insurance](https://www.researchgate.net/publication/332637928_Monte_Carlo_Methods_for_Insurance_Risk_Computation)
* [World Trade Network](https://www.researchgate.net/publication/23786718_The_World_Trade_Network)
* [World Trade Network dataset](http://www.cepii.fr/cepii/en/bdd_modele/presentation.asp?id=27), requires free registration, holds all network data.
"""

# ╔═╡ 2e4860bd-b74b-4671-8e57-c6849bc63d88
md"""
## Logistics
Supply chain optimisation and the optimal use of personnel or resources can significantly increase the efficiency of a logistics depot. These problems can be solved with linear programming, but it is often difficult to reach a solution because these problems are typically NP-hard. As a solution, either heuristics (cf. next year) or discrete event simulation is used.

### Possible projects
- **Personnel tasking**: given a specific warehouse, increase efficiency by optimising the tasks each person is executing.
- **Warehouse layout**: given a set of products and historical order data, optimise warehouse or grocery store layout for highest possible output (e.g. something similar to collect and go from the perspective of the store personnel)
- **Seaport operations**: In a cargo port, there are a multitude of actors at work such as pilots, ships, cranes, trains, trucks, etc.  In the context of efficient use of resources, it is interesting to simulate this in order to identify possible bottlenecks in different scenarios.  If necessary, study a part of a Belgian port.
### References
- [complete project personnel optimisation](https://www.mdpi.com/1999-4893/13/12/326)
- [data source](https://www.kaggle.com/msp48731/frequent-itemsets-and-association-rules/data)
- [seaport operations](https://sci-hub.st/https://doi.org/10.1177%2F003754979807000401)
- [layout optimisation](https://sci-hub.st/https://doi.org/10.1111/itor.12852)
"""

# ╔═╡ 4357e4be-1005-470f-978b-90844dd31b1a
md"""
## Healthcare
Within the healthcare sector there are a lot of use cases for discrete event simulation.

### Possible projects
get creative.
### References
- [overview paper](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7491890/)
- [staffing a neonatal ICU](https://journals.sagepub.com/doi/pdf/10.1177/1460458216628314)
- [capacity planning (COVID)](https://arxiv.org/abs/2012.07188)
"""

# ╔═╡ 88b57987-b284-41a7-8c35-3b29a0436d0f
md"""
## Biology
Simulation can also be used in biology.


### References:
- [evolution of a virus](https://academic.oup.com/ve/article/5/1/vez003/5372481)
- [evolution of a virus bis](https://sci-hub.st/https://doi.org/10.1007/s11538-018-00550-4)
"""

# ╔═╡ 72df832c-442f-4693-9953-df873951a1db
md"""
## Energy grid management
Managing the electricity grid is a major challenge. 
### Possible projects

### References
- [Introduction to electricity markets](https://www.e-education.psu.edu/ebf483/node/816)
"""

# ╔═╡ Cell order:
# ╟─fc0426fc-d2b6-4751-9c48-ecf31a7b5a3b
# ╟─a795cad3-33a6-4664-a4b4-52b083ed4308
# ╟─abd51e4f-6e18-461a-9882-a79a405bc1e2
# ╟─07965656-a4fe-449c-898b-2fed7e755c42
# ╟─69a9e78f-1150-4914-9772-d8feedd13fd0
# ╟─94c57b2d-24c1-45d6-aba4-77aefd4da9bf
# ╟─5126163e-0f60-4712-97fd-5a085af91744
# ╟─023da279-7a42-4cb1-addb-613d1363a282
# ╟─42968b6f-a86f-48dd-b354-d06dfd53624c
# ╟─d3195ce3-cc34-458f-a526-f346591b34b2
# ╟─8bc9e310-3151-4c49-b009-04b4cc1a4a84
# ╟─279eda92-e1cf-480e-a093-e17625046125
# ╟─cb784ac1-7dde-4163-a325-379f87ccb18b
# ╟─a7659bd3-796b-4155-b01f-1d9ef6b42f12
# ╟─57e9e568-4bb7-43d1-91cf-0711cc2fa905
# ╟─2e4860bd-b74b-4671-8e57-c6849bc63d88
# ╟─4357e4be-1005-470f-978b-90844dd31b1a
# ╟─88b57987-b284-41a7-8c35-3b29a0436d0f
# ╟─72df832c-442f-4693-9953-df873951a1db
