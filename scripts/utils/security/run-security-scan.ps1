<#
scripts/utils/run-security-scan.ps1

.SYNOPSIS
    Runs security-focused analysis on PowerShell scripts using PSScriptAnalyzer.

.DESCRIPTION
    Runs security-focused analysis on PowerShell scripts using PSScriptAnalyzer with
    security-specific rules. Checks for common security issues like plain text passwords,
    use of Invoke-Expression, and other security anti-patterns.

.PARAMETER Path
    The path to scan. Defaults to profile.d directory relative to repository root.

.PARAMETER AllowlistFile
    Optional path to a custom allowlist JSON file.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-security-scan.ps1

    Runs security scan on all PowerShell files in the profile.d directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-security-scan.ps1 -Path scripts

    Runs security scan on all PowerShell files in the scripts directory.
#>

param(
    [ValidateScript({
            if ($_ -and -not (Test-Path $_)) {
                throw "Path does not exist: $_"
            }
            $true
        })]
    [string]$Path = $null,

    [string]$AllowlistFile = $null
)

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Module' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'FileSystem' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathValidation' -ScriptPath $PSScriptRoot -DisableNameChecking

# Import security modules
$modulesPath = Join-Path $PSScriptRoot 'modules'
Import-Module (Join-Path $modulesPath 'SecurityAllowlist.psm1') -ErrorAction Stop
Import-Module (Join-Path $modulesPath 'SecurityRules.psm1') -ErrorAction Stop
Import-Module (Join-Path $modulesPath 'SecurityPatterns.psm1') -ErrorAction Stop
Import-Module (Join-Path $modulesPath 'SecurityScanner.psm1') -ErrorAction Stop
Import-Module (Join-Path $modulesPath 'SecurityReporter.psm1') -ErrorAction Stop

# Default to profile.d relative to the repository root
try {
    $defaultPath = Get-ProfileDirectory -ScriptPath $PSScriptRoot
    $Path = Resolve-DefaultPath -Path $Path -DefaultPath $defaultPath -PathType 'Directory'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Write-ScriptMessage -Message "Running security scan on: $Path"

# Ensure PSScriptAnalyzer is available
try {
    Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Load allowlist
$defaultAllowlist = Get-DefaultAllowlist
if ($AllowlistFile) {
    $allowlist = Get-AllowlistFromFile -AllowlistFile $AllowlistFile -DefaultAllowlist $defaultAllowlist
}
else {
    $allowlist = $defaultAllowlist
}

# Get security rules and patterns
$securityRules = Get-SecurityRules
$externalCommandPatterns = Get-ExternalCommandPatterns
$secretPatterns = Get-SecretPatterns
$falsePositivePatterns = Get-FalsePositivePatterns

# Get PowerShell scripts using helper function
$scripts = Get-PowerShellScripts -Path $Path

# Process files sequentially for reliability
Write-ScriptMessage -Message "Scanning $($scripts.Count) file(s) for security issues..."

# Use List for better performance than array concatenation
$securityIssues = [System.Collections.Generic.List[PSCustomObject]]::new()

# Scan each file
foreach ($script in $scripts) {
    $fileIssues = Invoke-SecurityScan -FilePath $script.FullName -SecurityRules $securityRules -ExternalCommandPatterns $externalCommandPatterns -SecretPatterns $secretPatterns -FalsePositivePatterns $falsePositivePatterns -Allowlist $allowlist
    
    foreach ($issue in $fileIssues) {
        $securityIssues.Add($issue)
    }
}

# Process results
$results = Get-SecurityScanResults -SecurityIssues $securityIssues.ToArray()

# Check for scan errors that should cause failure
if ($results.ScanErrors.Count -gt 0) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to scan $($results.ScanErrors.Count) file(s). Check warnings above for details."
}

# Display results
Write-SecurityReport -Results $results

# Exit with appropriate code
if ($results.BlockingIssues.Count -gt 0) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Found $($results.BlockingIssues.Count) security-related error(s)"
}

if ($results.WarningIssues.Count -gt 0) {
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Security scan completed with $($results.WarningIssues.Count) warning(s)"
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Security scan completed: no issues found"
