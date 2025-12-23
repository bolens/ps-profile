# ===============================================
# system.ps1
# System utilities (shell-like helpers adapted for PowerShell)
# ===============================================
# Provides Unix-style command aliases and helper functions for common system operations.
# These functions wrap PowerShell cmdlets to provide familiar command names for users
# coming from Unix/Linux environments or who prefer shorter command names.

# Load system utility modules in logical order
# Use standardized module loading if available, otherwise fall back to manual loading
# Tier: essential
# Dependencies: bootstrap, env
if (Get-Command Import-FragmentModules -ErrorAction SilentlyContinue) {
    try {
        $modules = @(
            @{ ModulePath = @('system', 'FileOperations.ps1'); Context = 'Fragment: system (FileOperations.ps1)' },
            @{ ModulePath = @('system', 'SystemInfo.ps1'); Context = 'Fragment: system (SystemInfo.ps1)' },
            @{ ModulePath = @('system', 'NetworkOperations.ps1'); Context = 'Fragment: system (NetworkOperations.ps1)' },
            @{ ModulePath = @('system', 'ArchiveOperations.ps1'); Context = 'Fragment: system (ArchiveOperations.ps1)' },
            @{ ModulePath = @('system', 'EditorAliases.ps1'); Context = 'Fragment: system (EditorAliases.ps1)' },
            @{ ModulePath = @('system', 'TextSearch.ps1'); Context = 'Fragment: system (TextSearch.ps1)' }
        )
        
        $result = Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules $modules
        
        if ($env:PS_PROFILE_DEBUG -and $result.FailureCount -gt 0) {
            Write-Verbose "Loaded $($result.SuccessCount) system modules (failed: $($result.FailureCount))"
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                Write-ProfileError -ErrorRecord $_ -Context "Fragment: system" -Category 'Fragment'
            }
            else {
                Write-Warning "Failed to load system utilities fragment: $($_.Exception.Message)"
            }
        }
    }
}
else {
    # Fallback: manual loading for environments where Import-FragmentModules is not yet available
    try {
        $systemModulesDir = Join-Path $PSScriptRoot 'system'
        
        if ($systemModulesDir -and -not [string]::IsNullOrWhiteSpace($systemModulesDir) -and (Test-Path -LiteralPath $systemModulesDir)) {
            # Load system utility modules in logical order
            $moduleFiles = @(
                'FileOperations.ps1',
                'SystemInfo.ps1',
                'NetworkOperations.ps1',
                'ArchiveOperations.ps1',
                'EditorAliases.ps1',
                'TextSearch.ps1'
            )
            
            foreach ($moduleFile in $moduleFiles) {
                $modulePath = Join-Path $systemModulesDir $moduleFile
                if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                    try {
                        . $modulePath
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                                Write-ProfileError -ErrorRecord $_ -Context "Fragment: system ($moduleFile)" -Category 'Fragment'
                            }
                            else {
                                Write-Warning "Failed to load $moduleFile : $($_.Exception.Message)"
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
                Write-ProfileError -ErrorRecord $_ -Context "Fragment: system" -Category 'Fragment'
            }
            else {
                Write-Warning "Failed to load system utilities fragment: $($_.Exception.Message)"
            }
        }
    }
}
