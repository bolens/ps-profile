# ===============================================
# 73-performance-insights.ps1
# Command timing and performance insights
# ===============================================

# Source performance insights diagnostic module
$diagnosticsModulesDir = Join-Path $PSScriptRoot 'diagnostics-modules'
if (Test-Path $diagnosticsModulesDir) {
    $monitoringDir = Join-Path $diagnosticsModulesDir 'monitoring'
    . (Join-Path $monitoringDir 'diagnostics-performance.ps1')
}
