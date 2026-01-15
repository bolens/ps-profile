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
            if ($_ -and -not [string]::IsNullOrWhiteSpace($_) -and -not (Test-Path -LiteralPath $_)) {
                throw "Path does not exist: $_"
            }
            $true
        })]
    [string]$Path = $null,

    [string]$AllowlistFile = $null
)

# Import shared utilities directly (no barrel files)
# Import PathResolution first (required for ModuleImport to work)
$scriptsDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pathResolutionPath = Join-Path $scriptsDir 'lib' 'path' 'PathResolution.psm1'
if ($pathResolutionPath -and -not [string]::IsNullOrWhiteSpace($pathResolutionPath) -and -not (Test-Path -LiteralPath $pathResolutionPath)) {
    throw "PathResolution module not found at: $pathResolutionPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction Stop

# Import ModuleImport (bootstrap)
$moduleImportPath = Join-Path $scriptsDir 'lib' 'ModuleImport.psm1'
if ($moduleImportPath -and -not [string]::IsNullOrWhiteSpace($moduleImportPath) -and -not (Test-Path -LiteralPath $moduleImportPath)) {
    throw "ModuleImport module not found at: $moduleImportPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Module' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'FileSystem' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathValidation' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Import security modules
$modulesPath = Join-Path $PSScriptRoot 'modules'
Import-Module (Join-Path $modulesPath 'SecurityAllowlist.psm1') -ErrorAction Stop
Import-Module (Join-Path $modulesPath 'SecurityRules.psm1') -ErrorAction Stop
Import-Module (Join-Path $modulesPath 'SecurityPatterns.psm1') -ErrorAction Stop
Import-Module (Join-Path $modulesPath 'SecurityScanner.psm1') -ErrorAction Stop
Import-Module (Join-Path $modulesPath 'SecurityReporter.psm1') -ErrorAction Stop

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Default to profile.d relative to the repository root
try {
    $defaultPath = Get-ProfileDirectory -ScriptPath $PSScriptRoot
    $Path = Resolve-DefaultPath -Path $Path -DefaultPath $defaultPath -PathType 'Directory'
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[security.scan] Starting security scan"
    Write-Verbose "[security.scan] Target path: $Path"
    if ($AllowlistFile) {
        Write-Verbose "[security.scan] Using allowlist file: $AllowlistFile"
    }
}

Write-ScriptMessage -Message "Running security scan on: $Path"

# Ensure PSScriptAnalyzer is available
try {
    Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
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

# Level 2: File list details
if ($debugLevel -ge 2) {
    Write-Verbose "[security.scan] Found $($scripts.Count) PowerShell script(s) to scan"
}

# Process files sequentially for reliability
Write-ScriptMessage -Message "Scanning $($scripts.Count) file(s) for security issues..."

# Use List for better performance than array concatenation
$securityIssues = [System.Collections.Generic.List[PSCustomObject]]::new()

# Scan each file
$failedFiles = [System.Collections.Generic.List[string]]::new()
$scanStartTime = Get-Date
foreach ($script in $scripts) {
    # Level 1: Individual file scanning
    if ($debugLevel -ge 1) {
        Write-Verbose "[security.scan] Scanning file: $($script.Name)"
    }
    
    $fileStartTime = Get-Date
    try {
        $fileIssues = Invoke-SecurityScan -FilePath $script.FullName -SecurityRules $securityRules -ExternalCommandPatterns $externalCommandPatterns -SecretPatterns $secretPatterns -FalsePositivePatterns $falsePositivePatterns -Allowlist $allowlist -ErrorAction Stop
        
        $fileDuration = ((Get-Date) - $fileStartTime).TotalMilliseconds
        
        if ($fileIssues) {
            foreach ($issue in $fileIssues) {
                $securityIssues.Add($issue)
            }
            
            # Level 2: File scan timing and results
            if ($debugLevel -ge 2) {
                Write-Verbose "[security.scan] File $($script.Name) scanned in ${fileDuration}ms - Found $($fileIssues.Count) issue(s)"
            }
        }
        else {
            # Level 2: File scan timing (no issues)
            if ($debugLevel -ge 2) {
                Write-Verbose "[security.scan] File $($script.Name) scanned in ${fileDuration}ms - No issues found"
            }
        }
    }
    catch {
        $failedFiles.Add($script.FullName)
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'security.scan.file' -Context @{
                file_path = $script.FullName
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to scan file $($script.FullName): $($_.Exception.Message)" -IsWarning
        }
    }
}

if ($failedFiles.Count -gt 0) {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        Write-StructuredWarning -Message "Some files failed during security scan" -OperationName 'security.scan' -Context @{
            failed_files = $failedFiles -join ','
            failed_count = $failedFiles.Count
            total_files = $scripts.Count
        } -Code 'SecurityScanPartialFailure'
    }
    else {
        Write-ScriptMessage -Message "Warning: Failed to scan $($failedFiles.Count) file(s): $($failedFiles -join ', ')" -IsWarning
    }
    
    # If all files failed, exit with error
    if ($failedFiles.Count -eq $scripts.Count) {
        Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "All files failed during security scan"
    }
}

$scanDuration = ((Get-Date) - $scanStartTime).TotalMilliseconds

# Level 2: Overall scan timing
if ($debugLevel -ge 2) {
    Write-Verbose "[security.scan] Scan completed in ${scanDuration}ms"
    Write-Verbose "[security.scan] Total issues found: $($securityIssues.Count), Failed files: $($failedFiles.Count)"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $avgFileTime = if ($scripts.Count -gt 0) { $scanDuration / $scripts.Count } else { 0 }
    Write-Host "  [security.scan] Performance - Duration: ${scanDuration}ms, Avg per file: ${avgFileTime}ms, Files: $($scripts.Count), Issues: $($securityIssues.Count)" -ForegroundColor DarkGray
}

# Process results
$results = Get-SecurityScanResults -SecurityIssues $securityIssues.ToArray()

# Level 1: Results processing
if ($debugLevel -ge 1) {
    Write-Verbose "[security.scan] Processing scan results"
}

# Check for scan errors that should cause failure
if ($results.ScanErrors.Count -gt 0) {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Failed to scan $($results.ScanErrors.Count) file(s). Check warnings above for details."
}

# Display results
Write-SecurityReport -Results $results

# Exit with appropriate code
if ($results.BlockingIssues.Count -gt 0) {
    Exit-WithCode -ExitCode [ExitCode]::ValidationFailure -Message "Found $($results.BlockingIssues.Count) security-related error(s)"
}

if ($results.WarningIssues.Count -gt 0) {
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "Security scan completed with $($results.WarningIssues.Count) warning(s)"
}

Exit-WithCode -ExitCode [ExitCode]::Success -Message "Security scan completed: no issues found"
