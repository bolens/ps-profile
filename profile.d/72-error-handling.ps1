# ===============================================
# 72-error-handling.ps1
# Enhanced error handling and recovery mechanisms
# ===============================================

# Source error handling diagnostic module
$diagnosticsModulesDir = Join-Path $PSScriptRoot 'diagnostics-modules'
if (Test-Path $diagnosticsModulesDir) {
    $coreDir = Join-Path $diagnosticsModulesDir 'core'
    . (Join-Path $coreDir 'diagnostics-error-handling.ps1')
}
