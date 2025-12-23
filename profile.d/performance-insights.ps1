# ===============================================
# performance-insights.ps1
# Command timing and performance insights
# ===============================================

# Source performance insights diagnostic module
# Tier: optional
# Dependencies: bootstrap, env
try {
    $diagnosticsModulesDir = Join-Path $PSScriptRoot 'diagnostics-modules'
    if ($diagnosticsModulesDir -and -not [string]::IsNullOrWhiteSpace($diagnosticsModulesDir) -and (Test-Path -LiteralPath $diagnosticsModulesDir)) {
        $monitoringDir = Join-Path $diagnosticsModulesDir 'monitoring'
        if ($monitoringDir -and -not [string]::IsNullOrWhiteSpace($monitoringDir) -and (Test-Path -LiteralPath $monitoringDir)) {
            $modulePath = Join-Path $monitoringDir 'diagnostics-performance.ps1'
            if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                try {
                    . $modulePath
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                            Write-ProfileError -ErrorRecord $_ -Context "Fragment: performance-insights (diagnostics-performance.ps1)" -Category 'Fragment'
                        }
                        else {
                            Write-Warning "Failed to load performance insights module diagnostics-performance.ps1 : $($_.Exception.Message)"
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
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: performance-insights" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load performance insights fragment: $($_.Exception.Message)"
        }
    }
}
