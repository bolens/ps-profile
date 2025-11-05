# ===============================================
# 09-package-managers.ps1
# Package manager helper shorthands (Scoop, uv, pnpm, etc.)
# ===============================================

# Scoop helpers
if (Test-HasCommand scoop) {
    # Scoop install
    <#
    .SYNOPSIS
        Installs packages using Scoop.
    .DESCRIPTION
        Installs one or more packages using the Scoop package manager.
    #>
    function Install-ScoopPackage { scoop install @args }
    Set-Alias -Name sinstall -Value Install-ScoopPackage -ErrorAction SilentlyContinue

    # Scoop search
    <#
    .SYNOPSIS
        Searches for packages in Scoop.
    .DESCRIPTION
        Searches for available packages in Scoop repositories.
    #>
    function Find-ScoopPackage { scoop search @args }
    Set-Alias -Name ss -Value Find-ScoopPackage -ErrorAction SilentlyContinue

    # Scoop update
    <#
    .SYNOPSIS
        Updates packages using Scoop.
    .DESCRIPTION
        Updates specified packages or all packages if no arguments provided.
    #>
    function Update-ScoopPackage { scoop update @args }
    Set-Alias -Name su -Value Update-ScoopPackage -ErrorAction SilentlyContinue

    # Scoop update all
    <#
    .SYNOPSIS
        Updates all installed Scoop packages.
    .DESCRIPTION
        Updates all installed packages and Scoop itself.
    #>
    function Update-ScoopAll { scoop update * }
    Set-Alias -Name suu -Value Update-ScoopAll -ErrorAction SilentlyContinue

    # Scoop uninstall
    <#
    .SYNOPSIS
        Uninstalls packages using Scoop.
    .DESCRIPTION
        Removes installed packages from the system.
    #>
    function Uninstall-ScoopPackage { scoop uninstall @args }
    Set-Alias -Name sr -Value Uninstall-ScoopPackage -ErrorAction SilentlyContinue

    # Scoop list
    <#
    .SYNOPSIS
        Lists installed Scoop packages.
    .DESCRIPTION
        Shows all packages currently installed via Scoop.
    #>
    function Get-ScoopPackage { scoop list @args }
    Set-Alias -Name slist -Value Get-ScoopPackage -ErrorAction SilentlyContinue

    # Scoop info
    <#
    .SYNOPSIS
        Shows information about Scoop packages.
    .DESCRIPTION
        Displays detailed information about specified packages.
    #>
    function Get-ScoopPackageInfo { scoop info @args }
    Set-Alias -Name sh -Value Get-ScoopPackageInfo -ErrorAction SilentlyContinue

    # Scoop cleanup
    <#
    .SYNOPSIS
        Cleans up Scoop cache and old versions.
    .DESCRIPTION
        Removes old package versions and cleans the download cache.
    #>
    function Clear-ScoopCache { scoop cleanup *; scoop cache rm * }
    Set-Alias -Name scleanup -Value Clear-ScoopCache -ErrorAction SilentlyContinue
}
else {
    Write-Warning "Scoop not found. Install from: https://scoop.sh/"
}

# UV helpers
if (Test-HasCommand uv) {
    # UV install (tool install)
    <#
    .SYNOPSIS
        Installs Python tools using UV.
    .DESCRIPTION
        Installs Python applications as standalone executables.
    #>
    function Install-UVTool { uv tool install @args }
    Set-Alias -Name uvi -Value Install-UVTool -ErrorAction SilentlyContinue

    # UV run
    <#
    .SYNOPSIS
        Runs Python commands with UV.
    .DESCRIPTION
        Executes Python commands in temporary virtual environments.
    #>
    function Invoke-UVRun { uv run @args }
    Set-Alias -Name uvr -Value Invoke-UVRun -ErrorAction SilentlyContinue

    # UV tool run
    <#
    .SYNOPSIS
        Runs tools installed with UV.
    .DESCRIPTION
        Executes tools that were installed using uv tool install.
    #>
    function Invoke-UVTool { uv tool run @args }
    Set-Alias -Name uvx -Value Invoke-UVTool -ErrorAction SilentlyContinue

    # UV add
    <#
    .SYNOPSIS
        Adds dependencies to UV project.
    .DESCRIPTION
        Adds packages as dependencies to the current UV project.
    #>
    function Add-UVDependency { uv add @args }
    Set-Alias -Name uva -Value Add-UVDependency -ErrorAction SilentlyContinue

    # UV sync
    <#
    .SYNOPSIS
        Syncs UV project dependencies.
    .DESCRIPTION
        Installs and synchronizes all project dependencies.
    #>
    function Sync-UVDependencies { uv sync @args }
    Set-Alias -Name uvs -Value Sync-UVDependencies -ErrorAction SilentlyContinue
}
else {
    Write-Warning "UV not found. Install with: pip install uv"
}

# PNPM helpers
if (Test-HasCommand pnpm) {
    # PNPM install
    <#
    .SYNOPSIS
        Installs dependencies using PNPM.
    .DESCRIPTION
        Installs project dependencies defined in package.json.
    #>
    function Install-PnpmPackage { pnpm install @args }
    Set-Alias -Name pni -Value Install-PnpmPackage -ErrorAction SilentlyContinue

    # PNPM add
    <#
    .SYNOPSIS
        Adds packages using PNPM.
    .DESCRIPTION
        Adds packages as dependencies to the project.
    #>
    function Add-PnpmPackage { pnpm add @args }
    Set-Alias -Name pna -Value Add-PnpmPackage -ErrorAction SilentlyContinue

    # PNPM add dev
    <#
    .SYNOPSIS
        Adds dev dependencies using PNPM.
    .DESCRIPTION
        Adds packages as development dependencies to the project.
    #>
    function Add-PnpmDevPackage { pnpm add -D @args }
    Set-Alias -Name pnd -Value Add-PnpmDevPackage -ErrorAction SilentlyContinue

    # PNPM run
    <#
    .SYNOPSIS
        Runs scripts using PNPM.
    .DESCRIPTION
        Executes scripts defined in package.json.
    #>
    function Invoke-PnpmScript { pnpm run @args }
    Set-Alias -Name pnr -Value Invoke-PnpmScript -ErrorAction SilentlyContinue

    # PNPM start
    <#
    .SYNOPSIS
        Starts the project using PNPM.
    .DESCRIPTION
        Runs the start script defined in package.json.
    #>
    function Start-PnpmProject { pnpm start @args }
    Set-Alias -Name pns -Value Start-PnpmProject -ErrorAction SilentlyContinue

    # PNPM build
    <#
    .SYNOPSIS
        Builds the project using PNPM.
    .DESCRIPTION
        Runs the build script defined in package.json.
    #>
    function Build-PnpmProject { pnpm run build @args }
    Set-Alias -Name pnb -Value Build-PnpmProject -ErrorAction SilentlyContinue

    # PNPM test
    <#
    .SYNOPSIS
        Runs tests using PNPM.
    .DESCRIPTION
        Runs the test script defined in package.json.
    #>
    function Test-PnpmProject { pnpm run test @args }
    Set-Alias -Name pnt -Value Test-PnpmProject -ErrorAction SilentlyContinue

    # PNPM dev
    <#
    .SYNOPSIS
        Runs development server using PNPM.
    .DESCRIPTION
        Runs the dev script defined in package.json.
    #>
    function Start-PnpmDev { pnpm run dev @args }
    Set-Alias -Name pndev -Value Start-PnpmDev -ErrorAction SilentlyContinue
}
else {
    Write-Warning "PNPM not found. Install with: npm install -g pnpm"
}
