# ===============================================
# error-handling.ps1
# Enhanced error handling and recovery mechanisms
# ===============================================

# Source error handling diagnostic module
# Tier: optional
# Dependencies: bootstrap, env
# Environment: testing, ci, development
try {
    $diagnosticsModulesDir = Join-Path $PSScriptRoot 'diagnostics-modules'
    if ($diagnosticsModulesDir -and -not [string]::IsNullOrWhiteSpace($diagnosticsModulesDir) -and (Test-Path -LiteralPath $diagnosticsModulesDir)) {
        $coreDir = Join-Path $diagnosticsModulesDir 'core'
        if ($coreDir -and -not [string]::IsNullOrWhiteSpace($coreDir) -and (Test-Path -LiteralPath $coreDir)) {
            $modulePath = Join-Path $coreDir 'diagnostics-error-handling.ps1'
            if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                try {
                    . $modulePath
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                            Write-ProfileError -ErrorRecord $_ -Context "Fragment: error-handling (diagnostics-error-handling.ps1)" -Category 'Fragment'
                        }
                        else {
                            Write-Warning "Failed to load error handling module diagnostics-error-handling.ps1 : $($_.Exception.Message)"
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
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: error-handling" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load error handling fragment: $($_.Exception.Message)"
        }
    }
}
