<#
scripts/dev/setup.ps1

.SYNOPSIS
    Sets up development environment for PowerShell profile development.

.DESCRIPTION
    Installs required modules and tools for development, including:
    - PSScriptAnalyzer for linting
    - Pester for testing
    - Other development dependencies

.EXAMPLE
    pwsh -NoProfile -File scripts\dev\setup.ps1

    Sets up the development environment.
#>

# Import shared utilities
$commonModulePath = Join-Path $PSScriptRoot '..' 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

Write-ScriptMessage -Message "Setting up development environment..." -LogLevel Info

# Required modules for development
$requiredModules = @(
    'PSScriptAnalyzer',
    'Pester'
)

$installedCount = 0
$failedModules = [System.Collections.Generic.List[string]]::new()

foreach ($moduleName in $requiredModules) {
    try {
        Write-ScriptMessage -Message "Installing $moduleName..." -LogLevel Info
        Ensure-ModuleAvailable -ModuleName $moduleName
        $installedCount++
        Write-ScriptMessage -Message "✓ $moduleName installed" -LogLevel Info
    }
    catch {
        Write-ScriptMessage -Message "Failed to install $moduleName`: $($_.Exception.Message)" -IsWarning
        $failedModules.Add($moduleName)
    }
}

Write-ScriptMessage -Message "`nSetup Summary:" -LogLevel Info
Write-ScriptMessage -Message "  Installed: $installedCount/$($requiredModules.Count) modules" -LogLevel Info

if ($failedModules.Count -gt 0) {
    Write-ScriptMessage -Message "  Failed: $($failedModules -join ', ')" -IsWarning
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Some modules failed to install"
}

Write-ScriptMessage -Message "`nDevelopment environment setup complete!" -LogLevel Info
Exit-WithCode -ExitCode $EXIT_SUCCESS


