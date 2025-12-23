# ===============================================
# conan.ps1
# Conan C++ package manager
# ===============================================

# Conan aliases and functions
# Requires: conan (Conan - https://conan.io/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand conan) {
    # Conan install - install packages
    <#
    .SYNOPSIS
        Installs C++ packages using Conan.
    .DESCRIPTION
        Installs packages from conanfile.txt or conanfile.py. Supports --build and --profile flags.
    .PARAMETER Path
        Path to conanfile (optional, uses current directory if omitted).
    .PARAMETER Build
        Build policy (missing, outdated, all, never).
    .PARAMETER Profile
        Profile name to use.
    .EXAMPLE
        Install-ConanPackages
        Installs dependencies from current directory.
    .EXAMPLE
        Install-ConanPackages -Build missing
        Installs and builds missing packages.
    #>
    function Install-ConanPackages {
        [CmdletBinding()]
        param(
            [string]$Path,
            [string]$Build,
            [string]$Profile
        )
        
        $args = @('install')
        if ($Path) {
            $args += $Path
        }
        else {
            $args += '.'
        }
        if ($Build) {
            $args += '--build', $Build
        }
        if ($Profile) {
            $args += '--profile', $Profile
        }
        & conan @args
    }
    Set-Alias -Name conaninstall -Value Install-ConanPackages -ErrorAction SilentlyContinue

    # Conan create - create package
    <#
    .SYNOPSIS
        Creates a Conan package.
    .DESCRIPTION
        Creates and exports a package from a recipe.
    .PARAMETER Path
        Path to conanfile.py.
    .PARAMETER Profile
        Profile name to use.
    .EXAMPLE
        New-ConanPackage ./conanfile.py
        Creates package from recipe.
    #>
    function New-ConanPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Path,
            [string]$Profile
        )
        
        $args = @('create', $Path)
        if ($Profile) {
            $args += '--profile', $Profile
        }
        & conan @args
    }
    Set-Alias -Name conancreate -Value New-ConanPackage -ErrorAction SilentlyContinue

    # Conan search - search packages
    <#
    .SYNOPSIS
        Searches for Conan packages.
    .DESCRIPTION
        Searches remote repositories for packages.
    .PARAMETER Query
        Package name or pattern to search for.
    .PARAMETER Remote
        Remote name to search.
    .EXAMPLE
        Find-ConanPackage boost
        Searches for boost packages.
    #>
    function Find-ConanPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Query,
            [string]$Remote
        )
        
        $args = @('search', $Query)
        if ($Remote) {
            $args += '--remote', $Remote
        }
        & conan @args
    }
    Set-Alias -Name conansearch -Value Find-ConanPackage -ErrorAction SilentlyContinue

    # Conan update - update packages
    <#
    .SYNOPSIS
        Updates Conan packages.
    .DESCRIPTION
        Updates specified packages or all packages if no arguments provided.
        Uses 'conan install' with --update flag to update dependencies.
    .PARAMETER Packages
        Package names to update (optional, updates all if omitted).
    .PARAMETER Path
        Path to conanfile (optional, uses current directory if omitted).
    .PARAMETER Build
        Build policy (missing, outdated, all, never).
    .PARAMETER Profile
        Profile name to use.
    .EXAMPLE
        Update-ConanPackages
        Updates all packages in current directory.
    .EXAMPLE
        Update-ConanPackages -Path ./conanfile.txt
        Updates all packages in specific file.
    .EXAMPLE
        Update-ConanPackages -Build outdated
        Updates and rebuilds outdated packages.
    #>
    function Update-ConanPackages {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [string]$Path,
            [string]$Build,
            [string]$Profile
        )
            
        $args = @('install', '--update')
        if ($Path) {
            $args += $Path
        }
        else {
            $args += '.'
        }
        if ($Build) {
            $args += '--build', $Build
        }
        if ($Profile) {
            $args += '--profile', $Profile
        }
        & conan @args
    }
    Set-Alias -Name conanupdate -Value Update-ConanPackages -ErrorAction SilentlyContinue
}
else {
    $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        Get-PreferenceAwareInstallHint -ToolName 'conan' -ToolType 'python-package'
    }
    else {
        'Install with: pip install conan'
    }
    Write-MissingToolWarning -Tool 'conan' -InstallHint $installHint
}
