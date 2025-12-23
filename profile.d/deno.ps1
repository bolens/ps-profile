# ===============================================
# deno.ps1
# Deno JavaScript runtime helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Deno JavaScript runtime helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Deno operations.
    Functions check for deno availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Deno
    Author: PowerShell Profile
#>

# Deno execute - run deno with arguments
<#
.SYNOPSIS
    Executes Deno commands.

.DESCRIPTION
    Wrapper function for Deno CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to deno.

.EXAMPLE
    Invoke-Deno --version

.EXAMPLE
    Invoke-Deno run app.ts
#>
function Invoke-Deno {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand deno) {
        & deno @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'deno' -ToolType 'node-package' -DefaultInstallCommand 'scoop install deno'
        }
        else {
            'Install with: scoop install deno'
        }
        Write-MissingToolWarning -Tool 'deno' -InstallHint $installHint
    }
}

# Deno run - execute Deno scripts
<#
.SYNOPSIS
    Runs Deno scripts.

.DESCRIPTION
    Wrapper for deno run command.

.PARAMETER Arguments
    Arguments to pass to deno run.

.EXAMPLE
    Invoke-DenoRun app.ts

.EXAMPLE
    Invoke-DenoRun --allow-net server.ts
#>
function Invoke-DenoRun {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand deno) {
        & deno run @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'deno' -ToolType 'node-package' -DefaultInstallCommand 'scoop install deno'
        }
        else {
            'Install with: scoop install deno'
        }
        Write-MissingToolWarning -Tool 'deno' -InstallHint $installHint
    }
}

# Deno task - run defined tasks from deno.json
<#
.SYNOPSIS
    Runs Deno tasks.

.DESCRIPTION
    Wrapper for deno task command to run tasks defined in deno.json.

.PARAMETER Arguments
    Arguments to pass to deno task.

.EXAMPLE
    Invoke-DenoTask dev

.EXAMPLE
    Invoke-DenoTask build
#>
function Invoke-DenoTask {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand deno) {
        & deno task @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'deno' -ToolType 'node-package' -DefaultInstallCommand 'scoop install deno'
        }
        else {
            'Install with: scoop install deno'
        }
        Write-MissingToolWarning -Tool 'deno' -InstallHint $installHint
    }
}

# Deno upgrade - update Deno itself
<#
.SYNOPSIS
    Updates Deno to the latest version.
.DESCRIPTION
    Updates Deno itself to the latest version using 'deno upgrade'.
.EXAMPLE
    Update-DenoSelf
    Updates Deno to the latest version.
#>
function Update-DenoSelf {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand deno) {
        & deno upgrade
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'deno' -ToolType 'node-package' -DefaultInstallCommand 'scoop install deno'
        }
        else {
            'Install with: scoop install deno'
        }
        Write-MissingToolWarning -Tool 'deno' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'deno' -Target 'Invoke-Deno'
    Set-AgentModeAlias -Name 'deno-run' -Target 'Invoke-DenoRun'
    Set-AgentModeAlias -Name 'deno-task' -Target 'Invoke-DenoTask'
    Set-AgentModeAlias -Name 'deno-upgrade' -Target 'Update-DenoSelf'
}
else {
    Set-Alias -Name 'deno' -Value 'Invoke-Deno' -ErrorAction SilentlyContinue
    Set-Alias -Name 'deno-run' -Value 'Invoke-DenoRun' -ErrorAction SilentlyContinue
    Set-Alias -Name 'deno-task' -Value 'Invoke-DenoTask' -ErrorAction SilentlyContinue
    Set-Alias -Name 'deno-upgrade' -Value 'Update-DenoSelf' -ErrorAction SilentlyContinue
}
