# ===============================================
# nuget.ps1
# NuGet package management (.NET)
# ===============================================

# NuGet aliases and functions
# Requires: nuget (NuGet - https://www.nuget.org/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand nuget) {
    # NuGet install - install packages
    <#
    .SYNOPSIS
        Installs packages using NuGet.
    .DESCRIPTION
        Installs packages using NuGet. Supports -Version, -Source, and -OutputDirectory flags.
    .PARAMETER Packages
        Package names to install.
    .PARAMETER Version
        Specific version to install.
    .PARAMETER Source
        Package source URL.
    .PARAMETER OutputDirectory
        Directory to install packages to.
    .EXAMPLE
        Install-NuGetPackage Newtonsoft.Json
        Installs Newtonsoft.Json.
    .EXAMPLE
        Install-NuGetPackage Newtonsoft.Json -Version 13.0.1
        Installs specific version.
    #>
    function Install-NuGetPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [string]$Version,
            [string]$Source,
            [string]$OutputDirectory
        )
        
        foreach ($package in $Packages) {
            $args = @('install', $package)
            if ($Version) {
                $args += '-Version', $Version
            }
            if ($Source) {
                $args += '-Source', $Source
            }
            if ($OutputDirectory) {
                $args += '-OutputDirectory', $OutputDirectory
            }
            & nuget @args
        }
    }
    Set-Alias -Name nugetinstall -Value Install-NuGetPackage -ErrorAction SilentlyContinue
    Set-Alias -Name nugetadd -Value Install-NuGetPackage -ErrorAction SilentlyContinue

    # NuGet restore - restore packages
    <#
    .SYNOPSIS
        Restores packages from packages.config or project.json.
    .DESCRIPTION
        Restores packages for a solution or project.
    .PARAMETER Path
        Path to solution or project file.
    .PARAMETER Source
        Package source URL.
    .EXAMPLE
        Restore-NuGetPackages
        Restores packages in current directory.
    .EXAMPLE
        Restore-NuGetPackages -Path MyProject.sln
        Restores packages for solution.
    #>
    function Restore-NuGetPackages {
        [CmdletBinding()]
        param(
            [string]$Path,
            [string]$Source
        )
        
        $args = @('restore')
        if ($Path) {
            $args += $Path
        }
        if ($Source) {
            $args += '-Source', $Source
        }
        & nuget @args
    }
    Set-Alias -Name nugetrestore -Value Restore-NuGetPackages -ErrorAction SilentlyContinue

    # NuGet update - update packages
    <#
    .SYNOPSIS
        Updates packages in packages.config.
    .DESCRIPTION
        Updates packages to their latest versions.
    .PARAMETER Path
        Path to packages.config file.
    .PARAMETER Id
        Specific package ID to update.
    .EXAMPLE
        Update-NuGetPackages
        Updates all packages in current directory.
    .EXAMPLE
        Update-NuGetPackages -Id Newtonsoft.Json
        Updates specific package.
    #>
    function Update-NuGetPackages {
        [CmdletBinding()]
        param(
            [string]$Path,
            [string]$Id
        )
        
        $args = @('update')
        if ($Path) {
            $args += $Path
        }
        if ($Id) {
            $args += '-Id', $Id
        }
        & nuget @args
    }
    Set-Alias -Name nugetupdate -Value Update-NuGetPackages -ErrorAction SilentlyContinue
}
else {
    Write-MissingToolWarning -Tool 'nuget' -InstallHint 'Install from: https://www.nuget.org/downloads or use: scoop install nuget (or: choco install nuget.commandline, or: winget install Microsoft.NuGet)'
}
