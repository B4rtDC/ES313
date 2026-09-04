# ------------------------------------------------- #
#            DO NOT CHANGE THIS                     #
# ------------------------------------------------- #
#
# Loads every binary dependency (_jll package) of the course environment one by one and reports
# which ones fail. Run it on a machine where notebooks fail to work, in particular on a CDN
# computer after changing the package versions in Project.toml/Manifest.toml.
#
# Why this exists: a _jll package opens its native library in `__init__`, i.e. when it is *loaded*,
# not when it is precompiled. A precompilation log therefore blames the dependent package
# (Plots, StatsPlots, ...) instead of the binary that actually refuses to load, and one broken
# library hides behind ten cascading failures. This script loads each of them directly, so the
# output is a flat list of exactly which binaries are broken on this machine.
#
# See setup/maintaining.md for what to do with the result.

if VERSION.major != 1 || VERSION.minor != 10
    error("ES313 is configured for Julia 1.10.x. Current Julia version: $(VERSION)")
end

using Pkg, TOML, Dates
const courseroot = normpath(joinpath(@__DIR__, ".."))
Pkg.activate(courseroot; io = devnull)

const manifest = TOML.parsefile(joinpath(courseroot, "Manifest.toml"))
const cslversion = TOML.parsefile(joinpath(Sys.STDLIB, "CompilerSupportLibraries_jll", "Project.toml"))["version"]

# every binary wrapper in the environment, in a stable order
const jlls = sort!([(name, first(entries)) for (name, entries) in manifest["deps"] if endswith(name, "_jll")])

const report = IOBuffer()
function log(str)
    println(str)
    println(report, str)
end

log("ES313 binary dependency probe")
log("  date                       : $(Dates.now())")
log("  julia                      : $(VERSION) ($(Sys.MACHINE))")
log("  CompilerSupportLibraries   : $(cslversion)")
log("  manifest resolved with     : $(get(manifest, "julia_version", "unknown"))")
log("  depot                      : $(DEPOT_PATH[1])")
log("  binary packages to load    : $(length(jlls))")
log("")

failures = Tuple{String,String}[]
for (i, (name, entry)) in enumerate(jlls)
    uuid = get(entry, "uuid", nothing)
    uuid === nothing && continue
    version = get(entry, "version", "stdlib")
    print("[$(lpad(i, 3))/$(length(jlls))] $(rpad(name, 34)) $(rpad(version, 14)) ")
    try
        Base.require(Base.PkgId(Base.UUID(uuid), name))
        println("ok")
    catch err
        println("FAILED")
        # the interesting part is the innermost message, not the load-path stacktrace
        msg = sprint(showerror, err isa LoadError ? err.error : err)
        push!(failures, (string(name, " ", version), first(split(msg, "\nStacktrace"))))
    end
end

log("")
if isempty(failures)
    log("All $(length(jlls)) binary dependencies loaded successfully on this machine.")
else
    log("$(length(failures)) binary dependencies FAILED to load:")
    for (pkg, msg) in failures
        log("")
        log("  * $(pkg)")
        for line in split(strip(msg), '\n')
            log("      $(line)")
        end
    end
    log("")
    log("""
    Every package that depends on one of these will also fail to precompile. Report the list above
    (or the file mentioned below) to the course lecturer; see setup/maintaining.md for the fix.""")
end

const reportfile = joinpath(courseroot, "cdn_probe_report.txt")
write(reportfile, take!(report))
println("\nReport written to $(reportfile)")
