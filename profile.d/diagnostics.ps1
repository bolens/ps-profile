# ===============================================
# diagnostics.ps1
# Profile diagnostics and health checks
# ===============================================

# Source profile diagnostic module
# Use standardized module loading if available, otherwise fall back to manual loading
# Tier: standard
# Dependencies: bootstrap, env
# Environment: testing, ci, development
if (Get-Command Import-FragmentModule -ErrorAction SilentlyContinue) {
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
}
else {
    # Fallback: manual loading for environments where Import-FragmentModule is not yet available
    try {
        $diagnosticsModulesDir = Join-Path $PSScriptRoot 'diagnostics-modules'
        if ($diagnosticsModulesDir -and -not [string]::IsNullOrWhiteSpace($diagnosticsModulesDir) -and (Test-Path -LiteralPath $diagnosticsModulesDir)) {
            $coreDir = Join-Path $diagnosticsModulesDir 'core'
            if ($coreDir -and -not [string]::IsNullOrWhiteSpace($coreDir) -and (Test-Path -LiteralPath $coreDir)) {
                $modulePath = Join-Path $coreDir 'diagnostics-profile.ps1'
                if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                    try {
                        . $modulePath
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                                Write-ProfileError -ErrorRecord $_ -Context "Fragment: diagnostics (diagnostics-profile.ps1)" -Category 'Fragment'
                            }
                            else {
                                Write-Warning "Failed to load diagnostics module diagnostics-profile.ps1 : $($_.Exception.Message)"
                            }
                        }
                    }
                }
            }
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
}
