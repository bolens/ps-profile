# ===============================================
# bun.ps1
# Bun JavaScript runtime helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development

<#
.SYNOPSIS
    Bun JavaScript runtime helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Bun operations.
    Functions check for bun availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Bun
    Author: PowerShell Profile
#>

# Bun execute - run bunx with arguments
<#
.SYNOPSIS
    Executes packages using bunx.

.DESCRIPTION
    Wrapper for bunx command that runs packages without installing them globally.

.PARAMETER Arguments
    Arguments to pass to bunx.

.EXAMPLE
    Invoke-Bunx create next-app

.EXAMPLE
    Invoke-Bunx --version
#>
function Invoke-Bunx {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand bun) {
        & bunx @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'bun' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install bun'
        }
        Write-MissingToolWarning -Tool 'bun' -InstallHint $installHint
    }
}

# Bun run script - execute npm scripts with bun
<#
.SYNOPSIS
    Runs npm scripts using Bun.

.DESCRIPTION
    Wrapper for bun run command.

.PARAMETER Arguments
    Arguments to pass to bun run.

.EXAMPLE
    Invoke-BunRun build

.EXAMPLE
    Invoke-BunRun dev
#>
function Invoke-BunRun {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand bun) {
        & bun run @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'bun' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install bun'
        }
        Write-MissingToolWarning -Tool 'bun' -InstallHint $installHint
    }
}

# Bun add package - install npm packages with bun
<#
.SYNOPSIS
    Adds packages using Bun.

.DESCRIPTION
    Wrapper for bun add command.

.PARAMETER Arguments
    Arguments to pass to bun add.

.EXAMPLE
    Add-BunPackage express

.EXAMPLE
    Add-BunPackage -D typescript
#>
function Add-BunPackage {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand bun) {
        & bun add @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'bun' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install bun'
        }
        Write-MissingToolWarning -Tool 'bun' -InstallHint $installHint
    }
}

# Bun upgrade - update Bun itself
<#
.SYNOPSIS
    Updates Bun to the latest version.
.DESCRIPTION
    Updates Bun itself to the latest version using 'bun upgrade'.
.EXAMPLE
    Update-BunSelf
    Updates Bun to the latest version.
#>
function Update-BunSelf {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand bun) {
        & bun upgrade
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'bun' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install bun'
        }
        Write-MissingToolWarning -Tool 'bun' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'bunx' -Target 'Invoke-Bunx'
    Set-AgentModeAlias -Name 'bun-run' -Target 'Invoke-BunRun'
    Set-AgentModeAlias -Name 'bun-add' -Target 'Add-BunPackage'
    Set-AgentModeAlias -Name 'bun-remove' -Target 'Remove-BunPackage'
    Set-AgentModeAlias -Name 'bun-upgrade' -Target 'Update-BunSelf'
}
else {
    Set-Alias -Name 'bunx' -Value 'Invoke-Bunx' -ErrorAction SilentlyContinue
    Set-Alias -Name 'bun-run' -Value 'Invoke-BunRun' -ErrorAction SilentlyContinue
    Set-Alias -Name 'bun-add' -Value 'Add-BunPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'bun-remove' -Value 'Remove-BunPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'bun-upgrade' -Value 'Update-BunSelf' -ErrorAction SilentlyContinue
}

# Bun remove package - remove npm packages
<#
.SYNOPSIS
    Removes packages using Bun.
.DESCRIPTION
    Wrapper for bun remove command. Supports --global flag.
.PARAMETER Packages
    Package names to remove.
.PARAMETER Global
    Remove from global packages (--global).
.EXAMPLE
    Remove-BunPackage express
    Removes express from production dependencies.
.EXAMPLE
    Remove-BunPackage typescript -Dev
    Removes typescript from dev dependencies.
.EXAMPLE
    Remove-BunPackage nodemon -Global
    Removes nodemon from global packages.
#>
function Remove-BunPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
        [string[]]$Packages,
        [switch]$Global
    )
    
    if (Test-CachedCommand bun) {
        $args = @()
        if ($Global) {
            $args += '--global'
        }
        & bun remove @args @Packages
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'bun' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install bun'
        }
        Write-MissingToolWarning -Tool 'bun' -InstallHint $installHint
    }
}

# Create aliases for Remove-BunPackage
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'bun-remove' -Target 'Remove-BunPackage'
}
else {
    Set-Alias -Name 'bun-remove' -Value 'Remove-BunPackage' -ErrorAction SilentlyContinue
}

# Bun upgrade - update Bun itself
<#
.SYNOPSIS
    Updates Bun to the latest version.
.DESCRIPTION
    Updates Bun itself to the latest version using 'bun upgrade'.
.EXAMPLE
    Update-BunSelf
    Updates Bun to the latest version.
#>
function Update-BunSelf {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand bun) {
        & bun upgrade
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'bun' -ToolType 'node-package'
        }
        else {
            'Install with: scoop install bun'
        }
        Write-MissingToolWarning -Tool 'bun' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'bunx' -Target 'Invoke-Bunx'
    Set-AgentModeAlias -Name 'bun-run' -Target 'Invoke-BunRun'
    Set-AgentModeAlias -Name 'bun-add' -Target 'Add-BunPackage'
    Set-AgentModeAlias -Name 'bun-remove' -Target 'Remove-BunPackage'
    Set-AgentModeAlias -Name 'bun-upgrade' -Target 'Update-BunSelf'
}
else {
    Set-Alias -Name 'bunx' -Value 'Invoke-Bunx' -ErrorAction SilentlyContinue
    Set-Alias -Name 'bun-run' -Value 'Invoke-BunRun' -ErrorAction SilentlyContinue
    Set-Alias -Name 'bun-add' -Value 'Add-BunPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'bun-remove' -Value 'Remove-BunPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'bun-upgrade' -Value 'Update-BunSelf' -ErrorAction SilentlyContinue
}
