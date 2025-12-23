# ===============================================
# network-utils.ps1
# Advanced network utilities with error recovery and timeout handling
# ===============================================

# Source advanced network utility module
# Tier: optional
# Dependencies: bootstrap, env
# Environment: server, development
try {
    $utilitiesModulesDir = Join-Path $PSScriptRoot 'utilities-modules'
    if ($utilitiesModulesDir -and -not [string]::IsNullOrWhiteSpace($utilitiesModulesDir) -and (Test-Path -LiteralPath $utilitiesModulesDir)) {
        $networkDir = Join-Path $utilitiesModulesDir 'network'
        if ($networkDir -and -not [string]::IsNullOrWhiteSpace($networkDir) -and (Test-Path -LiteralPath $networkDir)) {
            $modulePath = Join-Path $networkDir 'utilities-network-advanced.ps1'
            if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                try {
                    . $modulePath
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                            Write-ProfileError -ErrorRecord $_ -Context "Fragment: network-utils (utilities-network-advanced.ps1)" -Category 'Fragment'
                        }
                        else {
                            Write-Warning "Failed to load network utility module utilities-network-advanced.ps1 : $($_.Exception.Message)"
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
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: network-utils" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load network utils fragment: $($_.Exception.Message)"
        }
    }
}
