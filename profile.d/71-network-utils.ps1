# ===============================================
# 71-network-utils.ps1
# Advanced network utilities with error recovery and timeout handling
# ===============================================

# Source advanced network utility module
$utilitiesModulesDir = Join-Path $PSScriptRoot 'utilities-modules'
if (Test-Path $utilitiesModulesDir) {
    $networkDir = Join-Path $utilitiesModulesDir 'network'
    . (Join-Path $networkDir 'utilities-network-advanced.ps1')
}
