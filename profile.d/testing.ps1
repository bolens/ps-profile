# ===============================================
# testing.ps1
# Testing frameworks helpers (guarded)
# ===============================================

<#
.SYNOPSIS
    Testing framework helpers (Pester, pytest, etc.).
.DESCRIPTION
    Loads the dev-tools testing module providing helpers for running tests
    with Pester, pytest, Jest, and other testing frameworks.
    All functions are guarded with tool availability checks.
#>

# Source testing framework module
# Tier: standard
# Dependencies: bootstrap, env
# Environment: testing, development
try {
    $success = Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('dev-tools-modules', 'build', 'testing-frameworks.ps1') `
        -Context "Fragment: testing (testing-frameworks.ps1)" `
        -CacheResults

    if ($env:PS_PROFILE_DEBUG -and -not $success) {
        Write-Verbose "Failed to load testing framework module"
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: testing" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load testing fragment: $($_.Exception.Message)"
        }
    }
}
