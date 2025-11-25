<#
scripts/utils/dependencies/modules/ModuleUpdateChecker.psm1

.SYNOPSIS
    Module update checking utilities.

.DESCRIPTION
    Provides functions for checking module versions and detecting available updates.
#>

<#
.SYNOPSIS
    Gets local modules from the Modules directory.

.DESCRIPTION
    Scans the Modules directory and extracts module information including name and version.

.PARAMETER LocalModulesPath
    Path to the local Modules directory.

.OUTPUTS
    Array of PSCustomObject with Name, Version, Path, and Source properties.
#>
function Get-LocalModules {
    param(
        [Parameter(Mandatory)]
        [string]$LocalModulesPath
    )

    $localModules = @()

    if (Test-Path $LocalModulesPath) {
        $localModules = Get-ChildItem -Path $LocalModulesPath -Directory | ForEach-Object {
            $modulePath = Join-Path $_.FullName "$($_.Name).psd1"
            if (Test-Path $modulePath) {
                try {
                    $moduleInfo = Import-CachedPowerShellDataFile -Path $modulePath
                    [PSCustomObject]@{
                        Name    = $_.Name
                        Version = $moduleInfo.ModuleVersion
                        Path    = $_.FullName
                        Source  = "Local"
                    }
                }
                catch {
                    Write-ScriptMessage -Message "Failed to read module info for $($_.Name): $($_.Exception.Message)" -IsWarning
                }
            }
        }
    }

    return $localModules
}

<#
.SYNOPSIS
    Checks for available updates for a single module.

.DESCRIPTION
    Checks if a module has updates available by comparing installed version with gallery version.

.PARAMETER ModuleName
    Name of the module to check.

.PARAMETER LocalModules
    Array of local module objects to check against.

.OUTPUTS
    PSCustomObject with Name, CurrentVersion, LatestVersion, and Source properties if update available, otherwise null.
#>
function Test-ModuleUpdate {
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [array]$LocalModules = @()
    )

    try {
        # Try to get cached module version first (cache for 5 minutes)
        $cacheKey = "ModuleVersion_$ModuleName"
        $cachedVersion = Get-CachedValue -Key $cacheKey

        if ($null -ne $cachedVersion) {
            Write-Verbose "Using cached version info for $ModuleName"
            $installed = $cachedVersion.Installed
            $galleryInfo = $cachedVersion.Gallery
        }
        else {
            # Get installed version with retry logic
            $maxRetries = 3
            $retryCount = 0
            $installed = $null

            while ($retryCount -lt $maxRetries -and $null -eq $installed) {
                try {
                    $installed = Get-Module -Name $ModuleName -ListAvailable -ErrorAction Stop |
                    Sort-Object Version -Descending | Select-Object -First 1
                }
                catch {
                    $retryCount++
                    if ($retryCount -lt $maxRetries) {
                        Write-Verbose "Retry $retryCount/$maxRetries for Get-Module $ModuleName"
                        Start-Sleep -Milliseconds (500 * $retryCount)  # Exponential backoff
                    }
                    else {
                        throw
                    }
                }
            }

            # Check PowerShell Gallery for latest version with retry logic
            $galleryInfo = $null
            $retryCount = 0

            while ($retryCount -lt $maxRetries -and $null -eq $galleryInfo) {
                try {
                    $galleryInfo = Find-Module -Name $ModuleName -ErrorAction Stop
                }
                catch {
                    $retryCount++
                    if ($retryCount -lt $maxRetries) {
                        Write-Verbose "Retry $retryCount/$maxRetries for Find-Module $ModuleName"
                        Start-Sleep -Milliseconds (500 * $retryCount)  # Exponential backoff
                    }
                    else {
                        Write-Verbose "Could not find module $ModuleName in gallery (may not be published)"
                        $galleryInfo = $null
                    }
                }
            }

            # Cache the results for 5 minutes
            if ($null -ne $installed -or $null -ne $galleryInfo) {
                Set-CachedValue -Key $cacheKey -Value @{
                    Installed = $installed
                    Gallery   = $galleryInfo
                } -ExpirationSeconds 300
            }
        }

        if ($installed) {
            if ($galleryInfo -and [version]$galleryInfo.Version -gt [version]$installed.Version) {
                return [PSCustomObject]@{
                    Name           = $ModuleName
                    CurrentVersion = $installed.Version.ToString()
                    LatestVersion  = $galleryInfo.Version
                    Source         = if ($LocalModules | Where-Object { $_.Name -eq $ModuleName }) { "Local" } else { "System" }
                }
            }
        }
        else {
            Write-ScriptMessage -Message "Module $ModuleName is not installed" -IsWarning
        }
    }
    catch {
        Write-ScriptMessage -Message "Failed to check updates for $ModuleName`: $($_.Exception.Message)" -IsWarning
    }

    return $null
}

<#
.SYNOPSIS
    Checks for available updates for multiple modules.

.DESCRIPTION
    Checks multiple modules for available updates and returns a list of updates.

.PARAMETER ModulesToCheck
    Array of module names to check.

.PARAMETER LocalModules
    Array of local module objects.

.OUTPUTS
    List of PSCustomObject with update information.
#>
function Get-ModuleUpdates {
    param(
        [Parameter(Mandatory)]
        [string[]]$ModulesToCheck,

        [array]$LocalModules = @()
    )

    $updatesAvailable = [System.Collections.Generic.List[PSCustomObject]]::new()

    $totalModules = $ModulesToCheck.Count
    $currentModule = 0

    foreach ($moduleName in $ModulesToCheck) {
        $currentModule++
        $percentComplete = [math]::Round(($currentModule / $totalModules) * 100)

        Write-Progress -Activity "Checking module updates" -Status "Checking $moduleName ($currentModule/$totalModules)" -PercentComplete $percentComplete
        Write-ScriptMessage -Message "[$currentModule/$totalModules] Checking $moduleName..."

        $update = Test-ModuleUpdate -ModuleName $moduleName -LocalModules $LocalModules
        if ($update) {
            $updatesAvailable.Add($update)
        }
    }

    Write-Progress -Activity "Checking module updates" -Completed

    return $updatesAvailable
}

Export-ModuleMember -Function @(
    'Get-LocalModules',
    'Test-ModuleUpdate',
    'Get-ModuleUpdates'
)

