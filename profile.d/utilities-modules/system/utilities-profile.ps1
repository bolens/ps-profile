# ===============================================
# Profile management utility functions
# Profile reloading, editing, backup, and function listing
# ===============================================

# Reload profile in current session
<#
.SYNOPSIS
    Reloads the PowerShell profile.
.DESCRIPTION
    Dots-sources the current profile file to reload all functions and settings.
    
.PARAMETER Fast
    Enables fast reload mode, skipping expensive operations like update checks and git status.
    Automatically enabled if PS_PROFILE_FAST_RELOAD or PS_PROFILE_DEV_MODE is set.
    
.EXAMPLE
    Reload-Profile
    Reloads the profile normally.
    
.EXAMPLE
    Reload-Profile -Fast
    Reloads the profile in fast mode, skipping expensive operations.
#>
function Reload-Profile {
    [CmdletBinding()]
    param(
        [switch]$Fast
    )
    
    # Auto-enable fast mode if environment variables are set
    if (-not $Fast) {
        # Helper function to check env bool (fallback if Test-EnvBool not available)
        function Test-EnvBoolLocal {
            param([string]$Value)
            if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
            $normalized = $Value.Trim().ToLowerInvariant()
            return ($normalized -eq '1' -or $normalized -eq 'true')
        }
        
        $testEnvBool = if (Get-Command Test-EnvBool -ErrorAction SilentlyContinue) {
            { param([string]$v) Test-EnvBool -Value $v }
        }
        else {
            { param([string]$v) Test-EnvBoolLocal -Value $v }
        }
        
        $Fast = (& $testEnvBool $env:PS_PROFILE_FAST_RELOAD) -or (& $testEnvBool $env:PS_PROFILE_DEV_MODE)
    }
    
    if ($Fast) {
        # Fast reload: skip expensive operations
        $originalSkipUpdates = $env:PS_PROFILE_SKIP_UPDATES
        $originalDevMode = $env:PS_PROFILE_DEV_MODE
        
        try {
            # Temporarily enable skip flags for fast reload
            $env:PS_PROFILE_SKIP_UPDATES = '1'
            if (-not $env:PS_PROFILE_DEV_MODE) {
                $env:PS_PROFILE_DEV_MODE = '1'
            }
            
            Write-Verbose "Fast reload: Skipping expensive operations"
            . $PROFILE
        }
        finally {
            # Restore original values
            if ($originalSkipUpdates) {
                $env:PS_PROFILE_SKIP_UPDATES = $originalSkipUpdates
            }
            else {
                Remove-Item Env:\PS_PROFILE_SKIP_UPDATES -ErrorAction SilentlyContinue
            }
            
            if (-not $originalDevMode) {
                Remove-Item Env:\PS_PROFILE_DEV_MODE -ErrorAction SilentlyContinue
            }
        }
    }
    else {
        # Normal reload
        . $PROFILE
    }
}

Set-Alias -Name reload -Value Reload-Profile -ErrorAction SilentlyContinue

# Fast reload alias
function Reload-ProfileFast { Reload-Profile -Fast }
Set-Alias -Name reload-fast -Value Reload-ProfileFast -ErrorAction SilentlyContinue

# Edit profile in code editor
<#
.SYNOPSIS
    Opens the profile in VS Code.
.DESCRIPTION
    Launches VS Code to edit the current PowerShell profile file.
#>
function Edit-Profile { code $PROFILE }
Set-Alias -Name edit-profile -Value Edit-Profile -ErrorAction SilentlyContinue

# Backup current profile to timestamped .bak file
<#
.SYNOPSIS
    Creates a backup of the profile.
.DESCRIPTION
    Creates a timestamped backup copy of the current PowerShell profile.
#>
function Backup-Profile { Copy-Item $PROFILE ($PROFILE + '.' + (Get-Date -Format 'yyyyMMddHHmmss') + '.bak') }
Set-Alias -Name backup-profile -Value Backup-Profile -ErrorAction SilentlyContinue

# List all user-defined functions in current session
<#
.SYNOPSIS
    Lists user-defined functions.
.DESCRIPTION
    Displays all user-defined functions in the current PowerShell session.
#>
function Get-Functions { @(Get-Command -CommandType Function | Where-Object { $_.Source -eq '' } | Select-Object Name, Definition) }
Set-Alias -Name list-functions -Value Get-Functions -ErrorAction SilentlyContinue

# Reload a specific fragment
<#
.SYNOPSIS
    Reloads a specific profile fragment.
.DESCRIPTION
    Reloads a single fragment from profile.d/ without reloading the entire profile.
    Useful for testing changes to a specific fragment during development.
    
.PARAMETER FragmentName
    Name of the fragment to reload (without .ps1 extension).
    
.PARAMETER FragmentNames
    Array of fragment names to reload.
    
.EXAMPLE
    Reload-Fragment -FragmentName 'files'
    Reloads the files.ps1 fragment.
    
.EXAMPLE
    Reload-Fragment -FragmentName 'files','utilities'
    Reloads multiple fragments.
#>
function Reload-Fragment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$FragmentName
    )
    
    $profileDir = Split-Path $PROFILE
    $profileDDir = Join-Path $profileDir 'profile.d'
    
    foreach ($name in $FragmentName) {
        # Remove .ps1 extension if present
        $name = $name -replace '\.ps1$', ''
        
        $fragmentPath = Join-Path $profileDDir "$name.ps1"
        
        if (-not (Test-Path -LiteralPath $fragmentPath)) {
            Write-Warning "Fragment not found: $name.ps1"
            continue
        }
        
        try {
            Write-Verbose "Reloading fragment: $name"
            . $fragmentPath
            Write-Host "✓ Reloaded fragment: $name" -ForegroundColor Green
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'utilities.profile.reload-fragment' -Context @{
                    fragment_name = $name
                }
            }
            else {
                Write-Error "Failed to reload fragment $name : $($_.Exception.Message)"
            }
        }
    }
}

# Test a fragment in isolation
<#
.SYNOPSIS
    Tests a fragment by loading it with minimal dependencies.
.DESCRIPTION
    Loads a fragment with only bootstrap and env dependencies for isolated testing.
    
.PARAMETER FragmentName
    Name of the fragment to test (without .ps1 extension).
    
.EXAMPLE
    Test-Fragment -FragmentName 'files'
    Loads bootstrap, env, and files fragments for testing.
#>
function Test-Fragment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FragmentName
    )
    
    $profileDir = Split-Path $PROFILE
    $profileDDir = Join-Path $profileDir 'profile.d'
    
    # Remove .ps1 extension if present
    $FragmentName = $FragmentName -replace '\.ps1$', ''
    
    Write-Host "Loading fragment for testing: $FragmentName" -ForegroundColor Cyan
    
    # Load bootstrap first
    $bootstrapPath = Join-Path $profileDDir 'bootstrap.ps1'
    if (Test-Path -LiteralPath $bootstrapPath) {
        Write-Verbose "Loading bootstrap..."
        . $bootstrapPath
    }
    
    # Load env
    $envPath = Join-Path $profileDDir 'env.ps1'
    if (Test-Path -LiteralPath $envPath) {
        Write-Verbose "Loading env..."
        . $envPath
    }
    
    # Load the fragment
    $fragmentPath = Join-Path $profileDDir "$FragmentName.ps1"
    if (Test-Path -LiteralPath $fragmentPath) {
        Write-Verbose "Loading fragment: $FragmentName..."
        . $fragmentPath
        Write-Host "✓ Fragment loaded: $FragmentName" -ForegroundColor Green
    }
    else {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                    [System.IO.FileNotFoundException]::new("Fragment not found: $FragmentName.ps1"),
                    'FragmentNotFound',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $FragmentName
                )) -OperationName 'utilities.profile.test-fragment' -Context @{
                fragment_name = $FragmentName
            }
        }
        else {
            Write-Error "Fragment not found: $FragmentName.ps1"
        }
    }
}

