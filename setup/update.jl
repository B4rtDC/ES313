# ------------------------------------------------- #
#         CHANGE ONLY THIS (IF NEEDED)              #
# ------------------------------------------------- #
# set the path
const git_path_windows = "C:\\Program Files\\Git\\bin\\git.exe"



# ------------------------------------------------- #
#            DO NOT CHANGE THIS                     #
# ------------------------------------------------- #
if VERSION.major != 1 || VERSION.minor != 10
    error("ES313 is configured for Julia 1.10.x. On personal computers, run updates with `julia +1.10 setup/update.jl`. On the CDN Windows machine, use the Julia 1.10 executable. Current Julia version: $(VERSION)")
end

using Pkg
# change pwd
cd(joinpath(dirname(@__FILE__),".."))
Pkg.activate(pwd())
using Git

# fetch git updates
const stash_message = "ES313 automatic stash before update"
try
    if Sys.iswindows()
        run(`$(git_path_windows) stash push -m $(stash_message)`)
        run(`$(git_path_windows) pull --ff-only`)
    else
        run(`$(git()) stash push -m $(stash_message)`)
        run(`$(git()) pull --ff-only`)
    end
catch err
    @warn """
    The automatic update could not be completed (`git pull --ff-only` failed, most likely because your local repository has diverged from GitHub).
    Any local changes were saved in a git stash BEFORE the pull, so they are not lost. To inspect or recover them, run from $(pwd()):
        git stash list
        git stash show -p \"stash@{0}\"
        git stash pop \"stash@{0}\"
    See setup/readme.md (Getting updates) for more details.
    """
    rethrow(err)
end

# refresh the registry first (see setup/config.jl for why instantiate does not always do this)
@info "Updating the package registry"
try
    Pkg.Registry.update()
catch err
    @warn "Could not update the package registry; continuing with the local copy." exception=err
end

# install the package versions from Manifest.toml
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
