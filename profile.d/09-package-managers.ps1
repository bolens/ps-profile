# ===============================================
# 09-package-managers.ps1
# Package manager helper shorthands (Scoop, uv, pnpm, etc.)
# ===============================================

# Scoop helpers
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    # Scoop install
    <#
    .SYNOPSIS
        Installs packages using Scoop.
    .DESCRIPTION
        Installs one or more packages using the Scoop package manager.
    #>
    function sinstall { scoop install @args }

    # Scoop search
    <#
    .SYNOPSIS
        Searches for packages in Scoop.
    .DESCRIPTION
        Searches for available packages in Scoop repositories.
    #>
    function ss { scoop search @args }

    # Scoop update
    <#
    .SYNOPSIS
        Updates packages using Scoop.
    .DESCRIPTION
        Updates specified packages or all packages if no arguments provided.
    #>
    function su { scoop update @args }

    # Scoop update all
    <#
    .SYNOPSIS
        Updates all installed Scoop packages.
    .DESCRIPTION
        Updates all installed packages and Scoop itself.
    #>
    function suu { scoop update * }

    # Scoop uninstall
    <#
    .SYNOPSIS
        Uninstalls packages using Scoop.
    .DESCRIPTION
        Removes installed packages from the system.
    #>
    function sr { scoop uninstall @args }

    # Scoop list
    <#
    .SYNOPSIS
        Lists installed Scoop packages.
    .DESCRIPTION
        Shows all packages currently installed via Scoop.
    #>
    function slist { scoop list @args }

    # Scoop info
    <#
    .SYNOPSIS
        Shows information about Scoop packages.
    .DESCRIPTION
        Displays detailed information about specified packages.
    #>
    function sh { scoop info @args }

    # Scoop cleanup
    <#
    .SYNOPSIS
        Cleans up Scoop cache and old versions.
    .DESCRIPTION
        Removes old package versions and cleans the download cache.
    #>
    function scleanup { scoop cleanup *; scoop cache rm * }
}
else {
    Write-Warning "Scoop not found. Install from: https://scoop.sh/"
}

# UV helpers
if (Get-Command uv -ErrorAction SilentlyContinue) {
    # UV install (tool install)
    <#
    .SYNOPSIS
        Installs Python tools using UV.
    .DESCRIPTION
        Installs Python applications as standalone executables.
    #>
    function uvi { uv tool install @args }

    # UV run
    <#
    .SYNOPSIS
        Runs Python commands with UV.
    .DESCRIPTION
        Executes Python commands in temporary virtual environments.
    #>
    function uvr { uv run @args }

    # UV tool run
    <#
    .SYNOPSIS
        Runs tools installed with UV.
    .DESCRIPTION
        Executes tools that were installed using uv tool install.
    #>
    function uvx { uv tool run @args }

    # UV add
    <#
    .SYNOPSIS
        Adds dependencies to UV project.
    .DESCRIPTION
        Adds packages as dependencies to the current UV project.
    #>
    function uva { uv add @args }

    # UV sync
    <#
    .SYNOPSIS
        Syncs UV project dependencies.
    .DESCRIPTION
        Installs and synchronizes all project dependencies.
    #>
    function uvs { uv sync @args }
}
else {
    Write-Warning "UV not found. Install with: pip install uv"
}

# PNPM helpers
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    # PNPM install
    <#
    .SYNOPSIS
        Installs dependencies using PNPM.
    .DESCRIPTION
        Installs project dependencies defined in package.json.
    #>
    function pni { pnpm install @args }

    # PNPM add
    <#
    .SYNOPSIS
        Adds packages using PNPM.
    .DESCRIPTION
        Adds packages as dependencies to the project.
    #>
    function pna { pnpm add @args }

    # PNPM add dev
    <#
    .SYNOPSIS
        Adds dev dependencies using PNPM.
    .DESCRIPTION
        Adds packages as development dependencies to the project.
    #>
    function pnd { pnpm add -D @args }

    # PNPM run
    <#
    .SYNOPSIS
        Runs scripts using PNPM.
    .DESCRIPTION
        Executes scripts defined in package.json.
    #>
    function pnr { pnpm run @args }

    # PNPM start
    <#
    .SYNOPSIS
        Starts the project using PNPM.
    .DESCRIPTION
        Runs the start script defined in package.json.
    #>
    function pns { pnpm start @args }

    # PNPM build
    <#
    .SYNOPSIS
        Builds the project using PNPM.
    .DESCRIPTION
        Runs the build script defined in package.json.
    #>
    function pnb { pnpm run build @args }

    # PNPM test
    <#
    .SYNOPSIS
        Runs tests using PNPM.
    .DESCRIPTION
        Runs the test script defined in package.json.
    #>
    function pnt { pnpm run test @args }

    # PNPM dev
    <#
    .SYNOPSIS
        Runs development server using PNPM.
    .DESCRIPTION
        Runs the dev script defined in package.json.
    #>
    function pndev { pnpm run dev @args }
}
else {
    Write-Warning "PNPM not found. Install with: npm install -g pnpm"
}
