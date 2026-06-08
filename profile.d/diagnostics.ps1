# ===============================================
# diagnostics.ps1
# Profile diagnostics and health checks
# ===============================================

<#
.SYNOPSIS
    Profile diagnostics and health checks.
.DESCRIPTION
    Loads the diagnostics module providing profile health checks, fragment
    loading status inspection, and environment diagnostics functions.
#>

# Source profile diagnostic module
# Tier: standard
# Dependencies: bootstrap, env
# Environment: testing, ci, development
try {
    $success = Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('diagnostics-modules', 'core', 'diagnostics-profile.ps1') `
        -Context "Fragment: diagnostics (diagnostics-profile.ps1)" `
        -CacheResults

    if ($env:PS_PROFILE_DEBUG -and -not $success) {
        Write-Verbose "Failed to load diagnostics module"
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: diagnostics" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load diagnostics fragment: $($_.Exception.Message)"
        }
    }
}
