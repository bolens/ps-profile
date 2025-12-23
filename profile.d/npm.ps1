# ===============================================
# npm.ps1
# NPM Node.js Package Manager Helpers
# ===============================================
# Provides convenient aliases and wrapper functions for npm package manager operations.
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development

if (Test-CachedCommand npm) {
    # NPM install - install packages
    <#
    .SYNOPSIS
        Installs packages using npm.
    .DESCRIPTION
        Installs packages as dependencies. Supports --save-dev, --save-prod, --global flags.
    .PARAMETER Packages
        Package names to install.
    .PARAMETER Dev
        Install as dev dependency (--save-dev).
    .PARAMETER Global
        Install globally (--global).
    .PARAMETER Prod
        Install as production dependency (--save-prod, default).
    .EXAMPLE
        Install-NpmPackage express
        Installs express as a production dependency.
    .EXAMPLE
        Install-NpmPackage typescript -Dev
        Installs typescript as a dev dependency.
    .EXAMPLE
        Install-NpmPackage nodemon -Global
        Installs nodemon globally.
    #>
    function Install-NpmPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Dev,
            [switch]$Global,
            [switch]$Prod
        )
        
        if (Test-CachedCommand npm) {
            $args = @()
            if ($Global) {
                $args += '--global'
            }
            elseif ($Dev) {
                $args += '--save-dev'
            }
            elseif ($Prod) {
                $args += '--save-prod'
            }
            & npm install @args @Packages
        }
        else {
            $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                Get-PreferenceAwareInstallHint -ToolName 'npm' -ToolType 'node-package'
            }
            else {
                'Install with: scoop install nodejs'
            }
            Write-MissingToolWarning -Tool 'npm' -InstallHint $installHint
        }
    }
    Set-Alias -Name npminstall -Value Install-NpmPackage -ErrorAction SilentlyContinue
    Set-Alias -Name npmadd -Value Install-NpmPackage -ErrorAction SilentlyContinue

    # NPM uninstall - remove packages
    <#
    .SYNOPSIS
        Removes packages using npm.
    .DESCRIPTION
        Removes packages from dependencies. Supports --save-dev, --save-prod, --global flags.
    .PARAMETER Packages
        Package names to remove.
    .PARAMETER Dev
        Remove from dev dependencies (--save-dev).
    .PARAMETER Global
        Remove from global packages (--global).
    .PARAMETER Prod
        Remove from production dependencies (--save-prod, default).
    .EXAMPLE
        Remove-NpmPackage express
        Removes express from production dependencies.
    .EXAMPLE
        Remove-NpmPackage typescript -Dev
        Removes typescript from dev dependencies.
    .EXAMPLE
        Remove-NpmPackage nodemon -Global
        Removes nodemon from global packages.
    #>
    function Remove-NpmPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Dev,
            [switch]$Global,
            [switch]$Prod
        )
        
        if (Test-CachedCommand npm) {
            $args = @()
            if ($Global) {
                $args += '--global'
            }
            elseif ($Dev) {
                $args += '--save-dev'
            }
            elseif ($Prod) {
                $args += '--save-prod'
            }
            & npm uninstall @args @Packages
        }
        else {
            $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                Get-PreferenceAwareInstallHint -ToolName 'npm' -ToolType 'node-package'
            }
            else {
                'Install with: scoop install nodejs'
            }
            Write-MissingToolWarning -Tool 'npm' -InstallHint $installHint
        }
    }
    Set-Alias -Name npmuninstall -Value Remove-NpmPackage -ErrorAction SilentlyContinue
    Set-Alias -Name npmremove -Value Remove-NpmPackage -ErrorAction SilentlyContinue

    # NPM outdated - check for outdated packages
    <#
    .SYNOPSIS
        Checks for outdated packages in the current project.
    .DESCRIPTION
        Lists all packages that have newer versions available.
        This is equivalent to running 'npm outdated'.
    #>
    function Test-NpmOutdated {
        [CmdletBinding()]
        param()
        
        if (Test-CachedCommand npm) {
            & npm outdated
        }
        else {
            $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                Get-PreferenceAwareInstallHint -ToolName 'npm' -ToolType 'node-package'
            }
            else {
                'Install with: scoop install nodejs'
            }
            Write-MissingToolWarning -Tool 'npm' -InstallHint $installHint
        }
    }
    Set-Alias -Name npmoutdated -Value Test-NpmOutdated -ErrorAction SilentlyContinue

    # NPM update - update all packages
    <#
    .SYNOPSIS
        Updates all packages in the current project to their latest versions.
    .DESCRIPTION
        Updates all packages to their latest versions according to the version ranges
        specified in package.json. This is equivalent to running 'npm update'.
    #>
    function Update-NpmPackages {
        [CmdletBinding()]
        param()
        
        if (Test-CachedCommand npm) {
            & npm update
        }
        else {
            $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                Get-PreferenceAwareInstallHint -ToolName 'npm' -ToolType 'node-package'
            }
            else {
                'Install with: scoop install nodejs'
            }
            Write-MissingToolWarning -Tool 'npm' -InstallHint $installHint
        }
    }
    Set-Alias -Name npmupdate -Value Update-NpmPackages -ErrorAction SilentlyContinue

    # NPM self-update - update npm itself
    <#
    .SYNOPSIS
        Updates npm to the latest version.
    .DESCRIPTION
        Updates npm itself to the latest version using 'npm install -g npm@latest'.
    #>
    function Update-NpmSelf {
        [CmdletBinding()]
        param()
        
        if (Test-CachedCommand npm) {
            & npm install -g npm@latest
        }
        else {
            $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                Get-PreferenceAwareInstallHint -ToolName 'npm' -ToolType 'node-package'
            }
            else {
                'Install with: scoop install nodejs'
            }
            Write-MissingToolWarning -Tool 'npm' -InstallHint $installHint
        }
    }
    Set-Alias -Name npmupgrade -Value Update-NpmSelf -ErrorAction SilentlyContinue

    # NPM export global - backup global packages
    <#
    .SYNOPSIS
        Exports globally installed npm packages to a backup file.
    .DESCRIPTION
        Creates a package.json file containing all globally installed npm packages.
        This file can be used to restore packages on another system or after a reinstall.
    .PARAMETER Path
        Path to save the export file. Defaults to "npm-global-packages.json" in current directory.
    .EXAMPLE
        Export-NpmGlobalPackages
        Exports global packages to npm-global-packages.json in current directory.
    .EXAMPLE
        Export-NpmGlobalPackages -Path "C:\backup\npm-global.json"
        Exports global packages to a specific file.
    #>
    function Export-NpmGlobalPackages {
        [CmdletBinding()]
        param(
            [string]$Path = 'npm-global-packages.json'
        )
        
        if (Test-CachedCommand npm) {
            $packages = & npm list -g --depth=0 --json 2>$null | ConvertFrom-Json
            if ($packages.dependencies) {
                $export = @{
                    dependencies = @{}
                }
                foreach ($key in $packages.dependencies.PSObject.Properties.Name) {
                    $version = $packages.dependencies.$key.version
                    $export.dependencies[$key] = $version
                }
                $export | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
            }
            else {
                Write-Warning "No global packages found to export."
            }
        }
        else {
            $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                Get-PreferenceAwareInstallHint -ToolName 'npm' -ToolType 'node-package'
            }
            else {
                'Install with: scoop install nodejs'
            }
            Write-MissingToolWarning -Tool 'npm' -InstallHint $installHint
        }
    }
    Set-Alias -Name npmexport -Value Export-NpmGlobalPackages -ErrorAction SilentlyContinue
    Set-Alias -Name npmbackup -Value Export-NpmGlobalPackages -ErrorAction SilentlyContinue

    # NPM import global - restore global packages
    <#
    .SYNOPSIS
        Restores globally installed npm packages from a backup file.
    .DESCRIPTION
        Installs all packages listed in a package.json file as global packages.
        This is useful for restoring packages after a system reinstall or on a new machine.
    .PARAMETER Path
        Path to the package.json file to import. Defaults to "npm-global-packages.json" in current directory.
    .EXAMPLE
        Import-NpmGlobalPackages
        Restores global packages from npm-global-packages.json in current directory.
    .EXAMPLE
        Import-NpmGlobalPackages -Path "C:\backup\npm-global.json"
        Restores global packages from a specific file.
    #>
    function Import-NpmGlobalPackages {
        [CmdletBinding()]
        param(
            [string]$Path = 'npm-global-packages.json'
        )
        
        if (-not (Test-Path -LiteralPath $Path)) {
            Write-Error "Package file not found: $Path"
            return
        }
        
        if (Test-CachedCommand npm) {
            $json = Get-Content -Path $Path -Raw | ConvertFrom-Json
            if ($json.dependencies) {
                foreach ($package in $json.dependencies.PSObject.Properties) {
                    $packageName = $package.Name
                    $packageVersion = $package.Value
                    Write-Verbose "Installing $packageName@$packageVersion"
                    & npm install -g "${packageName}@${packageVersion}"
                }
            }
        }
        else {
            $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                Get-PreferenceAwareInstallHint -ToolName 'npm' -ToolType 'node-package'
            }
            else {
                'Install with: scoop install nodejs'
            }
            Write-MissingToolWarning -Tool 'npm' -InstallHint $installHint
        }
    }
    Set-Alias -Name npmimport -Value Import-NpmGlobalPackages -ErrorAction SilentlyContinue
    Set-Alias -Name npmrestore -Value Import-NpmGlobalPackages -ErrorAction SilentlyContinue
}
else {
    $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        Get-PreferenceAwareInstallHint -ToolName 'npm' -ToolType 'node-package'
    }
    else {
        'Install with: scoop install nodejs'
    }
    Write-MissingToolWarning -Tool 'npm' -InstallHint $installHint
}
