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

# Initialize profile timing tracking
if ($env:PS_PROFILE_DEBUG -and -not $global:PSProfileFragmentTimes) {
    $global:PSProfileFragmentTimes = [System.Collections.Generic.List[PSCustomObject]]::new()
}

# Command usage tracking (only when debugging)
if ($env:PS_PROFILE_DEBUG -and -not $global:PSProfileCommandUsage) {
    $global:PSProfileCommandUsage = [System.Collections.Concurrent.ConcurrentDictionary[string, int]]::new()
}

# Collision-safe function creator for profile fragments
if (-not (Test-Path "Function:\\global:Set-AgentModeFunction")) {
    <#
    .SYNOPSIS
        Creates collision-safe functions for profile fragments.
    .DESCRIPTION
        Defines a helper function that creates small convenience functions or wrappers
        without overwriting existing user or module commands. Used by profile fragments
        to safely register functions.
    .PARAMETER Name
        The name of the function to create.
    .PARAMETER Body
        The script block containing the function body.
    .PARAMETER ReturnScriptBlock
        If specified, returns the created script block instead of a boolean.
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
    .PARAMETER Name
        The name of the alias to create.
    .PARAMETER Target
        The target command for the alias.
    .PARAMETER ReturnDefinition
        If specified, returns the alias definition instead of a boolean.
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
    .PARAMETER Name
        The name of the command to test.
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
.PARAMETER Name
    The name of the command to test.
#>
function Test-HasCommand {
    param([Parameter(Mandatory)] [string]$Name)
    # Fast provider checks avoid triggering module autoload/discovery
    if ((Test-Path "Function:\\global:$Name") -or (Test-Path "Function:\\$Name") -or (Test-Path "Alias:\\$Name")) { return $true }
    # If we have the cached helper, prefer it to avoid repeated Get-Command calls
    if (Test-Path "Function:\\global:Test-CachedCommand") {
        try { return [bool](Test-CachedCommand -Name $Name) } catch { Write-Verbose "Test-CachedCommand failed: $($_.Exception.Message)" }
    }
    # Last resort: Get-Command (may autoload modules)
    return $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

# ===============================================
# FRAGMENT MANAGEMENT HELPERS
# ===============================================
# Helper function to get the fragment config file path
if (-not (Test-Path "Function:\\global:Get-FragmentConfigPath")) {
    function Get-FragmentConfigPath {
        $profileDir = Split-Path -Parent $PROFILE
        return Join-Path $profileDir '.profile-fragments.json'
    }
}

# Helper function to load fragment configuration
if (-not (Test-Path "Function:\\global:Get-FragmentConfig")) {
    function Get-FragmentConfig {
        $configPath = Get-FragmentConfigPath
        if (-not (Test-Path $configPath)) {
            return @{ disabled = @() }
        }
        try {
            $content = Get-Content -Path $configPath -Raw -ErrorAction Stop
            $configObj = $content | ConvertFrom-Json
            # Convert to hashtable for easier manipulation
            $config = @{ disabled = @() }
            if ($configObj.disabled) {
                $config.disabled = @($configObj.disabled)
            }
            return $config
        }
        catch {
            Write-Warning "Failed to load fragment config: $($_.Exception.Message). Using defaults."
            return @{ disabled = @() }
        }
    }
}

# Helper function to save fragment configuration
if (-not (Test-Path "Function:\\global:Save-FragmentConfig")) {
    function Save-FragmentConfig {
        param([Parameter(Mandatory)] [hashtable]$Config)
        $configPath = Get-FragmentConfigPath
        try {
            $json = $Config | ConvertTo-Json -Depth 10 -Compress
            Set-Content -Path $configPath -Value $json -ErrorAction Stop
            return $true
        }
        catch {
            Write-Error "Failed to save fragment config: $($_.Exception.Message)"
            return $false
        }
    }
}

# Helper function to check if a fragment is enabled
if (-not (Test-Path "Function:\\global:Test-ProfileFragmentEnabled")) {
    <#
    .SYNOPSIS
        Tests if a profile fragment is enabled.
    .DESCRIPTION
        Checks the fragment configuration to determine if a fragment is enabled.
        Fragments are enabled by default unless explicitly disabled.
    .PARAMETER FragmentName
        The name of the fragment to check (e.g., '11-git.ps1' or '11-git').
    #>
    function Test-ProfileFragmentEnabled {
        param([Parameter(Mandatory)] [string]$FragmentName)
        
        # Normalize fragment name (remove .ps1 extension if present)
        if ($FragmentName -like '*.ps1') {
            $FragmentName = $FragmentName -replace '\.ps1$', ''
        }
        
        $config = Get-FragmentConfig
        return $FragmentName -notin $config.disabled
    }
}

# Enable a profile fragment
if (-not (Test-Path "Function:\\global:Enable-ProfileFragment")) {
    <#
    .SYNOPSIS
        Enables a profile fragment.
    .DESCRIPTION
        Removes a fragment from the disabled list, allowing it to be loaded on next profile reload.
    .PARAMETER FragmentName
        The name of the fragment to enable (e.g., '11-git.ps1' or '11-git').
    .EXAMPLE
        Enable-ProfileFragment -FragmentName '11-git'
    #>
    function Enable-ProfileFragment {
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory, ValueFromPipeline)] [string]$FragmentName
        )
        
        # Normalize fragment name
        if ($FragmentName -like '*.ps1') {
            $FragmentName = $FragmentName -replace '\.ps1$', ''
        }
        
        $config = Get-FragmentConfig
        if ($FragmentName -in $config.disabled) {
            if ($PSCmdlet.ShouldProcess("Fragment '$FragmentName'", "Enable")) {
                $config.disabled = $config.disabled | Where-Object { $_ -ne $FragmentName }
                if (Save-FragmentConfig -Config $config) {
                    Write-Host "Fragment '$FragmentName' enabled. Reload your profile with '. `$PROFILE' to apply changes." -ForegroundColor Green
                    return $true
                }
            }
        }
        else {
            Write-Host "Fragment '$FragmentName' is already enabled." -ForegroundColor Yellow
            return $false
        }
    }
}

# Disable a profile fragment
if (-not (Test-Path "Function:\\global:Disable-ProfileFragment")) {
    <#
    .SYNOPSIS
        Disables a profile fragment.
    .DESCRIPTION
        Adds a fragment to the disabled list, preventing it from being loaded on next profile reload.
    .PARAMETER FragmentName
        The name of the fragment to disable (e.g., '11-git.ps1' or '11-git').
    .EXAMPLE
        Disable-ProfileFragment -FragmentName '11-git'
    #>
    function Disable-ProfileFragment {
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory, ValueFromPipeline)] [string]$FragmentName
        )
        
        # Normalize fragment name
        if ($FragmentName -like '*.ps1') {
            $FragmentName = $FragmentName -replace '\.ps1$', ''
        }
        
        $config = Get-FragmentConfig
        if ($FragmentName -notin $config.disabled) {
            if ($PSCmdlet.ShouldProcess("Fragment '$FragmentName'", "Disable")) {
                $existingDisabled = if ($config.disabled) { @($config.disabled) } else { @() }
                $config.disabled = $existingDisabled + $FragmentName
                if (Save-FragmentConfig -Config $config) {
                    Write-Host "Fragment '$FragmentName' disabled. Reload your profile with '. `$PROFILE' to apply changes." -ForegroundColor Yellow
                    return $true
                }
            }
        }
        else {
            Write-Host "Fragment '$FragmentName' is already disabled." -ForegroundColor Yellow
            return $false
        }
    }
}

# Get profile fragment status
if (-not (Test-Path "Function:\\global:Get-ProfileFragment")) {
    <#
    .SYNOPSIS
        Gets the status of profile fragments.
    .DESCRIPTION
        Lists all profile fragments and their enabled/disabled status.
    .PARAMETER FragmentName
        Optional. Filter by specific fragment name.
    .PARAMETER DisabledOnly
        Show only disabled fragments.
    .PARAMETER EnabledOnly
        Show only enabled fragments.
    .EXAMPLE
        Get-ProfileFragment
    .EXAMPLE
        Get-ProfileFragment -DisabledOnly
    #>
    function Get-ProfileFragment {
        [CmdletBinding()]
        param(
            [string]$FragmentName,
            [switch]$DisabledOnly,
            [switch]$EnabledOnly
        )
        
        $profileDir = Split-Path -Parent $PROFILE
        $profileD = Join-Path $profileDir 'profile.d'
        
        if (-not (Test-Path $profileD)) {
            Write-Warning "Profile.d directory not found: $profileD"
            return
        }
        
        $config = Get-FragmentConfig
        $fragments = Get-ChildItem -Path $profileD -File -Filter '*.ps1' | Sort-Object Name
        
        $results = foreach ($fragment in $fragments) {
            $name = $fragment.BaseName
            $isEnabled = Test-ProfileFragmentEnabled -FragmentName $name
            
            if ($FragmentName -and $name -notlike "*$FragmentName*") {
                continue
            }
            if ($DisabledOnly -and $isEnabled) {
                continue
            }
            if ($EnabledOnly -and -not $isEnabled) {
                continue
            }
            
            [PSCustomObject]@{
                Name     = $name
                FileName = $fragment.Name
                Enabled  = $isEnabled
                Path     = $fragment.FullName
            }
        }
        
        return $results
    }
}
