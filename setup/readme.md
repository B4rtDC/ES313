# Setup
This is a small guide intended to put you on your way for this course. We will be working with Julia v1.10.x for all applications. It is recommended that you do all this before attending class, because the installation might take a while. A speedy and stable internet connection is an added value.

We try to make sure that the installation and configuration runs as smoothly as possible with a minimum of effort on your part. These guidelines work for Windows, MacOS and Linux. Occasionally there is a small difference between the platforms that will be made clear during this walkthrough. This guide has been successfully tested on Windows 11 Enterprise (CDN), MacOS and Ubuntu.

## Tools
* You will be using the Julia REPL in combination Pluto notebooks.
* For code development you could use Notepad++ or Visual Studio Code (available in the CDN software center). There is a Julia language extension ([Notepad++](https://github.com/JuliaEditorSupport/julia-NotepadPlusPlus)/[VS Code](https://code.visualstudio.com/docs/languages/julia)) available for both. We use Visual Studio Code for this course.


## Installation
The process detailed below will guide you through the installation of Julia and the necessary dependencies. It works for both your personal computer and the CDN computer.

**CDN specific remark**:
When connected to the CDN network, you are behind the CDN proxy. This can impact the installation process. For the most fluid user experience, we recommend that you install Julia
from the software center when connected to CDN and then connect to an open network (such as pubnet or eduroam) for the rest of the installation process.

### Getting started (do this once)
0. Make sure you have [Git](https://git-scm.com) on your system (you can find this in the software center for a CDN computer).
1. Install Julia
    * CDN computer: install Julia 1.10 from the software center. **Note:** this requires you to be connected to CDN. The examples below assume the executable is available at
        ```powershell
        C:\Program Files\Julia-1.10\bin\julia.exe
        ```
    * Windows personal computer: install Juliaup first by following the official instructions on [JuliaLang](https://julialang.org/downloads/) or the [Juliaup documentation](https://github.com/JuliaLang/juliaup). For example, in PowerShell:
        ```powershell
        winget install --name Julia --id 9NJNWW8PVKMN -e -s msstore
        ```
    * MacOS/Linux personal computer: install Juliaup first by following the official instructions on [JuliaLang](https://julialang.org/downloads/) or the [Juliaup documentation](https://github.com/JuliaLang/juliaup). For example:
        ```bash
        curl -fsSL https://install.julialang.org | sh
        ```
    * After Juliaup has been installed on your personal computer, install the Julia 1.10 channel:
        ```bash
        juliaup add 1.10
        ```

        The `juliaup` command only works after Juliaup itself has been installed.
2. Copy the configuration script from [here](https://raw.githubusercontent.com/B4rtDC/ES313/master/setup/config.jl) and store it as a .jl file (e.g. with Notepad++ or VSCode). Things to modify by yourself (if required):
    * For Windows: the path to your `Git` install. The default path is the one that should work for CDN, i.e.
        ```julia
        const git_path_windows = "C:\\Program Files\\Git\\bin\\git.exe"
        ```
        can be modified to (for example)
        ```julia
        const git_path_windows = "Path\\to\\my\\Git\\installation\\git.exe"
        ```
    
    * The location where you want the course documentation to be downloaded. By default, the `ES313` folder will be installed in
        * `C:\\Users\\YourAccount\\Documents\\` on Windows 
        * `/Users/YourAccount/Documents/` on Mac
        * `/home/YourAccount/Documents/` on Linux

        if you want to use another path, you can change it, e.g.
        ```Julia
        joinpath(homedir(),"Documents","3Ba","Sem1","ES313")
        ```
        will download the course folder into 
        * `C:\\Users\\YourAccount\\Documents\\3Ba\\Sem1\\ES313` (Windows)
        *  `/Users/YourAccount/Documents/3Ba/Sem1/ES313` (MacOS)
        * `/home/YourAccount/3Ba/Sem1/ES313` (Linux)
    
    
        
3. Run the script `config.jl` with Julia 1.10. This will install the `Git.jl` package and subsequently proceed to fetch the git repository for the course in the required folder.
    ```powershell
    & "C:\Program Files\Julia-1.10\bin\julia.exe" "C:\path\to\folder name with a space\config.jl" # on CDN Windows
    ```
    ```powershell
    julia +1.10 "C:\path\to\config.jl" # on a personal Windows computer, after installing Juliaup and running juliaup add 1.10
    ```
    ```bash
    julia +1.10 path/to/config.jl # on Mac/Linux, after installing Juliaup and running juliaup add 1.10
    ```

You are now ready to start working on the course. Tested on:
* :white_check_mark: Ubuntu 26.04 LTS
* :white_check_mark: MacOS 26.5.1
* :white_check_mark: Windows 11 (CDN build 26200.8346)

:bulb: You might want to associate ``*.jl` files with Julia. After doing so, you can simply double click on a file to start working or fetch updates instead of having to pass by the terminal or REPL.


### Getting updates (run when needed)
Some lectures may get updates during the semester. If you have followed the installation process, you can get the most recent version of the lecture by running the update script.

0. On Windows, if required, modify the path to your `Git` installation (cf. configuration script).
1. Run the update script from the setup folder with Julia 1.10. This will fetch updates from GitHub, sync them with your local files, and install the package versions specified by the course manifest. Local changes in tracked files are saved in a named [git stash](https://git-scm.com/docs/git-stash) before the update is pulled. Please note that you will no longer see those local changes after the update; they are however not gone.
    ```powershell
    & "C:\Program Files\Julia-1.10\bin\julia.exe" "C:\path\to\folder name with a space\ES313\setup\update.jl" # on CDN Windows
    ```
    ```powershell
    julia +1.10 "C:\path\to\folder name with a space\ES313\setup\update.jl" # on a personal Windows computer
    ```
    ```bash
    julia +1.10 "path/to/folder name with a space/ES313/setup/update.jl" # on Mac/Linux
    ```
    The update uses `git pull --ff-only`. If that fails, your local repository probably has commits that need manual attention before it can be updated safely.

    To inspect or recover the automatic stash, use:
    ```bash
    git stash list
    git stash show -p "stash@{0}"
    git stash pop "stash@{0}"
    ```
    `git stash pop` reapplies the stashed changes to your working copy and removes that stash entry. If you only want to inspect your changes, use the first two commands.

    For your own sanity, the most straightforward way that will allow you to stay synced and at the same time have your own file to work in, is to rename the notebook and maybe move it in a working directory from within Pluto as soon as you open it for the first time.
### Doing some work (run when you want to work)
1. Run the script to start the Pluto notebook. This will automatically start the notebook server using its default settings, which should open a new tab in your browser. If no window opens, you can always copy the explicit link from the REPL.
    ```powershell
    & "C:\Program Files\Julia-1.10\bin\julia.exe" "C:\path\to\folder name with a space\ES313\setup\start.jl" # on CDN Windows
    ```
    ```powershell
    julia +1.10 "C:\path\to\folder name with a space\ES313\setup\start.jl" # on a personal Windows computer
    ```
    ```bash
    julia +1.10 path/to/ES313/setup/start.jl # on Mac/Linux
    ```
2. By default the present working directory is changed to the one for this course, this means that you can open every single notebook simply by using a relative path e.g. `./Exercises/PS01 - Visualisation.jl` or `./Lectures/Lecture00.jl`. After typing `./`, you can even use the tab key for autocomplete.

### Troubleshooting
* The setup scripts intentionally stop when they are not run with Julia 1.10.x. On personal computers, check `juliaup status` and use `julia +1.10 ...`. On CDN Windows, check that you are using `C:\Program Files\Julia-1.10\bin\julia.exe`.
* Should you experience troubles with the installation, you can always delete the files in `C:\\Users\\YourAccount\\.julia\\` (Windows), `/Users/YourAccount/.julia/`(Mac) or `/home/YourAccount/.julia` (Linux) and then repeat the getting started sequence.

##  Overview of packages used

General:
* [Logging](https://docs.julialang.org/en/v1/stdlib/Logging/)
* [Dates](https://docs.julialang.org/en/v1/stdlib/Dates/)
* [Statistics](https://docs.julialang.org/en/v1/stdlib/Statistics/)
* [Distributions](https://juliastats.org/Distributions.jl/stable/)
* [HypothesisTests](https://juliastats.org/HypothesisTests.jl/stable/)
* [Combinatorics](https://github.com/JuliaMath/Combinatorics.jl)
* [CSV](https://juliadata.github.io/CSV.jl/stable/)
* [JLD2](https://github.com/JuliaIO/JLD2.jl)

Plotting:
* [Plots](http://docs.juliaplots.org/latest/)
* [StatsPlots](https://github.com/JuliaPlots/StatsPlots.jl)
* [LaTeXStrings](https://github.com/stevengj/LaTeXStrings.jl)
* [Measures](https://github.com/JuliaGraphics/Measures.jl)
* [NativeSVG](https://github.com/BenLauwens/NativeSVG.jl)

Optimization:
* [JuMP](https://jump.dev/JuMP.jl/stable/)
* [GLPK](https://github.com/jump-dev/GLPK.jl)
* [Optim](https://julianlsolvers.github.io/Optim.jl/stable/)
* [Tulip](https://github.com/ds4dm/Tulip.jl)
* [Ipopt](https://ipoptjl.readthedocs.io/en/latest/ipopt.html)

Discrete event simulation:
* [ResumableFunctions](https://github.com/JuliaDynamics/ResumableFunctions.jl)
* [ConcurrentSim](https://github.com/JuliaDynamics/ConcurrentSim.jl)

Notebooks:
* [Pluto](https://github.com/fonsp/Pluto.jl)
* [PlutoUI](https://github.com/fonsp/PlutoUI.jl)
