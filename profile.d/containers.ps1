# ===============================================
# containers.ps1
# Container engine helpers (Docker/Podman) and Compose utilities
# ===============================================
# Provides unified container management functions that work with either Docker or Podman.
# Functions automatically detect available engines and prefer Docker, falling back to Podman.
# All helpers are idempotent and check for engine availability before executing commands.

# Load container utility modules (loaded eagerly as they provide commonly-used container helpers)
# Use standardized module loading if available, otherwise fall back to manual loading
# Tier: essential
# Dependencies: bootstrap, env
# Environment: containers, development
if (Get-Command Import-FragmentModules -ErrorAction SilentlyContinue) {
    try {
        $modules = @(
            @{ ModulePath = @('container-modules', 'container-helpers.ps1'); Context = 'Fragment: containers (container-helpers.ps1)' },
            @{ ModulePath = @('container-modules', 'container-compose.ps1'); Context = 'Fragment: containers (container-compose.ps1)' },
            @{ ModulePath = @('container-modules', 'container-compose-podman.ps1'); Context = 'Fragment: containers (container-compose-podman.ps1)' }
        )
        
        $result = Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules $modules
        
        if ($env:PS_PROFILE_DEBUG -and $result.FailureCount -gt 0) {
            Write-Verbose "Loaded $($result.SuccessCount) container modules (failed: $($result.FailureCount))"
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                Write-ProfileError -ErrorRecord $_ -Context "Fragment: containers" -Category 'Fragment'
            }
            else {
                Write-Warning "Failed to load containers fragment: $($_.Exception.Message)"
            }
        }
    }
}
else {
    # Fallback: manual loading for environments where Import-FragmentModules is not yet available
    try {
        $containerModulesDir = Join-Path $PSScriptRoot 'container-modules'
        if ($containerModulesDir -and -not [string]::IsNullOrWhiteSpace($containerModulesDir) -and (Test-Path -LiteralPath $containerModulesDir)) {
            $containerModules = @(
                'container-helpers.ps1',
                'container-compose.ps1',
                'container-compose-podman.ps1'
            )
            
            foreach ($moduleFile in $containerModules) {
                $modulePath = Join-Path $containerModulesDir $moduleFile
                if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                    try {
                        . $modulePath
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                                Write-ProfileError -ErrorRecord $_ -Context "Fragment: containers ($moduleFile)" -Category 'Fragment'
                            }
                            else {
                                Write-Warning "Failed to load container module $moduleFile : $($_.Exception.Message)"
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
                Write-ProfileError -ErrorRecord $_ -Context "Fragment: containers" -Category 'Fragment'
            }
            else {
                Write-Warning "Failed to load containers fragment: $($_.Exception.Message)"
            }
        }
    }
}
