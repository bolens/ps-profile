<#
scripts/utils/check-module-updates.ps1

Checks for available updates to PowerShell modules in the Modules directory
and other commonly used modules.

Usage: pwsh -NoProfile -File scripts/utils/check-module-updates.ps1
#>

param(
    [switch]$Update
)

Write-Output "Checking for PowerShell module updates..."

# Get modules in the local Modules directory
$localModulesPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'Modules'
$localModules = @()

if (Test-Path $localModulesPath) {
    $localModules = Get-ChildItem -Path $localModulesPath -Directory | ForEach-Object {
        $modulePath = Join-Path $_.FullName "$($_.Name).psd1"
        if (Test-Path $modulePath) {
            try {
                $moduleInfo = Import-PowerShellDataFile -Path $modulePath
                [PSCustomObject]@{
                    Name = $_.Name
                    Version = $moduleInfo.ModuleVersion
                    Path = $_.FullName
                    Source = "Local"
                }
            } catch {
                Write-Warning "Failed to read module info for $($_.Name): $($_.Exception.Message)"
            }
        }
    }
}

# Check for updates from PowerShell Gallery
$modulesToCheck = @(
    # Local modules
    $localModules | Select-Object -ExpandProperty Name
    # Commonly used modules that might be installed
    'PSScriptAnalyzer',
    'Pester',
    'PowerShell-Beautifier',
    'platyPS'
) | Select-Object -Unique

$updatesAvailable = @()

foreach ($moduleName in $modulesToCheck) {
    try {
        Write-Output "Checking $moduleName..."

        # Get installed version
        $installed = Get-Module -Name $moduleName -ListAvailable -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending | Select-Object -First 1

        if ($installed) {
            # Check PowerShell Gallery for latest version
            $galleryInfo = Find-Module -Name $moduleName -ErrorAction SilentlyContinue

            if ($galleryInfo -and [version]$galleryInfo.Version -gt [version]$installed.Version) {
                $updatesAvailable += [PSCustomObject]@{
                    Name = $moduleName
                    CurrentVersion = $installed.Version.ToString()
                    LatestVersion = $galleryInfo.Version
                    Source = if ($localModules | Where-Object { $_.Name -eq $moduleName }) { "Local" } else { "System" }
                }
            }
        } else {
            Write-Warning "Module $moduleName is not installed"
        }
    } catch {
        Write-Warning "Failed to check updates for $moduleName`: $($_.Exception.Message)"
    }
}

if ($updatesAvailable.Count -gt 0) {
    Write-Output "`nUpdates available:"
    $updatesAvailable | Format-Table -AutoSize

    if ($Update) {
        Write-Output "`nUpdating modules..."
        foreach ($update in $updatesAvailable) {
            try {
                Write-Output "Updating $($update.Name) from $($update.CurrentVersion) to $($update.LatestVersion)..."
                if ($update.Source -eq "Local") {
                    # For local modules, update in place
                    Update-Module -Name $update.Name -RequiredVersion $update.LatestVersion -Force -ErrorAction Stop
                } else {
                    # For system modules, update normally
                    Install-Module -Name $update.Name -RequiredVersion $update.LatestVersion -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                }
                Write-Output "✓ Updated $($update.Name)"
            } catch {
                Write-Warning "Failed to update $($update.Name): $($_.Exception.Message)"
            }
        }
    } else {
        Write-Output "`nRun with -Update switch to install updates"
    }
} else {
    Write-Output "`nAll modules are up to date"
}

exit 0
