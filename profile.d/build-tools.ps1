# ===============================================
# build-tools.ps1
# Build tools and dev servers helpers (guarded)
# ===============================================

<#
.SYNOPSIS
    Build tools and dev servers helpers.
.DESCRIPTION
    Loads the dev-tools build module, providing helpers for build systems
    and development servers (npm, vite, webpack, etc.).
    All functions are guarded with tool availability checks.
#>

# Source build tools module
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development
try {
    $success = Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('dev-tools-modules', 'build', 'build-tools.ps1') `
        -Context "Fragment: build-tools (build-tools.ps1)" `
        -CacheResults

    if ($env:PS_PROFILE_DEBUG -and -not $success) {
        Write-Verbose "Failed to load build tools module"
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: build-tools" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load build tools fragment: $($_.Exception.Message)"
        }
    }
}
