# ===============================================
# PlatformPaths.ps1
# Cross-platform directory resolution helpers
# ===============================================

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$platformPathsModule = Join-Path $repoRoot 'scripts' 'lib' 'core' 'PlatformPaths.psm1'

if ($platformPathsModule -and (Test-Path -LiteralPath $platformPathsModule)) {
    try {
        Import-Module $platformPathsModule -DisableNameChecking -ErrorAction Stop -Global
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Warning "Failed to import PlatformPaths module: $($_.Exception.Message)"
        }
    }
}
