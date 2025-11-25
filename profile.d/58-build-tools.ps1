# ===============================================
# 58-build-tools.ps1
# Build tools and dev servers helpers (guarded)
# ===============================================

# Source build tools module
$devToolsModulesDir = Join-Path $PSScriptRoot 'dev-tools-modules'
if (Test-Path $devToolsModulesDir) {
    $buildDir = Join-Path $devToolsModulesDir 'build'
    . (Join-Path $buildDir 'build-tools.ps1')
}
