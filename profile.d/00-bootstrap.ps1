# ===============================================
# 00-bootstrap.ps1
# Bootstrap helpers for profile fragments
#
# Purpose: define small, collision-safe helpers used by other `profile.d` files
# so fragments can register functions/aliases without accidentally overwriting
# existing user or module commands.
#
# This file is intentionally loaded first (prefix `00-`) so other fragments
# can rely on these helpers. It's idempotent and will not overwrite existing
# helpers if already defined.
# ===============================================

# Collision-safe function creator for profile fragments
if (-not (Test-Path "Function:\\global:Set-AgentModeFunction")) {
    <#
    .SYNOPSIS
        Creates collision-safe functions for profile fragments.
    .DESCRIPTION
        Defines a helper function that creates small convenience functions or wrappers
        without overwriting existing user or module commands. Used by profile fragments
        to safely register functions.
    #>
    function Set-AgentModeFunction {
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory)] [string]$Name,
            [Parameter(Mandatory)] [scriptblock]$Body,
            [switch]$ReturnScriptBlock
        )
        # Don't overwrite existing commands
        if (Get-Command -Name $Name -ErrorAction SilentlyContinue) { return $false }

        $funcPath = 'Function:' + $Name
        # Determine debug verbosity: user can opt-in with PS_PROFILE_DEBUG=1
        $dbgEnabled = $false
        try { $dbgEnabled = ($env:PS_PROFILE_DEBUG -eq '1') -or (($env:GITHUB_ACTIONS -eq 'true') -and ($env:PS_PROFILE_DEBUG -ne '0')) } catch { $dbgEnabled = $false }
        if ($dbgEnabled) {
            if ($env:GITHUB_ACTIONS -eq 'true') { Write-Output "DEBUG: Set-AgentModeFunction: creating $Name" } else { Write-Verbose "Set-AgentModeFunction: creating $Name" }
        }
        # Build a ScriptBlock from the provided body. By default the helper
        # does not return the ScriptBlock to avoid emitting values during
        # profile dot-sourcing. Consumers may request the ScriptBlock by
        # specifying -ReturnScriptBlock.
        # Create the function in the global function provider directly, avoiding
        # text-based Invoke-Expression which can be slower and flagged by linters.
        $sb = [scriptblock]::Create($Body.ToString())
        try {
            # Use the Function: drive to create a persistent global function without
            # parsing text. This is more robust and avoids an extra Get-Command call.
            $funcPath = "Function:\global:$Name"
            if (Test-Path $funcPath) {
                if ($dbgEnabled) { Write-Verbose "Set-AgentModeFunction: function $Name already exists in $funcPath" }
                return $false
            }
            if ($PSCmdlet.ShouldProcess("Function '$Name'", "Create")) {
                New-Item -Path $funcPath -Value $sb -Force | Out-Null
                # Verify registration using provider path to avoid module autoload
                if (-not (Test-Path $funcPath)) { throw "Set-AgentModeFunction: unable to register function $Name" }
                if ($ReturnScriptBlock) { return $sb } else { return $true }
            }
        }
        catch {
            $err = $_.Exception.Message
            if ($dbgEnabled) { Write-Verbose "Set-AgentModeFunction: creation failed: $err" }
            throw
        }
    }
}

# Collision-safe alias creator for profile fragments
if (-not (Test-Path "Function:\\global:Set-AgentModeAlias")) {
    <#
    .SYNOPSIS
        Creates collision-safe aliases for profile fragments.
    .DESCRIPTION
        Defines a helper function that creates aliases or function wrappers
        without overwriting existing user or module commands. Used by profile fragments
        to safely register aliases.
    #>
    function Set-AgentModeAlias {
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory)] [string]$Name,
            [Parameter(Mandatory)] [string]$Target,
            [switch]$ReturnDefinition
        )
        if (Get-Command -Name $Name -ErrorAction SilentlyContinue) { return $false }
        try {
            # Determine debug verbosity
            $dbgEnabled = $false
            try { $dbgEnabled = ($env:PS_PROFILE_DEBUG -eq '1') -or (($env:GITHUB_ACTIONS -eq 'true') -and ($env:PS_PROFILE_DEBUG -ne '0')) } catch { $dbgEnabled = $false }
            if ($dbgEnabled) { Write-Verbose ("Set-AgentModeAlias: creating global wrapper {0} -> {1}" -f $Name, $Target) }
            # Prefer creating an alias or function using the provider API.
            try {
                if ($PSCmdlet.ShouldProcess("Alias '$Name'", "Create")) {
                    New-Alias -Name $Name -Value $Target -Scope Global -Force -ErrorAction Stop
                    if ($ReturnDefinition) { return "New-Alias -Name $Name -Value $Target -Scope Global" } else { return $true }
                }
            }
            catch {
                # Fall back to creating a small function via the Function: provider
                $funcPath = "Function:\global:$Name"
                $sb = [scriptblock]::Create("param([Parameter(ValueFromRemainingArguments=\$true)]\$args) & $Target @args")
                if ($PSCmdlet.ShouldProcess("Function '$Name'", "Create")) {
                    New-Item -Path $funcPath -Value $sb -Force | Out-Null
                    if ($ReturnDefinition) { return $funcPath } else { return $true }
                }
            }
        }
        catch {
            if ($dbgEnabled) { Write-Verbose ("Set-AgentModeAlias: failed creating {0}: {1}" -f $Name, $_.Exception.Message) }
            return $false
        }
    }
}

# Lightweight cached command-test used by multiple fragments to avoid repeated Get-Command calls
if (-not (Test-Path "Function:\\global:Test-CachedCommand")) {
    <#
    .SYNOPSIS
        Tests for command availability with caching.
    .DESCRIPTION
        Lightweight cached command testing used by profile fragments to avoid
        repeated Get-Command calls. Results are cached in script scope for performance.
    #>
    function Test-CachedCommand {
        param([Parameter(Mandatory)] [string]$Name)
        if (-not $script:__cmdCache) { $script:__cmdCache = @{} }
        if ($script:__cmdCache.ContainsKey($Name)) { return $script:__cmdCache[$Name] }
        # Fallback to Get-Command only when necessary (cached afterwards)
        $found = $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
        $script:__cmdCache[$Name] = $found
        return $found
    }
}

# Small utility exported for fragments: prefer provider checks first to avoid module autoload
<#
.SYNOPSIS
    Tests if a command is available.
.DESCRIPTION
    Utility function to check if a command exists. Uses fast provider checks first
    to avoid module autoload, then falls back to cached or direct command testing.
#>
function Test-HasCommand {
    param([Parameter(Mandatory)] [string]$Name)
    # Fast provider checks avoid triggering module autoload/discovery
    if (Test-Path "Function:\\global:$Name" -or Test-Path "Function:\\$Name" -or Test-Path "Alias:\\$Name") { return $true }
    # If we have the cached helper, prefer it to avoid repeated Get-Command calls
    if (Test-Path "Function:\\global:Test-CachedCommand" -or (Get-Command -Name Test-CachedCommand -ErrorAction SilentlyContinue)) {
        try { return [bool](Test-CachedCommand -Name $Name) } catch { Write-Verbose "Test-CachedCommand failed: $($_.Exception.Message)" }
    }
    # Last resort: Get-Command (may autoload modules)
    return $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
}























