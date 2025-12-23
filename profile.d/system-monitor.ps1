# ===============================================
# system-monitor.ps1
# System monitoring dashboard
# ===============================================

# Source system monitor diagnostic module
# Tier: optional
# Dependencies: bootstrap, env
# Environment: server, development
try {
    $diagnosticsModulesDir = Join-Path $PSScriptRoot 'diagnostics-modules'
    if ($diagnosticsModulesDir -and -not [string]::IsNullOrWhiteSpace($diagnosticsModulesDir) -and (Test-Path -LiteralPath $diagnosticsModulesDir)) {
        $monitoringDir = Join-Path $diagnosticsModulesDir 'monitoring'
        if ($monitoringDir -and -not [string]::IsNullOrWhiteSpace($monitoringDir) -and (Test-Path -LiteralPath $monitoringDir)) {
            $modulePath = Join-Path $monitoringDir 'diagnostics-system-monitor.ps1'
            if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                try {
                    . $modulePath
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                            Write-ProfileError -ErrorRecord $_ -Context "Fragment: system-monitor (diagnostics-system-monitor.ps1)" -Category 'Fragment'
                        }
                        else {
                            Write-Warning "Failed to load system monitor module diagnostics-system-monitor.ps1 : $($_.Exception.Message)"
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
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: system-monitor" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load system monitor fragment: $($_.Exception.Message)"
        }
    }
}
