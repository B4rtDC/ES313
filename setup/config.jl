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

# mkpath (not mkdir) so a custom, nested download folder is created together with any missing parents
!ispath(downloadfolder) ? mkpath(downloadfolder) : nothing
cd(downloadfolder)

@info "Installing Git tools for Julia $(VERSION)..."
Pkg.add("Git")
using Git

coursefolder = joinpath(downloadfolder, "ES313")
if isdir(coursefolder)
    @info "An ES313 folder already exists at $(coursefolder); skipping the download. Use setup/update.jl to fetch updates."
else
    @info "Downloading course material into $(downloadfolder)"
    try
        # if windows, use the configured git path
        Sys.iswindows() ? run(`$(git_path_windows) clone https://github.com/B4rtDC/ES313.git`) : run(`$(git()) clone https://github.com/B4rtDC/ES313.git`)
        @info "Download complete"
    catch err
        @warn "Cloning failed. Check one of the following:\n  - no/blocked internet connection (behind the CDN proxy? switch to an open network such as pubnet or eduroam)\n  - wrong path to git.exe in `git_path_windows` (Windows only)\n  - the ES313 folder already exists from an earlier run"
        @error "Git clone error" exception=err
    end
end

# Only continue if the repository is actually present; otherwise abort here with a clear
# message instead of failing later with an opaque IOError.
if !isdir(coursefolder)
    error("No ES313 folder found in $(downloadfolder): the download did not succeed. Fix the cause shown above and re-run this script.")
end

# Install & download required packages into environment
cd(coursefolder)
Pkg.activate(pwd())
@info "Downloading required packages"
Pkg.instantiate()
@info "Finished"
