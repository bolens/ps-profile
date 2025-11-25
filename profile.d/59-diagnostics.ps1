# ===============================================
# 59-diagnostics.ps1
# Profile diagnostics and health checks
# ===============================================

# Source profile diagnostic module
$diagnosticsModulesDir = Join-Path $PSScriptRoot 'diagnostics-modules'
if (Test-Path $diagnosticsModulesDir) {
    $coreDir = Join-Path $diagnosticsModulesDir 'core'
    . (Join-Path $coreDir 'diagnostics-profile.ps1')
}
