# ===============================================
# homebrew.ps1
# Homebrew package management (macOS/Linux)
# ===============================================

# Homebrew aliases and functions
# Requires: brew (Homebrew - https://brew.sh/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand brew) {
    # Homebrew install - install packages
    <#
    .SYNOPSIS
        Installs packages using Homebrew.
    .DESCRIPTION
        Installs packages using Homebrew. Supports --cask for GUI applications.
    .PARAMETER Packages
        Package names to install.
    .PARAMETER Cask
        Install as cask (GUI application).
    .EXAMPLE
        Install-BrewPackage git
        Installs git.
    .EXAMPLE
        Install-BrewPackage -Cask visual-studio-code
        Installs Visual Studio Code as a cask.
    #>
    function Install-BrewPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Cask
        )
        
        $args = @()
        if ($Cask) {
            $args += '--cask'
        }
        & brew install @args @Packages
    }
    Set-Alias -Name brewinstall -Value Install-BrewPackage -ErrorAction SilentlyContinue
    Set-Alias -Name brewadd -Value Install-BrewPackage -ErrorAction SilentlyContinue

    # Homebrew uninstall - remove packages
    <#
    .SYNOPSIS
        Removes packages using Homebrew.
    .DESCRIPTION
        Removes packages using Homebrew. Supports --cask for GUI applications.
    .PARAMETER Packages
        Package names to remove.
    .PARAMETER Cask
        Remove cask (GUI application).
    .EXAMPLE
        Remove-BrewPackage git
        Removes git.
    .EXAMPLE
        Remove-BrewPackage -Cask visual-studio-code
        Removes Visual Studio Code cask.
    #>
    function Remove-BrewPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Cask
        )
        
        $args = @()
        if ($Cask) {
            $args += '--cask'
        }
        & brew uninstall @args @Packages
    }
    Set-Alias -Name brewuninstall -Value Remove-BrewPackage -ErrorAction SilentlyContinue
    Set-Alias -Name brewremove -Value Remove-BrewPackage -ErrorAction SilentlyContinue

    # Homebrew outdated - check for outdated packages
    <#
    .SYNOPSIS
        Checks for outdated Homebrew packages.
    .DESCRIPTION
        Lists all installed packages that have newer versions available.
        This is equivalent to running 'brew outdated'.
    #>
    function Test-BrewOutdated {
        [CmdletBinding()]
        param()
        
        & brew outdated
    }
    Set-Alias -Name brewoutdated -Value Test-BrewOutdated -ErrorAction SilentlyContinue

    # Homebrew upgrade - update packages
    <#
    .SYNOPSIS
        Updates Homebrew packages.
    .DESCRIPTION
        Updates specified packages or all packages if no arguments provided.
    .PARAMETER Packages
        Package names to update (optional, updates all if omitted).
    .EXAMPLE
        Update-BrewPackages
        Updates all packages.
    .EXAMPLE
        Update-BrewPackages git
        Updates git package.
    #>
    function Update-BrewPackages {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Packages
        )
        
        if ($Packages) {
            & brew upgrade @Packages
        }
        else {
            & brew upgrade
        }
    }
    Set-Alias -Name brewupgrade -Value Update-BrewPackages -ErrorAction SilentlyContinue
    Set-Alias -Name brewupdate -Value Update-BrewPackages -ErrorAction SilentlyContinue

    # Homebrew update - update Homebrew itself
    <#
    .SYNOPSIS
        Updates Homebrew to the latest version.
    .DESCRIPTION
        Updates Homebrew itself and package lists.
    #>
    function Update-BrewSelf {
        [CmdletBinding()]
        param()
        
        & brew update
    }
    Set-Alias -Name brewselfupdate -Value Update-BrewSelf -ErrorAction SilentlyContinue

    # Homebrew cleanup - clean cache and old versions
    <#
    .SYNOPSIS
        Cleans up Homebrew cache and old package versions.
    .DESCRIPTION
        Removes old versions of installed formulae and cleans the download cache.
        This helps free up disk space by removing outdated package versions and cached downloads.
    .PARAMETER Formula
        Specific formula to clean up (optional).
    .PARAMETER Scrub
        Scrub the cache, removing downloads for even the latest versions of formulae.
    .PARAMETER Prune
        Remove all cache files older than the specified number of days.
    .PARAMETER DryRun
        Show what would be removed without actually deleting anything.
    .EXAMPLE
        Clear-BrewCache
        Cleans up old versions and cache for all formulae.
    .EXAMPLE
        Clear-BrewCache -Formula git
        Cleans up old versions and cache for git formula only.
    .EXAMPLE
        Clear-BrewCache -Scrub
        Removes all cache files, including those for latest versions.
    .EXAMPLE
        Clear-BrewCache -Prune 30
        Removes cache files older than 30 days.
    .EXAMPLE
        Clear-BrewCache -DryRun
        Shows what would be removed without deleting.
    #>
    function Clear-BrewCache {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Formula,
            [switch]$Scrub,
            [int]$Prune,
            [switch]$DryRun
        )
        
        $args = @('cleanup')
        
        if ($DryRun) {
            $args += '-n'
        }
        
        if ($Scrub) {
            $args += '-s'
        }
        
        if ($Prune -gt 0) {
            $args += "--prune=$Prune"
        }
        
        if ($Formula) {
            $args += $Formula
        }
        
        & brew @args
    }
    Set-Alias -Name brewcleanup -Value Clear-BrewCache -ErrorAction SilentlyContinue
    Set-Alias -Name brewclean -Value Clear-BrewCache -ErrorAction SilentlyContinue

    # Homebrew search - search for packages
    <#
    .SYNOPSIS
        Searches for Homebrew packages.
    .DESCRIPTION
        Searches for available packages in Homebrew repositories.
    .PARAMETER Query
        Search query string.
    .PARAMETER Cask
        Search for casks (GUI applications) instead of formulae.
    .EXAMPLE
        Find-BrewPackage git
        Searches for packages containing "git".
    .EXAMPLE
        Find-BrewPackage visual-studio-code -Cask
        Searches for casks containing "visual-studio-code".
    #>
    function Find-BrewPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Query,
            [switch]$Cask
        )
        
        $args = @('search')
        if ($Cask) {
            $args += '--cask'
        }
        & brew @args @Query
    }
    Set-Alias -Name brewsearch -Value Find-BrewPackage -ErrorAction SilentlyContinue
    Set-Alias -Name brewfind -Value Find-BrewPackage -ErrorAction SilentlyContinue

    # Homebrew list - list installed packages
    <#
    .SYNOPSIS
        Lists installed Homebrew packages.
    .DESCRIPTION
        Shows all packages currently installed via Homebrew.
    .PARAMETER Cask
        List casks (GUI applications) instead of formulae.
    .PARAMETER Versions
        Show installed versions for each package.
    .EXAMPLE
        Get-BrewPackage
        Lists all installed Homebrew formulae.
    .EXAMPLE
        Get-BrewPackage -Cask
        Lists all installed casks.
    .EXAMPLE
        Get-BrewPackage -Versions
        Lists formulae with their installed versions.
    #>
    function Get-BrewPackage {
        [CmdletBinding()]
        param(
            [switch]$Cask,
            [switch]$Versions
        )
        
        $args = @('list')
        if ($Cask) {
            $args += '--cask'
        }
        if ($Versions) {
            $args += '--versions'
        }
        & brew @args
    }
    Set-Alias -Name brewlist -Value Get-BrewPackage -ErrorAction SilentlyContinue

    # Homebrew info - show package information
    <#
    .SYNOPSIS
        Shows information about Homebrew packages.
    .DESCRIPTION
        Displays detailed information about specified packages, including version, description, dependencies, and installation status.
    .PARAMETER Packages
        Package names to get information for.
    .PARAMETER Cask
        Get information for casks (GUI applications) instead of formulae.
    .EXAMPLE
        Get-BrewPackageInfo git
        Shows detailed information about the git package.
    .EXAMPLE
        Get-BrewPackageInfo visual-studio-code -Cask
        Shows information for the Visual Studio Code cask.
    #>
    function Get-BrewPackageInfo {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Cask
        )
        
        $args = @('info')
        if ($Cask) {
            $args += '--cask'
        }
        & brew @args @Packages
    }
    Set-Alias -Name brewinfo -Value Get-BrewPackageInfo -ErrorAction SilentlyContinue

    # Homebrew bundle dump - backup installed packages
    <#
    .SYNOPSIS
        Exports installed Homebrew packages to a Brewfile.
    .DESCRIPTION
        Creates a Brewfile containing all installed Homebrew formulae, casks, and taps.
        This file can be used to restore packages on another system or after a reinstall.
    .PARAMETER Path
        Path to save the Brewfile. Defaults to "Brewfile" in current directory.
    .PARAMETER Describe
        Include descriptions for each package in the Brewfile.
    .PARAMETER Force
        Overwrite existing Brewfile if it exists.
    .EXAMPLE
        Export-BrewPackages
        Exports packages to Brewfile in current directory.
    .EXAMPLE
        Export-BrewPackages -Path "~/backup/Brewfile"
        Exports packages to a specific file.
    .EXAMPLE
        Export-BrewPackages -Describe
        Exports packages with descriptions included.
    #>
    function Export-BrewPackages {
        [CmdletBinding()]
        param(
            [string]$Path = 'Brewfile',
            [switch]$Describe,
            [switch]$Force
        )
        
        $args = @('bundle', 'dump', '--file', $Path)
        if ($Describe) {
            $args += '--describe'
        }
        if ($Force) {
            $args += '--force'
        }
        & brew @args
    }
    Set-Alias -Name brewexport -Value Export-BrewPackages -ErrorAction SilentlyContinue
    Set-Alias -Name brewbackup -Value Export-BrewPackages -ErrorAction SilentlyContinue

    # Homebrew bundle - restore packages from backup
    <#
    .SYNOPSIS
        Restores Homebrew packages from a Brewfile.
    .DESCRIPTION
        Installs all packages listed in a Brewfile.
        This is useful for restoring packages after a system reinstall or on a new machine.
    .PARAMETER Path
        Path to the Brewfile to import. Defaults to "Brewfile" in current directory.
    .PARAMETER NoLock
        Don't update the Brewfile.lock.json file.
    .PARAMETER NoUpgrade
        Don't run brew upgrade for outdated packages.
    .EXAMPLE
        Import-BrewPackages
        Restores packages from Brewfile in current directory.
    .EXAMPLE
        Import-BrewPackages -Path "~/backup/Brewfile"
        Restores packages from a specific file.
    #>
    function Import-BrewPackages {
        [CmdletBinding()]
        param(
            [string]$Path = 'Brewfile',
            [switch]$NoLock,
            [switch]$NoUpgrade
        )
        
        if (-not (Test-Path -LiteralPath $Path)) {
            Write-Error "Brewfile not found: $Path"
            return
        }
        
        $args = @('bundle', '--file', $Path)
        if ($NoLock) {
            $args += '--no-lock'
        }
        if ($NoUpgrade) {
            $args += '--no-upgrade'
        }
        & brew @args
    }
    Set-Alias -Name brewimport -Value Import-BrewPackages -ErrorAction SilentlyContinue
    Set-Alias -Name brewrestore -Value Import-BrewPackages -ErrorAction SilentlyContinue
}
else {
    Write-MissingToolWarning -Tool 'brew' -InstallHint 'Install from: https://brew.sh/'
}
