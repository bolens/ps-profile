<#
scripts/utils/dependencies/modules/ModuleUpdateInstaller.psm1

.SYNOPSIS
    Module update installation utilities.

.DESCRIPTION
    Provides functions for installing module updates with retry logic.
#>

# Import Retry module if available for consistent retry behavior
# Use safe path resolution that handles cases where $PSScriptRoot might not be set
try {
    if ($null -ne $PSScriptRoot -and -not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        # Start from the directory containing the script (or the script path itself if it's a directory)
        $currentDir = if ([System.IO.Directory]::Exists($PSScriptRoot)) {
            $PSScriptRoot
        }
        else {
            [System.IO.Path]::GetDirectoryName($PSScriptRoot)
        }
        
        $maxDepth = 4
        $depth = 0
        
        # Traverse up to repository root (4 levels: modules -> dependencies -> utils -> scripts -> repo root)
        while ($depth -lt $maxDepth -and $currentDir -and -not [string]::IsNullOrWhiteSpace($currentDir)) {
            $parentDir = [System.IO.Path]::GetDirectoryName($currentDir)
            if ([string]::IsNullOrWhiteSpace($parentDir) -or $parentDir -eq $currentDir) {
                break
            }
            $currentDir = $parentDir
            $depth++
        }
        
        if ($currentDir -and -not [string]::IsNullOrWhiteSpace($currentDir)) {
            $retryModulePath = Join-Path $currentDir 'scripts' 'lib' 'core' 'Retry.psm1'
            if (-not [string]::IsNullOrWhiteSpace($retryModulePath) -and (Test-Path -LiteralPath $retryModulePath -ErrorAction SilentlyContinue)) {
                Import-Module $retryModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }
}
catch {
    # Silently fail if path resolution fails - module will use fallback retry logic
}

<#
.SYNOPSIS
    Installs updates for a single module.

.DESCRIPTION
    Updates a module to the latest version with retry logic and error handling.

.PARAMETER ModuleUpdate
    Module update object with Name, LatestVersion, and Source properties.

.OUTPUTS
    Boolean indicating success.
#>
function Install-ModuleUpdate {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ModuleUpdate
    )

    try {
        # Use Retry module if available, otherwise fall back to manual retry logic
        if (Get-Command Invoke-WithRetry -ErrorAction SilentlyContinue) {
            Invoke-WithRetry -ScriptBlock {
                if ($ModuleUpdate.Source -eq "Local") {
                    # For local modules, update in place
                    Update-Module -Name $ModuleUpdate.Name -RequiredVersion $ModuleUpdate.LatestVersion -Force -ErrorAction Stop
                }
                else {
                    # For system modules, update normally
                    Install-Module -Name $ModuleUpdate.Name -RequiredVersion $ModuleUpdate.LatestVersion -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                }
                Write-ScriptMessage -Message "✓ Updated $($ModuleUpdate.Name)"

                # Clear cache for this module
                Clear-CachedValue -Key "ModuleVersion_$($ModuleUpdate.Name)"
            } -MaxRetries 3 -RetryDelaySeconds 2 -ExponentialBackoff -OnRetry {
                param($Attempt, $MaxRetries, $DelaySeconds, $Exception)
                Write-ScriptMessage -Message "Retry $Attempt/$MaxRetries for updating $($ModuleUpdate.Name)..." -IsWarning
            }
            return $true
        }
        else {
            # Fallback to manual retry logic
            $maxRetries = 3
            $retryCount = 0
            $updateSuccess = $false

            while ($retryCount -lt $maxRetries -and -not $updateSuccess) {
                try {
                    if ($ModuleUpdate.Source -eq "Local") {
                        # For local modules, update in place
                        Update-Module -Name $ModuleUpdate.Name -RequiredVersion $ModuleUpdate.LatestVersion -Force -ErrorAction Stop
                    }
                    else {
                        # For system modules, update normally
                        Install-Module -Name $ModuleUpdate.Name -RequiredVersion $ModuleUpdate.LatestVersion -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                    }
                    $updateSuccess = $true
                    Write-ScriptMessage -Message "✓ Updated $($ModuleUpdate.Name)"

                    # Clear cache for this module
                    Clear-CachedValue -Key "ModuleVersion_$($ModuleUpdate.Name)"
                }
                catch {
                    $retryCount++
                    if ($retryCount -lt $maxRetries) {
                        Write-ScriptMessage -Message "Retry $retryCount/$maxRetries for updating $($ModuleUpdate.Name)..." -IsWarning
                        Start-Sleep -Seconds (2 * $retryCount)  # Exponential backoff
                    }
                    else {
                        throw
                    }
                }
            }

            return $updateSuccess
        }
    }
    catch {
        Write-ScriptMessage -Message "Failed to update $($ModuleUpdate.Name): $($_.Exception.Message)" -IsWarning
        return $false
    }
}

<#
.SYNOPSIS
    Installs updates for multiple modules.

.DESCRIPTION
    Updates multiple modules with progress tracking.

.PARAMETER UpdatesAvailable
    List of module update objects to install.

.OUTPUTS
    Hashtable mapping module names to success status.
#>
function Install-ModuleUpdates {
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.List[PSCustomObject]]$UpdatesAvailable
    )

    $updatedModules = @{}
    $updateCount = 0
    $totalUpdates = $UpdatesAvailable.Count

    foreach ($moduleUpdate in $UpdatesAvailable) {
        $updateCount++
        $percentComplete = [math]::Round(($updateCount / $totalUpdates) * 100)

        Write-Progress -Activity "Updating modules" -Status "Updating $($moduleUpdate.Name) ($updateCount/$totalUpdates)" -PercentComplete $percentComplete

        Write-ScriptMessage -Message "[$updateCount/$totalUpdates] Updating $($moduleUpdate.Name) from $($moduleUpdate.CurrentVersion) to $($moduleUpdate.LatestVersion)..."

        $success = Install-ModuleUpdate -ModuleUpdate $moduleUpdate
        if ($success) {
            $updatedModules[$moduleUpdate.Name] = $true
        }
    }

    Write-Progress -Activity "Updating modules" -Completed

    return $updatedModules
}

Export-ModuleMember -Function @(
    'Install-ModuleUpdate',
    'Install-ModuleUpdates'
)

