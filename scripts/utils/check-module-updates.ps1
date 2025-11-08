<#
scripts/utils/check-module-updates.ps1

.SYNOPSIS
    Checks for available updates to PowerShell modules.

.DESCRIPTION
    Checks for available updates to PowerShell modules in the Modules directory and other
    commonly used modules like PSScriptAnalyzer, Pester, and PowerShell-Beautifier. Compares
    installed versions with latest versions available in the PowerShell Gallery.

.PARAMETER Update
    If specified, automatically updates all modules that have available updates. Otherwise,
    only reports available updates without installing them.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\check-module-updates.ps1

    Checks for available module updates and displays them.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\check-module-updates.ps1 -Update

    Checks for updates and automatically installs them.
#>

param(
    [switch]$Update
)

# Import shared utilities
$commonModulePath = Join-Path $PSScriptRoot 'Common.psm1'
Import-Module $commonModulePath -ErrorAction Stop

Write-ScriptMessage -Message "Checking for PowerShell module updates..."

# Get repository root and modules directory
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $localModulesPath = Join-Path $repoRoot 'Modules'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$localModules = @()

if (Test-Path $localModulesPath) {
    $localModules = Get-ChildItem -Path $localModulesPath -Directory | ForEach-Object {
        $modulePath = Join-Path $_.FullName "$($_.Name).psd1"
        if (Test-Path $modulePath) {
            try {
                $moduleInfo = Import-PowerShellDataFile -Path $modulePath
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

# Check for updates from PowerShell Gallery
$modulesToCheck = @(
    # Local modules
    $localModules | Select-Object -ExpandProperty Name
    # Commonly used modules that might be installed
    'PSScriptAnalyzer',
    'Pester',
    'PowerShell-Beautifier'
) | Select-Object -Unique

# Use List for better performance than array concatenation
$updatesAvailable = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($moduleName in $modulesToCheck) {
    try {
        Write-ScriptMessage -Message "Checking $moduleName..."

        # Get installed version
        $installed = Get-Module -Name $moduleName -ListAvailable -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending | Select-Object -First 1

        if ($installed) {
            # Check PowerShell Gallery for latest version
            $galleryInfo = Find-Module -Name $moduleName -ErrorAction SilentlyContinue

            if ($galleryInfo -and [version]$galleryInfo.Version -gt [version]$installed.Version) {
                $updatesAvailable.Add([PSCustomObject]@{
                        Name           = $moduleName
                        CurrentVersion = $installed.Version.ToString()
                        LatestVersion  = $galleryInfo.Version
                        Source         = if ($localModules | Where-Object { $_.Name -eq $moduleName }) { "Local" } else { "System" }
                    })
            }
        }
        else {
            Write-ScriptMessage -Message "Module $moduleName is not installed" -IsWarning
        }
    }
    catch {
        Write-ScriptMessage -Message "Failed to check updates for $moduleName`: $($_.Exception.Message)" -IsWarning
    }
}

if ($updatesAvailable.Count -gt 0) {
    Write-ScriptMessage -Message "`nUpdates available:"
    $updatesAvailable | Format-Table -AutoSize

    if ($Update) {
        Write-ScriptMessage -Message "`nUpdating modules..."
        foreach ($moduleUpdate in $updatesAvailable) {
            try {
                Write-ScriptMessage -Message "Updating $($moduleUpdate.Name) from $($moduleUpdate.CurrentVersion) to $($moduleUpdate.LatestVersion)..."
                if ($moduleUpdate.Source -eq "Local") {
                    # For local modules, update in place
                    Update-Module -Name $moduleUpdate.Name -RequiredVersion $moduleUpdate.LatestVersion -Force -ErrorAction Stop
                }
                else {
                    # For system modules, update normally
                    Install-Module -Name $moduleUpdate.Name -RequiredVersion $moduleUpdate.LatestVersion -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                }
                Write-ScriptMessage -Message "✓ Updated $($moduleUpdate.Name)"
            }
            catch {
                Write-ScriptMessage -Message "Failed to update $($moduleUpdate.Name): $($_.Exception.Message)" -IsWarning
            }
        }
    }
    else {
        Write-ScriptMessage -Message "`nRun with -Update switch to install updates"
    }
}
else {
    Write-ScriptMessage -Message "`nAll modules are up to date"
}

Exit-WithCode -ExitCode $EXIT_SUCCESS
