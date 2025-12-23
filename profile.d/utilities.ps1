# ===============================================
# utilities.ps1
# General-purpose utility functions for system, network, history, and filesystem operations
# ===============================================

# Load utility modules that provide system-level helper functions.
# These modules are loaded eagerly (not lazy) as they provide commonly-used utilities.
# Use standardized module loading if available, otherwise fall back to manual loading
# Tier: essential
# Dependencies: bootstrap, env
if (Get-Command Import-FragmentModules -ErrorAction SilentlyContinue) {
    try {
        $modules = @(
            # System utilities (profile management, security, environment)
            @{ ModulePath = @('utilities-modules', 'system', 'utilities-profile.ps1'); Context = 'Fragment: utilities (system/utilities-profile.ps1)' },
            @{ ModulePath = @('utilities-modules', 'system', 'utilities-security.ps1'); Context = 'Fragment: utilities (system/utilities-security.ps1)' },
            @{ ModulePath = @('utilities-modules', 'system', 'utilities-env.ps1'); Context = 'Fragment: utilities (system/utilities-env.ps1)' },
            # Network utilities (connectivity, DNS, port checking)
            @{ ModulePath = @('utilities-modules', 'network', 'utilities-network.ps1'); Context = 'Fragment: utilities (network/utilities-network.ps1)' },
            # Command history utilities (search, filtering, management)
            @{ ModulePath = @('utilities-modules', 'history', 'utilities-history.ps1'); Context = 'Fragment: utilities (history/utilities-history.ps1)' },
            # Data utilities (encoding, date/time manipulation)
            @{ ModulePath = @('utilities-modules', 'data', 'utilities-encoding.ps1'); Context = 'Fragment: utilities (data/utilities-encoding.ps1)' },
            @{ ModulePath = @('utilities-modules', 'data', 'utilities-datetime.ps1'); Context = 'Fragment: utilities (data/utilities-datetime.ps1)' },
            # Filesystem utilities (path manipulation, directory operations)
            @{ ModulePath = @('utilities-modules', 'filesystem', 'utilities-filesystem.ps1'); Context = 'Fragment: utilities (filesystem/utilities-filesystem.ps1)' }
        )
        
        $result = Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules $modules
        
        if ($env:PS_PROFILE_DEBUG -and $result.FailureCount -gt 0) {
            Write-Verbose "Loaded $($result.SuccessCount) utility modules (failed: $($result.FailureCount))"
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                Write-ProfileError -ErrorRecord $_ -Context "Fragment: utilities" -Category 'Fragment'
            }
            else {
                Write-Warning "Failed to load utilities fragment: $($_.Exception.Message)"
            }
        }
    }
}
else {
    # Fallback: manual loading for environments where Import-FragmentModules is not yet available
    try {
        $utilitiesModulesDir = Join-Path $PSScriptRoot 'utilities-modules'
        
        if ($utilitiesModulesDir -and -not [string]::IsNullOrWhiteSpace($utilitiesModulesDir) -and (Test-Path -LiteralPath $utilitiesModulesDir)) {
            # System utilities (profile management, security, environment)
            $systemDir = Join-Path $utilitiesModulesDir 'system'
            if ($systemDir -and -not [string]::IsNullOrWhiteSpace($systemDir) -and (Test-Path -LiteralPath $systemDir)) {
                $systemModules = @(
                    'utilities-profile.ps1',
                    'utilities-security.ps1',
                    'utilities-env.ps1'
                )
                
                foreach ($moduleFile in $systemModules) {
                    $modulePath = Join-Path $systemDir $moduleFile
                    if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                        try {
                            . $modulePath
                        }
                        catch {
                            if ($env:PS_PROFILE_DEBUG) {
                                if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                                    Write-ProfileError -ErrorRecord $_ -Context "Fragment: utilities (system/$moduleFile)" -Category 'Fragment'
                                }
                                else {
                                    Write-Warning "Failed to load system utility module $moduleFile : $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                }
            }
            
            # Network utilities (connectivity, DNS, port checking)
            $networkDir = Join-Path $utilitiesModulesDir 'network'
            if ($networkDir -and -not [string]::IsNullOrWhiteSpace($networkDir) -and (Test-Path -LiteralPath $networkDir)) {
                $modulePath = Join-Path $networkDir 'utilities-network.ps1'
                if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                    try {
                        . $modulePath
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                                Write-ProfileError -ErrorRecord $_ -Context "Fragment: utilities (network/utilities-network.ps1)" -Category 'Fragment'
                            }
                            else {
                                Write-Warning "Failed to load network utility module utilities-network.ps1 : $($_.Exception.Message)"
                            }
                        }
                    }
                }
            }
            
            # Command history utilities (search, filtering, management)
            $historyDir = Join-Path $utilitiesModulesDir 'history'
            if ($historyDir -and -not [string]::IsNullOrWhiteSpace($historyDir) -and (Test-Path -LiteralPath $historyDir)) {
                $modulePath = Join-Path $historyDir 'utilities-history.ps1'
                if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                    try {
                        . $modulePath
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                                Write-ProfileError -ErrorRecord $_ -Context "Fragment: utilities (history/utilities-history.ps1)" -Category 'Fragment'
                            }
                            else {
                                Write-Warning "Failed to load history utility module utilities-history.ps1 : $($_.Exception.Message)"
                            }
                        }
                    }
                }
            }
            
            # Data utilities (encoding, date/time manipulation)
            $dataDir = Join-Path $utilitiesModulesDir 'data'
            if ($dataDir -and -not [string]::IsNullOrWhiteSpace($dataDir) -and (Test-Path -LiteralPath $dataDir)) {
                $dataModules = @(
                    'utilities-encoding.ps1',
                    'utilities-datetime.ps1'
                )
                
                foreach ($moduleFile in $dataModules) {
                    $modulePath = Join-Path $dataDir $moduleFile
                    if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                        try {
                            . $modulePath
                        }
                        catch {
                            if ($env:PS_PROFILE_DEBUG) {
                                if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                                    Write-ProfileError -ErrorRecord $_ -Context "Fragment: utilities (data/$moduleFile)" -Category 'Fragment'
                                }
                                else {
                                    Write-Warning "Failed to load data utility module $moduleFile : $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                }
            }
            
            # Filesystem utilities (path manipulation, directory operations)
            $filesystemDir = Join-Path $utilitiesModulesDir 'filesystem'
            if ($filesystemDir -and -not [string]::IsNullOrWhiteSpace($filesystemDir) -and (Test-Path -LiteralPath $filesystemDir)) {
                $modulePath = Join-Path $filesystemDir 'utilities-filesystem.ps1'
                if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                    try {
                        . $modulePath
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                                Write-ProfileError -ErrorRecord $_ -Context "Fragment: utilities (filesystem/utilities-filesystem.ps1)" -Category 'Fragment'
                            }
                            else {
                                Write-Warning "Failed to load filesystem utility module utilities-filesystem.ps1 : $($_.Exception.Message)"
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
                Write-ProfileError -ErrorRecord $_ -Context "Fragment: utilities" -Category 'Fragment'
            }
            else {
                Write-Warning "Failed to load utilities fragment: $($_.Exception.Message)"
            }
        }
    }
}
