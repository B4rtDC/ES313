# The CDN Windows machines ship Julia 1.10.0 and cannot be updated, so the course environment has
# to keep working on exactly that release; newer 1.10.x are fine. See setup/maintaining.md.
if VERSION.major != 1 || VERSION.minor != 10
    error("ES313 is configured for Julia 1.10.x. On personal computers, start Pluto with `julia +1.10 setup/start.jl`. On the CDN Windows machine, use the Julia 1.10 executable. Current Julia version: $(VERSION)")
end

# activate the environment
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

# change to the root directory of the course
cd(joinpath(@__DIR__, ".."))

# Set threads at Julia startup, for example: `julia +1.10 -t auto setup/start.jl`.
# start Pluto
using Pluto
Pluto.run()
