# ===============================================
# 54-modern-cli.ps1
# Modern CLI tools helpers (guarded)
# ===============================================

# Source modern CLI tools module
$cliModulesDir = Join-Path $PSScriptRoot 'cli-modules'
if (Test-Path $cliModulesDir) {
    . (Join-Path $cliModulesDir 'modern-cli.ps1')
}
