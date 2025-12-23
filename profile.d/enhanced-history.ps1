# ===============================================
# enhanced-history.ps1
# Enhanced history search and navigation
# ===============================================

# Source enhanced history utility module
# Tier: optional
# Dependencies: bootstrap, env
try {
    $utilitiesModulesDir = Join-Path $PSScriptRoot 'utilities-modules'
    if ($utilitiesModulesDir -and -not [string]::IsNullOrWhiteSpace($utilitiesModulesDir) -and (Test-Path -LiteralPath $utilitiesModulesDir)) {
        $historyDir = Join-Path $utilitiesModulesDir 'history'
        if ($historyDir -and -not [string]::IsNullOrWhiteSpace($historyDir) -and (Test-Path -LiteralPath $historyDir)) {
            $modulePath = Join-Path $historyDir 'utilities-history-enhanced.ps1'
            if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                try {
                    . $modulePath
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                            Write-ProfileError -ErrorRecord $_ -Context "Fragment: enhanced-history (utilities-history-enhanced.ps1)" -Category 'Fragment'
                        }
                        else {
                            Write-Warning "Failed to load enhanced history module utilities-history-enhanced.ps1 : $($_.Exception.Message)"
                        }
                    }
                }
            }
        }
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: enhanced-history" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load enhanced history fragment: $($_.Exception.Message)"
        }
    }
}
