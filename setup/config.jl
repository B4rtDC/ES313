# ------------------------------------------------- #
#         CHANGE ONLY THIS (IF NEEDED)              #
# ------------------------------------------------- #
# set the paths
const downloadfolder = joinpath(homedir(),"Documents")
const git_path_windows = "C:\\Program Files\\Git\\bin\\git.exe"



# ------------------------------------------------- #
#            DO NOT CHANGE THIS                     #
# ------------------------------------------------- #
# The CDN Windows machines ship Julia 1.10.0 and cannot be updated, so the course environment has
# to keep working on exactly that release; newer 1.10.x are fine. See setup/maintaining.md.
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

# Refresh the registry before instantiating. The course manifest pins recent packages
# (e.g. GracefulPkg, a dependency of Pluto), which a stale registry copy in the shared
# .julia depot does not know about; instantiate then stops with
#     ERROR: expected package `GracefulPkg [828d9ff0]` to be registered
# `Pkg.instantiate()` does not reliably fix this by itself: it only refreshes the registry
# when nothing else already marked it as updated in this session (`Pkg.add("Git")` above
# does exactly that) and when the registry is off its one-day cooldown. `Pkg.Registry.update()`
# has no cooldown, so it always refreshes.
@info "Updating the package registry"
try
    Pkg.Registry.update()
catch err
    @warn "Could not update the package registry; continuing with the local copy." exception=err
end

@info "Downloading required packages"
try
    Pkg.instantiate()
catch err
    if err isa Pkg.Types.PkgError && occursin("to be registered", err.msg)
        @error """
        The registry copy in your shared `.julia` depot is out of date and could not be refreshed,
        so Pkg does not know the packages that the course manifest asks for.

        This is almost always a network problem: registry updates are blocked behind the CDN proxy.
        Connect to an open network (pubnet or eduroam) and run this script again. If it keeps failing,
        replace the registry copy from a Julia 1.10 REPL:

            using Pkg
            rm(joinpath(DEPOT_PATH[1], "registries"); recursive=true, force=true)
            Pkg.Registry.add("General")

        and then re-run this script.
        """
    end
    rethrow(err)
end
@info "Finished"
