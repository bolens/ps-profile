# ===============================================
# ProfileEnvDisplay.psm1
# PS_PROFILE environment variable display
# ===============================================

<#
.SYNOPSIS
    Displays PS_PROFILE environment variables in debug mode.
.DESCRIPTION
    Shows all PS_PROFILE_* environment variables with their values, defaults, and status.
    Only shows non-default values unless PS_PROFILE_DEBUG_SHOW_ALL_VARS is set.
#>
function Show-ProfileEnvVariables {
    [CmdletBinding()]
    param()

    if (-not $env:PS_PROFILE_DEBUG) {
        return
    }

    # Define all known PS_PROFILE variables with their defaults, grouped by category
    $knownVariables = @{
        # Debug & Performance
        'PS_PROFILE_DEBUG'                      = @{ Default = '0'; Category = 'Debug'; Description = 'Enable debug output for profile loading' }
        'PS_PROFILE_DEBUG_TIMINGS'              = @{ Default = '0'; Category = 'Debug'; Description = 'Enable performance timing output for fragment loading' }
        'PS_PROFILE_DEBUG_PARALLEL_SUPPRESS'    = @{ Default = '0'; Category = 'Debug'; Description = 'Suppress individual fragment messages during parallel loading' }
        'PS_PROFILE_DEBUG_TESTPATH'             = @{ Default = '0'; Category = 'Debug'; Description = 'Enable Test-Path interception debugging' }
        'PS_PROFILE_DEBUG_TESTPATH_TRACE'       = @{ Default = '0'; Category = 'Debug'; Description = 'Enable Test-Path trace debugging (detailed logging)' }
        'PS_PROFILE_DEBUG_SHOW_ALL_VARS'        = @{ Default = '0'; Category = 'Debug'; Description = 'Show all environment variables in debug output (including defaults)' }
        
        # Loading & Performance
        'PS_PROFILE_PARALLEL_LOADING'           = @{ Default = '0'; Category = 'Loading'; Description = 'EXPERIMENTAL: Enable parallel fragment loading (hybrid approach with sequential fallback)' }
        'PS_PROFILE_PARALLEL_DEPENDENCIES'      = @{ Default = '1'; Category = 'Loading'; Description = 'Enable parallel dependency parsing (speeds up dependency analysis)' }
        'PS_PROFILE_LOAD_ALL'                   = @{ Default = '0'; Category = 'Loading'; Description = 'Load all fragments (override disabled fragments and environment restrictions)' }
        'PS_PROFILE_ENABLE_LOCAL_OVERRIDES'     = @{ Default = '0'; Category = 'Loading'; Description = 'Enable local-overrides.ps1 loading (WARNING: may cause performance issues)' }
        'PS_PROFILE_BATCH_LOAD'                 = @{ Default = '0'; Category = 'Loading'; Description = 'Enable batch loading optimization for faster startup' }
        
        # Configuration
        'PS_PROFILE_ENVIRONMENT'                = @{ Default = ''; Category = 'Config'; Description = 'Active environment (minimal/testing/ci/server/cloud/containers/web/full/development)' }
        'PS_PROFILE_AUTOENABLE_ALIASES'         = @{ Default = '0'; Category = 'Config'; Description = 'Auto-enable aliases on profile load (instead of on-demand)' }
        'PS_PROFILE_AUTOENABLE_PSREADLINE'      = @{ Default = '0'; Category = 'Config'; Description = 'Auto-enable PSReadLine (mainly for benchmarking)' }
        'PS_PROFILE_SKIP_UPDATES'               = @{ Default = '0'; Category = 'Config'; Description = 'Skip automatic profile update checks' }
        'PS_PROFILE_SUPPRESS_TOOL_WARNINGS'     = @{ Default = '0'; Category = 'Config'; Description = 'Suppress missing tool warnings' }
        'PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS' = @{ Default = ''; Category = 'Config'; Description = 'Suppress warnings from specific fragments (comma/semicolon/space-separated fragment names, or all/*/1/true for all)' }
        'PS_PROFILE_ASSUME_COMMANDS'            = @{ Default = ''; Category = 'Config'; Description = 'Assume these commands are available even if not found on PATH (comma/semicolon/space-separated)' }
        'PS_PROFILE_TEST_MODE'                  = @{ Default = '0'; Category = 'Config'; Description = 'Enable test mode (disables certain interactive features, for testing/CI)' }
        
        # Prompt Display
        'PS_PROFILE_SHOW_GIT_BRANCH'            = @{ Default = '0'; Category = 'Prompt'; Description = 'Show git branch in prompt (SmartPrompt.ps1)' }
        'PS_PROFILE_SHOW_UV'                    = @{ Default = '0'; Category = 'Prompt'; Description = 'Show uv project status in prompt (SmartPrompt.ps1)' }
        'PS_PROFILE_SHOW_NPM'                   = @{ Default = '0'; Category = 'Prompt'; Description = 'Show npm project status in prompt (SmartPrompt.ps1)' }
        'PS_PROFILE_SHOW_PNPM'                  = @{ Default = '0'; Category = 'Prompt'; Description = 'Show pnpm/yarn project status in prompt (SmartPrompt.ps1)' }
        'PS_PROFILE_SHOW_RUST'                  = @{ Default = '0'; Category = 'Prompt'; Description = 'Show Rust project status in prompt (SmartPrompt.ps1)' }
        'PS_PROFILE_SHOW_GO'                    = @{ Default = '0'; Category = 'Prompt'; Description = 'Show Go project status in prompt (SmartPrompt.ps1)' }
        'PS_PROFILE_SHOW_DOCKER'                = @{ Default = '0'; Category = 'Prompt'; Description = 'Show Docker project status in prompt (SmartPrompt.ps1)' }
        'PS_PROFILE_SHOW_POETRY'                = @{ Default = '0'; Category = 'Prompt'; Description = 'Show Poetry project status in prompt (SmartPrompt.ps1)' }
    }
    
    # Cache environment variables (only call Get-ChildItem once)
    # Optimized: Single-pass filtering instead of Where-Object + ForEach-Object
    $allEnvVars = Get-ChildItem Env:
    $setEnvVars = @{}
    foreach ($envVar in $allEnvVars) {
        if ($envVar.Name -like 'PS_PROFILE_*') {
            $setEnvVars[$envVar.Name] = $envVar.Value
        }
    }
    
    # Helper function to normalize boolean values
    function Test-BooleanValue {
        param([string]$Value)
        if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
        $normalized = $Value.Trim().ToLowerInvariant()
        return $normalized -eq '1' -or $normalized -eq 'true'
    }
    
    # Helper function to format display value (converts 0/1 to false/true for boolean vars)
    function Format-EnvValue {
        param(
            [string]$Value,
            [string]$VarName
        )
        # Special cases that aren't simple booleans
        if ($VarName -eq 'PS_PROFILE_ENVIRONMENT' -or $VarName -eq 'PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS' -or $VarName -eq 'PS_PROFILE_ASSUME_COMMANDS') {
            if ([string]::IsNullOrWhiteSpace($Value)) {
                return '(not set)'
            }
            if ($Value.Length -gt 60) {
                return $Value.Substring(0, 57) + '...'
            }
            return $Value
        }
        if ($VarName -eq 'PS_PROFILE_DEBUG') {
            # DEBUG supports levels 0,1,2,3 - show as-is
            if ([string]::IsNullOrWhiteSpace($Value)) {
                return '(empty)'
            }
            if ($Value.Length -gt 60) {
                return $Value.Substring(0, 57) + '...'
            }
            return $Value
        }
        
        # For boolean variables, convert 0/1 to false/true
        if ([string]::IsNullOrWhiteSpace($Value)) {
            return '(empty)'
        }
        if ($Value.Length -gt 60) {
            return $Value.Substring(0, 57) + '...'
        }
        $normalized = $Value.Trim().ToLowerInvariant()
        if ($normalized -eq '0') {
            return 'false'
        }
        if ($normalized -eq '1' -or $normalized -eq 'true') {
            return 'true'
        }
        # For other values (like '2', '3' for DEBUG, or custom strings), return as-is
        return $Value
    }
    
    # Helper function to format default value (converts 0/1 to false/true for boolean vars)
    function Format-DefaultValue {
        param(
            [string]$Value,
            [string]$VarName
        )
        # Special cases that aren't simple booleans
        if ($VarName -eq 'PS_PROFILE_ENVIRONMENT' -or $VarName -eq 'PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS' -or $VarName -eq 'PS_PROFILE_ASSUME_COMMANDS') {
            if ([string]::IsNullOrWhiteSpace($Value)) {
                return '(not set)'
            }
            return $Value
        }
        if ($VarName -eq 'PS_PROFILE_DEBUG') {
            # DEBUG supports levels 0,1,2,3 - show as-is
            if ([string]::IsNullOrWhiteSpace($Value)) {
                return '(empty)'
            }
            return $Value
        }
        
        # For boolean variables, convert 0/1 to false/true
        if ([string]::IsNullOrWhiteSpace($Value)) {
            return '(empty)'
        }
        $normalized = $Value.Trim().ToLowerInvariant()
        if ($normalized -eq '0') {
            return 'false'
        }
        if ($normalized -eq '1' -or $normalized -eq 'true') {
            return 'true'
        }
        # For other values, return as-is
        return $Value
    }
    
    # Determine if value matches default (for filtering)
    $showAllVars = $env:PS_PROFILE_DEBUG_SHOW_ALL_VARS -eq '1' -or $env:PS_PROFILE_DEBUG_SHOW_ALL_VARS -eq 'true'
    
    # Collect all variables (both set and unset)
    $psProfileVars = [System.Collections.Generic.List[PSCustomObject]]::new()
    
    foreach ($varName in ($knownVariables.Keys | Sort-Object)) {
        $varInfo = $knownVariables[$varName]
        $isSet = $setEnvVars.ContainsKey($varName)
        $value = if ($isSet) { $setEnvVars[$varName] } else { $varInfo.Default }
        
        # Determine enabled state
        $isEnabled = $false
        $isDefaultEnabled = $false
        
        if ($varName -eq 'PS_PROFILE_DEBUG') {
            # Special case: DEBUG supports multiple levels (0,1,2,3)
            $debugValues = @('1', 'true', '2', '3')
            $isEnabled = if ($isSet) {
                $debugValues -contains $value
            }
            else {
                $debugValues -contains $varInfo.Default
            }
            $isDefaultEnabled = $debugValues -contains $varInfo.Default
        }
        elseif ($varName -eq 'PS_PROFILE_ENVIRONMENT' -or $varName -eq 'PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS' -or $varName -eq 'PS_PROFILE_ASSUME_COMMANDS') {
            # String variables: enabled if set to non-empty value
            $isEnabled = $isSet -and -not [string]::IsNullOrWhiteSpace($value)
            $isDefaultEnabled = $false
        }
        else {
            # Standard boolean check
            $isEnabled = Test-BooleanValue -Value $value
            $isDefaultEnabled = Test-BooleanValue -Value $varInfo.Default
        }
        
        # Matches default if: not set (using default) OR enabled state matches default enabled state
        $matchesDefault = (-not $isSet) -or ($isEnabled -eq $isDefaultEnabled)
        
        # Skip if matches default and not showing all (unless it's a special case)
        if (-not $showAllVars -and $matchesDefault -and $varName -ne 'PS_PROFILE_ENVIRONMENT') {
            continue
        }
        
        # Format default value for display (with boolean conversion)
        $defaultDisplayValue = Format-DefaultValue -Value $varInfo.Default -VarName $varName
        
        $psProfileVars.Add([PSCustomObject]@{
                Variable    = $varName
                Value       = Format-EnvValue -Value $value -VarName $varName
                Enabled     = if ($isEnabled) { '*' } else { '' }
                Default     = $defaultDisplayValue
                Status      = if ($matchesDefault) { 'default' } else { 'custom' }
                Category    = $varInfo.Category
                Description = $varInfo.Description
            })
    }
    
    # Also include any custom PS_PROFILE variables that aren't in our known list
    # Optimized: Single-pass filtering instead of Where-Object
    # Note: Get-ChildItem Env: returns DictionaryEntry objects, not PSVariable
    $customVars = [System.Collections.Generic.List[System.Collections.DictionaryEntry]]::new()
    foreach ($envVar in $allEnvVars) {
        if ($envVar.Name -like 'PS_PROFILE_*' -and -not $knownVariables.ContainsKey($envVar.Name)) {
            $customVars.Add($envVar)
        }
    }
    $customVars = $customVars | Sort-Object Name
    foreach ($envVar in $customVars) {
        $value = $envVar.Value
        $isEnabled = Test-BooleanValue -Value $value
        
        $psProfileVars.Add([PSCustomObject]@{
                Variable    = $envVar.Name
                Value       = Format-EnvValue -Value $value -VarName $envVar.Name
                Enabled     = if ($isEnabled) { '*' } else { '' }
                Default     = '(unknown)'
                Status      = 'custom'
                Category    = 'Custom'
                Description = 'Custom PS_PROFILE variable (not in known list)'
            })
    }
    
    if ($psProfileVars.Count -gt 0) {
        Write-Host "`nPS_PROFILE Environment Variables:" -ForegroundColor Cyan
        if (-not $showAllVars) {
            Write-Host "  (Showing non-default values only. Set PS_PROFILE_DEBUG_SHOW_ALL_VARS=1 to show all)" -ForegroundColor Gray
        }
        Write-Host "  Enabled: * = enabled" -ForegroundColor Gray
        Write-Host "  Status: default = using default value, custom = overridden" -ForegroundColor Gray
        
        # Group by category for better readability
        $grouped = $psProfileVars | Group-Object -Property Category | Sort-Object Name
        foreach ($group in $grouped) {
            if ($grouped.Count -gt 1) {
                Write-Host "`n[$($group.Name)]" -ForegroundColor DarkCyan
            }
            $group.Group | Format-Table -AutoSize -Property Variable, Value, Enabled, Default, Status, Description | Out-String | Write-Host
        }
    }
    else {
        Write-Host "No PS_PROFILE_* environment variables detected" -ForegroundColor Gray
    }
}

Export-ModuleMember -Function 'Show-ProfileEnvVariables'
