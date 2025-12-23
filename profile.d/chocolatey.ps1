# ===============================================
# chocolatey.ps1
# Chocolatey package management (Windows)
# ===============================================

# Chocolatey aliases and functions
# Requires: choco (Chocolatey - https://chocolatey.org/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand choco) {
    # Chocolatey install - install packages
    <#
    .SYNOPSIS
        Installs packages using Chocolatey.
    .DESCRIPTION
        Installs packages using Chocolatey. Supports --version and --source flags.
    .PARAMETER Packages
        Package names to install.
    .PARAMETER Version
        Specific version to install.
    .PARAMETER Source
        Source to install from.
    .PARAMETER Yes
        Auto-confirm all prompts.
    .EXAMPLE
        Install-ChocoPackage git
        Installs git.
    .EXAMPLE
        Install-ChocoPackage git -Version 2.40.0
        Installs specific version of git.
    #>
    function Install-ChocoPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [string]$Version,
            [string]$Source,
            [switch]$Yes
        )
        
        $args = @()
        if ($Version) {
            $args += '--version', $Version
        }
        if ($Source) {
            $args += '--source', $Source
        }
        if ($Yes) {
            $args += '-y'
        }
        & choco install @args @Packages
    }
    Set-Alias -Name choinstall -Value Install-ChocoPackage -ErrorAction SilentlyContinue
    Set-Alias -Name choadd -Value Install-ChocoPackage -ErrorAction SilentlyContinue

    # Chocolatey uninstall - remove packages
    <#
    .SYNOPSIS
        Removes packages using Chocolatey.
    .DESCRIPTION
        Removes packages using Chocolatey. Supports --version and --remove-dependencies flags.
    .PARAMETER Packages
        Package names to remove.
    .PARAMETER Version
        Specific version to remove.
    .PARAMETER RemoveDependencies
        Remove dependencies as well.
    .PARAMETER Yes
        Auto-confirm all prompts.
    .EXAMPLE
        Remove-ChocoPackage git
        Removes git.
    .EXAMPLE
        Remove-ChocoPackage git -RemoveDependencies
        Removes git and its dependencies.
    #>
    function Remove-ChocoPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [string]$Version,
            [switch]$RemoveDependencies,
            [switch]$Yes
        )
        
        $args = @()
        if ($Version) {
            $args += '--version', $Version
        }
        if ($RemoveDependencies) {
            $args += '--remove-dependencies'
        }
        if ($Yes) {
            $args += '-y'
        }
        & choco uninstall @args @Packages
    }
    Set-Alias -Name chouninstall -Value Remove-ChocoPackage -ErrorAction SilentlyContinue
    Set-Alias -Name choremove -Value Remove-ChocoPackage -ErrorAction SilentlyContinue

    # Chocolatey outdated - check for outdated packages
    <#
    .SYNOPSIS
        Checks for outdated Chocolatey packages.
    .DESCRIPTION
        Lists all installed packages that have newer versions available.
        This is equivalent to running 'choco outdated'.
    #>
    function Test-ChocoOutdated {
        [CmdletBinding()]
        param()
        
        & choco outdated
    }
    Set-Alias -Name chooutdated -Value Test-ChocoOutdated -ErrorAction SilentlyContinue

    # Chocolatey upgrade - update packages
    <#
    .SYNOPSIS
        Updates Chocolatey packages.
    .DESCRIPTION
        Updates specified packages or all packages if no arguments provided.
    .PARAMETER Packages
        Package names to update (optional, updates all if omitted).
    .PARAMETER Yes
        Auto-confirm all prompts.
    .EXAMPLE
        Update-ChocoPackages
        Updates all packages.
    .EXAMPLE
        Update-ChocoPackages git
        Updates git package.
    #>
    function Update-ChocoPackages {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Yes
        )
        
        $args = @()
        if ($Yes) {
            $args += '-y'
        }
        if ($Packages) {
            & choco upgrade @args @Packages
        }
        else {
            & choco upgrade all @args
        }
    }
    Set-Alias -Name choupgrade -Value Update-ChocoPackages -ErrorAction SilentlyContinue
    Set-Alias -Name choupdate -Value Update-ChocoPackages -ErrorAction SilentlyContinue

    # Chocolatey self-update - update Chocolatey itself
    <#
    .SYNOPSIS
        Updates Chocolatey to the latest version.
    .DESCRIPTION
        Updates Chocolatey itself to the latest version.
    #>
    function Update-ChocoSelf {
        [CmdletBinding()]
        param()
        
        & choco upgrade chocolatey -y
    }
    Set-Alias -Name choselfupdate -Value Update-ChocoSelf -ErrorAction SilentlyContinue

    # Chocolatey cleanup - clean cache
    <#
    .SYNOPSIS
        Cleans up Chocolatey cache.
    .DESCRIPTION
        Removes cached package files from Chocolatey's download cache.
        This helps free up disk space by removing downloaded installers.
        Note: Chocolatey doesn't have a built-in command to remove old package versions
        from the lib directory. Old versions can be manually removed from
        C:\ProgramData\chocolatey\lib if needed.
    .PARAMETER Yes
        Auto-confirm all prompts.
    .EXAMPLE
        Clear-ChocoCache
        Cleans the download cache.
    #>
    function Clear-ChocoCache {
        [CmdletBinding()]
        param(
            [switch]$Yes
        )
        
        $args = @()
        if ($Yes) {
            $args += '-y'
        }
        
        & choco clean @args
    }
    Set-Alias -Name chocleanup -Value Clear-ChocoCache -ErrorAction SilentlyContinue
    Set-Alias -Name choclean -Value Clear-ChocoCache -ErrorAction SilentlyContinue

    # Chocolatey search - search for packages
    <#
    .SYNOPSIS
        Searches for Chocolatey packages.
    .DESCRIPTION
        Searches for available packages in Chocolatey repositories.
    .PARAMETER Query
        Search query string.
    .PARAMETER Exact
        Search for exact package name match.
    .EXAMPLE
        Find-ChocoPackage git
        Searches for packages containing "git".
    .EXAMPLE
        Find-ChocoPackage git -Exact
        Searches for exact package name "git".
    #>
    function Find-ChocoPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Query,
            [switch]$Exact
        )
        
        $args = @('search')
        if ($Exact) {
            $args += '--exact'
        }
        & choco @args @Query
    }
    Set-Alias -Name chosearch -Value Find-ChocoPackage -ErrorAction SilentlyContinue
    Set-Alias -Name chofind -Value Find-ChocoPackage -ErrorAction SilentlyContinue

    # Chocolatey list - list installed packages
    <#
    .SYNOPSIS
        Lists installed Chocolatey packages.
    .DESCRIPTION
        Shows all packages currently installed via Chocolatey.
    .PARAMETER LocalOnly
        Show only locally installed packages (default).
    .PARAMETER IncludePrograms
        Include programs installed outside of Chocolatey.
    .EXAMPLE
        Get-ChocoPackage
        Lists all installed Chocolatey packages.
    #>
    function Get-ChocoPackage {
        [CmdletBinding()]
        param(
            [switch]$LocalOnly,
            [switch]$IncludePrograms
        )
        
        $args = @('list', '--local-only')
        if ($IncludePrograms) {
            $args = @('list')
        }
        & choco @args
    }
    Set-Alias -Name cholist -Value Get-ChocoPackage -ErrorAction SilentlyContinue

    # Chocolatey info - show package information
    <#
    .SYNOPSIS
        Shows information about Chocolatey packages.
    .DESCRIPTION
        Displays detailed information about specified packages, including version, description, and dependencies.
    .PARAMETER Packages
        Package names to get information for.
    .PARAMETER Source
        Source to search in.
    .EXAMPLE
        Get-ChocoPackageInfo git
        Shows detailed information about the git package.
    .EXAMPLE
        Get-ChocoPackageInfo git, vscode
        Shows information for multiple packages.
    #>
    function Get-ChocoPackageInfo {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [string]$Source
        )
        
        $args = @('info')
        if ($Source) {
            $args += '--source', $Source
        }
        & choco @args @Packages
    }
    Set-Alias -Name choinfo -Value Get-ChocoPackageInfo -ErrorAction SilentlyContinue

    # Chocolatey export - backup installed packages
    <#
    .SYNOPSIS
        Exports installed Chocolatey packages to a backup file.
    .DESCRIPTION
        Creates a packages.config file containing all installed Chocolatey packages.
        This file can be used to restore packages on another system or after a reinstall.
    .PARAMETER Path
        Path to save the export file. Defaults to "packages.config" in current directory.
    .PARAMETER IncludeVersions
        Include version numbers in the export file.
    .PARAMETER ExcludeDependencies
        Exclude dependencies from the export (only top-level packages).
    .EXAMPLE
        Export-ChocoPackages
        Exports packages to packages.config in current directory.
    .EXAMPLE
        Export-ChocoPackages -Path "C:\backup\choco-packages.config"
        Exports packages to a specific file.
    .EXAMPLE
        Export-ChocoPackages -IncludeVersions
        Exports packages with version numbers included.
    #>
    function Export-ChocoPackages {
        [CmdletBinding()]
        param(
            [string]$Path = 'packages.config',
            [switch]$IncludeVersions,
            [switch]$ExcludeDependencies
        )
        
        $args = @('export', '-o', $Path)
        if ($IncludeVersions) {
            $args += '--include-version-numbers'
        }
        & choco @args
    }
    Set-Alias -Name choexport -Value Export-ChocoPackages -ErrorAction SilentlyContinue
    Set-Alias -Name chobackup -Value Export-ChocoPackages -ErrorAction SilentlyContinue

    # Chocolatey import - restore packages from backup
    <#
    .SYNOPSIS
        Restores Chocolatey packages from a backup file.
    .DESCRIPTION
        Installs all packages listed in a packages.config file.
        This is useful for restoring packages after a system reinstall or on a new machine.
    .PARAMETER Path
        Path to the packages.config file to import. Defaults to "packages.config" in current directory.
    .PARAMETER Yes
        Auto-confirm all prompts.
    .EXAMPLE
        Import-ChocoPackages
        Restores packages from packages.config in current directory.
    .EXAMPLE
        Import-ChocoPackages -Path "C:\backup\choco-packages.config"
        Restores packages from a specific file.
    #>
    function Import-ChocoPackages {
        [CmdletBinding()]
        param(
            [string]$Path = 'packages.config',
            [switch]$Yes
        )
        
        if (-not (Test-Path -LiteralPath $Path)) {
            Write-Error "Package file not found: $Path"
            return
        }
        
        $args = @('install', $Path)
        if ($Yes) {
            $args += '-y'
        }
        & choco @args
    }
    Set-Alias -Name choimport -Value Import-ChocoPackages -ErrorAction SilentlyContinue
    Set-Alias -Name chorestore -Value Import-ChocoPackages -ErrorAction SilentlyContinue
}
else {
    Write-MissingToolWarning -Tool 'choco' -InstallHint 'Install from: https://chocolatey.org/install'
}
