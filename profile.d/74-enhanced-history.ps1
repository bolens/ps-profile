# ===============================================
# 74-enhanced-history.ps1
# Enhanced history search and navigation
# ===============================================

# Source enhanced history utility module
$utilitiesModulesDir = Join-Path $PSScriptRoot 'utilities-modules'
if (Test-Path $utilitiesModulesDir) {
    $historyDir = Join-Path $utilitiesModulesDir 'history'
    . (Join-Path $historyDir 'utilities-history-enhanced.ps1')
}
