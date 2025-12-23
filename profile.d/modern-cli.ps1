# ===============================================
# modern-cli.ps1
# Modern CLI tools helpers (guarded)
# ===============================================

# Source modern CLI tools module
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development
try {
    $cliModulesDir = Join-Path $PSScriptRoot 'cli-modules'
    if ($cliModulesDir -and -not [string]::IsNullOrWhiteSpace($cliModulesDir) -and (Test-Path -LiteralPath $cliModulesDir)) {
        $modulePath = Join-Path $cliModulesDir 'modern-cli.ps1'
        if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
            try {
                . $modulePath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: modern-cli (modern-cli.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load modern CLI module modern-cli.ps1 : $($_.Exception.Message)"
                    }
                }
            }
        }
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: modern-cli" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load modern CLI fragment: $($_.Exception.Message)"
        }
    }
}
