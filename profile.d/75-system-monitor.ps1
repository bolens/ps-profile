# ===============================================
# 75-system-monitor.ps1
# System monitoring dashboard
# ===============================================

# Source system monitor diagnostic module
$diagnosticsModulesDir = Join-Path $PSScriptRoot 'diagnostics-modules'
if (Test-Path $diagnosticsModulesDir) {
    $monitoringDir = Join-Path $diagnosticsModulesDir 'monitoring'
    . (Join-Path $monitoringDir 'diagnostics-system-monitor.ps1')
}
