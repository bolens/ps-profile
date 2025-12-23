# ===============================================
# testing.ps1
# Testing frameworks helpers (guarded)
# ===============================================

# Source testing framework module
# Use standardized module loading if available, otherwise fall back to manual loading
# Tier: standard
# Dependencies: bootstrap, env
# Environment: testing, development
if (Get-Command Import-FragmentModule -ErrorAction SilentlyContinue) {
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
}
else {
    # Fallback: manual loading for environments where Import-FragmentModule is not yet available
    try {
        $devToolsModulesDir = Join-Path $PSScriptRoot 'dev-tools-modules'
        if ($devToolsModulesDir -and -not [string]::IsNullOrWhiteSpace($devToolsModulesDir) -and (Test-Path -LiteralPath $devToolsModulesDir)) {
            $buildDir = Join-Path $devToolsModulesDir 'build'
            if ($buildDir -and -not [string]::IsNullOrWhiteSpace($buildDir) -and (Test-Path -LiteralPath $buildDir)) {
                $modulePath = Join-Path $buildDir 'testing-frameworks.ps1'
                if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                    try {
                        . $modulePath
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                                Write-ProfileError -ErrorRecord $_ -Context "Fragment: testing (testing-frameworks.ps1)" -Category 'Fragment'
                            }
                            else {
                                Write-Warning "Failed to load testing framework module testing-frameworks.ps1 : $($_.Exception.Message)"
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
                Write-ProfileError -ErrorRecord $_ -Context "Fragment: testing" -Category 'Fragment'
            }
            else {
                Write-Warning "Failed to load testing fragment: $($_.Exception.Message)"
            }
        }
    }
}
