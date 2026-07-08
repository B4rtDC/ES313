# ------------------------------------------------- #
#         CHANGE ONLY THIS (IF NEEDED)              #
# ------------------------------------------------- #
# set the paths
const downloadfolder = joinpath(homedir(),"Documents")
const git_path_windows = "C:\\Program Files\\Git\\bin\\git.exe"



# ------------------------------------------------- #
#            DO NOT CHANGE THIS                     #
# ------------------------------------------------- #
if VERSION.major != 1 || VERSION.minor != 10
    error("ES313 is configured for Julia 1.10.x. On personal computers, install Juliaup and run this script with `julia +1.10 path/to/config.jl`. On the CDN Windows machine, use the Julia 1.10 executable. Current Julia version: $(VERSION)")
end

using Pkg

!ispath(downloadfolder) ? mkdir(downloadfolder) : nothing
cd(downloadfolder)

@info "Installing Git tools for Julia $(VERSION)..."
Pkg.add("Git")
using Git

@info "Downloading course material into $(downloadfolder)"
try
    # if windows, set the git path
    Sys.iswindows() ? run(`$(git_path_windows) clone https://github.com/B4rtDC/ES313.git`) : run(`$(git()) clone https://github.com/B4rtDC/ES313.git`)
    @info "Download complete"
catch err
    @warn "Something went wrong, check one of the following:\n  - .gitignore file location\n  - destination folder already is a git repository"
    @info err
end

# Install & download required packages into environment
cd(joinpath(downloadfolder,"ES313"))
Pkg.activate(pwd())
@info "Downloading required packages"
Pkg.instantiate()
@info "Finished"
