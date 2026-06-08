# ===============================================
# pnpm.ps1
# Fast package manager with pnpm
# ===============================================

# PNPM aliases
# Requires: pnpm (https://pnpm.io/)
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development

if (Test-CachedCommand pnpm) {
    # PNPM as npm replacement
    Set-Alias -Name npm -Value pnpm -Option AllScope -Force
    Set-Alias -Name yarn -Value pnpm -Option AllScope -Force

    # Common pnpm commands
    # Note: Invoke-PnpmInstall with flag support is defined later in this file

    <#
.SYNOPSIS
        Installs development packages using pnpm.
    .DESCRIPTION
        Adds packages as dev dependencies to the project using pnpm.
.EXAMPLE
    Invoke-PnpmDevInstall typescript eslint
.PARAMETER Packages
    Package names to add as development dependencies.

#>
    function Invoke-PnpmDevInstall {
        param([string[]]$Packages)
        pnpm add -D @Packages
    }
    Set-Alias -Name pndev -Value Invoke-PnpmDevInstall -Option AllScope -Force

    <#
.SYNOPSIS
        Runs npm scripts using pnpm.
    .DESCRIPTION
        Executes package.json scripts using pnpm instead of npm.
.EXAMPLE
    Invoke-PnpmRun -Script build -Args @('--watch')
.PARAMETER Script
    package.json script name to execute.
.PARAMETER Args
    Additional arguments forwarded to the script command.

#>
    function Invoke-PnpmRun {
        param([string]$Script, [string[]]$Args)
        pnpm run $Script @Args
    }
    Set-Alias -Name pnrun -Value Invoke-PnpmRun -Option AllScope -Force

    # PNPM outdated - check for outdated packages
    <#
    .SYNOPSIS
        Checks for outdated packages in the current project.
    .DESCRIPTION
        Lists all packages that have newer versions available.
        This is equivalent to running 'pnpm outdated'.
    .EXAMPLE
        Test-PnpmOutdated
        Checks for outdated packages in the current project.
    #>
    function Test-PnpmOutdated {
        [CmdletBinding()]
        param()
        
        if (Test-CachedCommand pnpm) {
            & pnpm outdated
        }
        else {
            Invoke-MissingToolWarning -ToolName 'pnpm' -ToolType 'node-package'
        }
    }
    Set-Alias -Name pnoutdated -Value Test-PnpmOutdated -Option AllScope -Force

    # PNPM update - update all packages
    <#
    .SYNOPSIS
        Updates all packages in the current project to their latest versions.
    .DESCRIPTION
        Updates all packages to their latest versions according to the version ranges
        specified in package.json. This is equivalent to running 'pnpm update'.
    .EXAMPLE
        Update-PnpmPackages
        Updates all packages in the current project.
    #>
    function Update-PnpmPackages {
        [CmdletBinding()]
        param()
        
        if (Test-CachedCommand pnpm) {
            & pnpm update
        }
        else {
            Invoke-MissingToolWarning -ToolName 'pnpm' -ToolType 'node-package'
        }
    }
    Set-Alias -Name pnupdate -Value Update-PnpmPackages -Option AllScope -Force

    # PNPM self-update - update pnpm itself
    <#
    .SYNOPSIS
        Updates pnpm to the latest version.
    .DESCRIPTION
        Updates pnpm itself to the latest version using 'pnpm add -g pnpm@latest'.
    .EXAMPLE
        Update-PnpmSelf
        Updates pnpm to the latest version.
    #>
    function Update-PnpmSelf {
        [CmdletBinding()]
        param()
        
        if (Test-CachedCommand pnpm) {
            & pnpm add -g pnpm@latest
        }
        else {
            Invoke-MissingToolWarning -ToolName 'pnpm' -ToolType 'node-package'
        }
    }
    Set-Alias -Name pnupgrade -Value Update-PnpmSelf -Option AllScope -Force

    # PNPM remove - remove packages
    <#
    .SYNOPSIS
        Removes packages using pnpm.
    .DESCRIPTION
        Removes packages from dependencies. Supports --save-dev, --save-prod, --global flags.
    .PARAMETER Packages
        Package names to remove.
    .PARAMETER Dev
        Remove from dev dependencies (-D).
    .PARAMETER Global
        Remove from global packages (-g).
    .PARAMETER Prod
        Remove from production dependencies (default).
    .EXAMPLE
        Remove-PnpmPackage express
        Removes express from production dependencies.
    .EXAMPLE
        Remove-PnpmPackage typescript -Dev
        Removes typescript from dev dependencies.
    .EXAMPLE
        Remove-PnpmPackage nodemon -Global
        Removes nodemon from global packages.
    #>
    function Remove-PnpmPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Dev,
            [switch]$Global,
            [switch]$Prod
        )
        
        if (Test-CachedCommand pnpm) {
            $args = @()
            if ($Global) {
                $args += '-g'
            }
            elseif ($Dev) {
                $args += '-D'
            }
            & pnpm remove @args @Packages
        }
        else {
            Invoke-MissingToolWarning -ToolName 'pnpm' -ToolType 'node-package'
        }
    }
    Set-Alias -Name pnremove -Value Remove-PnpmPackage -Option AllScope -Force
    Set-Alias -Name pnuninstall -Value Remove-PnpmPackage -Option AllScope -Force

    # PNPM add - enhance existing function to support flags
    # Update Invoke-PnpmInstall to support dev/global flags
    <#
    .SYNOPSIS
        Installs packages using pnpm.
    .DESCRIPTION
        Adds packages as dependencies to the project using pnpm. Supports -D (dev) and -g (global) flags.
    .PARAMETER Packages
        Package names to install.
    .PARAMETER Dev
        Install as dev dependency (-D).
    .PARAMETER Global
        Install globally (-g).
    .EXAMPLE
        Invoke-PnpmInstall express
        Installs express as a production dependency.
    .EXAMPLE
        Invoke-PnpmInstall typescript -Dev
        Installs typescript as a dev dependency.
    .EXAMPLE
        Invoke-PnpmInstall nodemon -Global
        Installs nodemon globally.
    #>
    function Invoke-PnpmInstall {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Dev,
            [switch]$Global
        )
        
        if (Test-CachedCommand pnpm) {
            $args = @()
            if ($Global) {
                $args += '-g'
            }
            elseif ($Dev) {
                $args += '-D'
            }
            & pnpm add @args @Packages
        }
        else {
            Invoke-MissingToolWarning -ToolName 'pnpm' -ToolType 'node-package'
        }
    }
    Set-Alias -Name pnadd -Value Invoke-PnpmInstall -Option AllScope -Force

    # PNPM install (alias for Invoke-PnpmInstall)
    <#
    .SYNOPSIS
        Installs dependencies using PNPM.
    .DESCRIPTION
        Installs project dependencies defined in package.json.
    #>
    function Install-PnpmPackage { pnpm install @args }
    Set-AgentModeAlias -Name 'pni' -Target 'Install-PnpmPackage'
    # PNPM add (alias for Invoke-PnpmInstall)
    <#
    .SYNOPSIS
        Adds packages using PNPM.
    .DESCRIPTION
        Adds packages as dependencies to the project.
    #>
    function Add-PnpmPackage { pnpm add @args }
    Set-AgentModeAlias -Name 'pna' -Target 'Add-PnpmPackage'
    # PNPM add dev (alias for Invoke-PnpmDevInstall)
    <#
    .SYNOPSIS
        Adds dev dependencies using PNPM.
    .DESCRIPTION
        Adds packages as development dependencies to the project.
    #>
    function Add-PnpmDevPackage { pnpm add -D @args }
    Set-AgentModeAlias -Name 'pnd' -Target 'Add-PnpmDevPackage'
    # PNPM run (alias for Invoke-PnpmRun)
    <#
    .SYNOPSIS
        Runs scripts using PNPM.
    .DESCRIPTION
        Executes scripts defined in package.json.
    #>
    function Invoke-PnpmScript { pnpm run @args }
    Set-AgentModeAlias -Name 'pnr' -Target 'Invoke-PnpmScript'
    # PNPM start
    <#
    .SYNOPSIS
        Starts the project using PNPM.
    .DESCRIPTION
        Runs the start script defined in package.json.
    #>
    function Start-PnpmProject { pnpm start @args }
    Set-AgentModeAlias -Name 'pns' -Target 'Start-PnpmProject'
    # PNPM build
    <#
    .SYNOPSIS
        Builds the project using PNPM.
    .DESCRIPTION
        Runs the build script defined in package.json.
    #>
    function Build-PnpmProject { pnpm run build @args }
    Set-AgentModeAlias -Name 'pnb' -Target 'Build-PnpmProject'
    # PNPM test
    <#
    .SYNOPSIS
        Runs tests using PNPM.
    .DESCRIPTION
        Runs the test script defined in package.json.
    #>
    function Test-PnpmProject { pnpm run test @args }
    Set-AgentModeAlias -Name 'pnt' -Target 'Test-PnpmProject'
    # PNPM dev - run development server
    <#
    .SYNOPSIS
        Runs development server using PNPM.
    .DESCRIPTION
        Runs the dev script defined in package.json.
    #>
    function Start-PnpmDev { pnpm run dev @args }
    # Note: pndev is already aliased to Invoke-PnpmDevInstall, so we use a different alias
    Set-AgentModeAlias -Name 'pndevserver' -Target 'Start-PnpmDev'
}
else {
    Invoke-MissingToolWarning -ToolName 'pnpm' -ToolType 'node-package'
}
