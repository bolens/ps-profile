# ===============================================
# winget.ps1
# Windows Package Manager (winget)
# ===============================================

# Winget aliases and functions
# Requires: winget (Windows Package Manager)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand winget) {
    # Winget upgrade - check for outdated packages
    <#
    .SYNOPSIS
        Lists packages with available upgrades.
    .DESCRIPTION
        Lists all installed packages that have newer versions available.
        This is equivalent to running 'winget upgrade'.
    #>
    function Test-WingetOutdated {
        [CmdletBinding()]
        param()
        
        & winget upgrade
    }
    Set-AgentModeAlias -Name 'winget-outdated' -Target 'Test-WingetOutdated'
    # Winget upgrade all - update all packages
    <#
    .SYNOPSIS
        Updates all winget packages.
    .DESCRIPTION
        Updates all installed packages to their latest versions.
    #>
    function Update-WingetPackages {
        [CmdletBinding()]
        param()
        
        & winget upgrade --all
    }
    Set-AgentModeAlias -Name 'winget-update' -Target 'Update-WingetPackages'
    # Winget install - install packages
    <#
    .SYNOPSIS
        Installs packages using winget.
    .DESCRIPTION
        Installs packages from the winget repository.
    .PARAMETER Packages
        Package IDs or names to install.
    .PARAMETER Version
        Specific version to install (--version).
    .PARAMETER Source
        Source to install from (--source).
    .EXAMPLE
        Install-WingetPackage Microsoft.VisualStudioCode
        Installs Visual Studio Code.
    .EXAMPLE
        Install-WingetPackage Git.Git -Version 2.40.0
        Installs a specific version of Git.
    #>
    function Install-WingetPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [string]$Version,
            [string]$Source
        )
        
        foreach ($package in $Packages) {
            $args = @('install', $package, '--accept-package-agreements', '--accept-source-agreements')
            if ($Version) {
                $args += '--version', $Version
            }
            if ($Source) {
                $args += '--source', $Source
            }
            & winget @args
        }
    }
    Set-AgentModeAlias -Name 'winget-install' -Target 'Install-WingetPackage'
    Set-AgentModeAlias -Name 'winget-add' -Target 'Install-WingetPackage'
    # Winget uninstall - remove packages
    <#
    .SYNOPSIS
        Removes packages using winget.
    .DESCRIPTION
        Uninstalls packages installed via winget.
    .PARAMETER Packages
        Package IDs or names to uninstall.
    .EXAMPLE
        Remove-WingetPackage Microsoft.VisualStudioCode
        Uninstalls Visual Studio Code.
    #>
    function Remove-WingetPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages
        )
        
        foreach ($package in $Packages) {
            & winget uninstall $package --accept-source-agreements
        }
    }
    Set-AgentModeAlias -Name 'winget-uninstall' -Target 'Remove-WingetPackage'
    Set-AgentModeAlias -Name 'winget-remove' -Target 'Remove-WingetPackage'
    # Winget cleanup - clean cache
    <#
    .SYNOPSIS
        Cleans up winget cache.
    .DESCRIPTION
        Removes cached installer packages from winget's cache directory.
        This helps free up disk space by removing downloaded installers.
    .EXAMPLE
        Clear-WingetCache
        Cleans the winget cache.
    #>
    function Clear-WingetCache {
        [CmdletBinding()]
        param()
        
        & winget cache clean
    }
    Set-AgentModeAlias -Name 'winget-cleanup' -Target 'Clear-WingetCache'
    Set-AgentModeAlias -Name 'winget-clean' -Target 'Clear-WingetCache'
    # Winget search - search for packages
    <#
    .SYNOPSIS
        Searches for winget packages.
    .DESCRIPTION
        Searches for available packages in the winget repository.
    .PARAMETER Query
        Search query string.
    .PARAMETER Exact
        Search for exact package ID match.
    .PARAMETER Source
        Source to search in.
    .EXAMPLE
        Find-WingetPackage git
        Searches for packages containing "git".
    .EXAMPLE
        Find-WingetPackage Git.Git -Exact
        Searches for exact package ID "Git.Git".
    #>
    function Find-WingetPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Query,
            [switch]$Exact,
            [string]$Source
        )
        
        $args = @('search')
        if ($Exact) {
            $args += '--exact'
        }
        if ($Source) {
            $args += '--source', $Source
        }
        & winget @args @Query
    }
    Set-AgentModeAlias -Name 'winget-search' -Target 'Find-WingetPackage'
    Set-AgentModeAlias -Name 'winget-find' -Target 'Find-WingetPackage'
    # Winget list - list installed packages
    <#
    .SYNOPSIS
        Lists installed winget packages.
    .DESCRIPTION
        Shows all packages currently installed via winget.
    .PARAMETER Source
        Filter by source.
    .EXAMPLE
        Get-WingetPackage
        Lists all installed winget packages.
    #>
    function Get-WingetPackage {
        [CmdletBinding()]
        param(
            [string]$Source
        )
        
        $args = @('list')
        if ($Source) {
            $args += '--source', $Source
        }
        & winget @args
    }
    Set-AgentModeAlias -Name 'winget-list' -Target 'Get-WingetPackage'
    # Winget show - show package information
    <#
    .SYNOPSIS
        Shows information about winget packages.
    .DESCRIPTION
        Displays detailed information about specified packages, including version, description, publisher, and available versions.
    .PARAMETER Packages
        Package IDs or names to get information for.
    .PARAMETER Version
        Show information for a specific version.
    .PARAMETER Source
        Source to search in.
    .EXAMPLE
        Get-WingetPackageInfo Git.Git
        Shows detailed information about the Git.Git package.
    .EXAMPLE
        Get-WingetPackageInfo Microsoft.VisualStudioCode
        Shows information for Visual Studio Code.
    #>
    function Get-WingetPackageInfo {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [string]$Version,
            [string]$Source
        )
        
        foreach ($package in $Packages) {
            $args = @('show', $package)
            if ($Version) {
                $args += '--version', $Version
            }
            if ($Source) {
                $args += '--source', $Source
            }
            & winget @args
        }
    }
    Set-AgentModeAlias -Name 'winget-show' -Target 'Get-WingetPackageInfo'
    Set-AgentModeAlias -Name 'winget-info' -Target 'Get-WingetPackageInfo'
    # Winget export - backup installed packages
    <#
    .SYNOPSIS
        Exports installed winget packages to a backup file.
    .DESCRIPTION
        Creates a JSON file containing all installed winget packages.
        This file can be used to restore packages on another system or after a reinstall.
    .PARAMETER Path
        Path to save the export file. Defaults to "winget-packages.json" in current directory.
    .PARAMETER Source
        Export packages from a specific source only.
    .EXAMPLE
        Export-WingetPackages
        Exports packages to winget-packages.json in current directory.
    .EXAMPLE
        Export-WingetPackages -Path "C:\backup\winget-backup.json"
        Exports packages to a specific file.
    #>
    function Export-WingetPackages {
        [CmdletBinding()]
        param(
            [string]$Path = 'winget-packages.json',
            [string]$Source
        )
        
        $args = @('export', '-o', $Path)
        if ($Source) {
            $args += '--source', $Source
        }
        & winget @args
    }
    Set-AgentModeAlias -Name 'winget-export' -Target 'Export-WingetPackages'
    Set-AgentModeAlias -Name 'winget-backup' -Target 'Export-WingetPackages'
    # Winget import - restore packages from backup
    <#
    .SYNOPSIS
        Restores winget packages from a backup file.
    .DESCRIPTION
        Installs all packages listed in a JSON export file.
        This is useful for restoring packages after a system reinstall or on a new machine.
    .PARAMETER Path
        Path to the JSON file to import. Defaults to "winget-packages.json" in current directory.
    .PARAMETER IgnoreUnavailable
        Skip packages that are not available in the repository.
    .PARAMETER IgnoreVersions
        Install latest versions instead of the versions specified in the export file.
    .EXAMPLE
        Import-WingetPackages
        Restores packages from winget-packages.json in current directory.
    .EXAMPLE
        Import-WingetPackages -Path "C:\backup\winget-backup.json"
        Restores packages from a specific file.
    .EXAMPLE
        Import-WingetPackages -IgnoreUnavailable
        Restores packages, skipping any that are no longer available.
    #>
    function Import-WingetPackages {
        [CmdletBinding()]
        param(
            [string]$Path = 'winget-packages.json',
            [switch]$IgnoreUnavailable,
            [switch]$IgnoreVersions
        )
        
        if (-not (Test-Path -LiteralPath $Path)) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.IO.FileNotFoundException]::new("Package file not found: $Path"),
                        'PackageFileNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $Path
                    )) -OperationName 'winget.packages.import' -Context @{ path = $Path }
            }
            else {
                Write-Error "Package file not found: $Path"
            }
            return
        }
        
        $args = @('import', '-i', $Path, '--accept-package-agreements', '--accept-source-agreements')
        if ($IgnoreUnavailable) {
            $args += '--ignore-unavailable'
        }
        if ($IgnoreVersions) {
            $args += '--ignore-versions'
        }
        
        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'winget.packages.import' -Context @{
                path               = $Path
                ignore_unavailable = $IgnoreUnavailable.IsPresent
                ignore_versions    = $IgnoreVersions.IsPresent
            } -ScriptBlock {
                & winget @args
            } | Out-Null
        }
        else {
            & winget @args
        }
    }
    Set-AgentModeAlias -Name 'winget-import' -Target 'Import-WingetPackages'
    Set-AgentModeAlias -Name 'winget-restore' -Target 'Import-WingetPackages'
}
else {
    Write-MissingToolWarning -Tool 'winget' -InstallHint 'Winget is included with Windows 10/11. If missing, install from: https://aka.ms/getwinget'
}
