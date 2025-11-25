# ===============================================
# 57-testing.ps1
# Testing frameworks helpers (guarded)
# ===============================================

# Source testing framework module
$devToolsModulesDir = Join-Path $PSScriptRoot 'dev-tools-modules'
if (Test-Path $devToolsModulesDir) {
    $buildDir = Join-Path $devToolsModulesDir 'build'
    . (Join-Path $buildDir 'testing-frameworks.ps1')
}
