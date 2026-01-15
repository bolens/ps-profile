<#
scripts/utils/run-lint.ps1

.SYNOPSIS
    Runs PSScriptAnalyzer against profile.d and scripts directories.

.DESCRIPTION
    Installs PSScriptAnalyzer if not present, then runs it against profile.d and scripts
    directories. This matches the CI lint task behavior exactly. Reports are saved to
    scripts/data/psscriptanalyzer-report.json. Exits with error code 1 if any Error-level
    findings are detected.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-lint.ps1

    Runs PSScriptAnalyzer on all PowerShell files in profile.d and scripts directories.
#>

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

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Cache' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathValidation' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PowerShellDetection' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Module' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'FileSystem' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'JsonUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[lint] Starting PSScriptAnalyzer linting"
    Write-Verbose "[lint] Repository root: $repoRoot"
}

# Analyze both profile.d and scripts directories, matching CI behavior
$paths = @(
    Join-Path $repoRoot 'profile.d'
    Join-Path $repoRoot 'scripts'
) | Where-Object { $_ -and -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) }

# Level 2: Path details
if ($debugLevel -ge 2) {
    Write-Verbose "[lint] Paths to analyze: $($paths -join ', ')"
}

if (-not $paths) {
    Write-ScriptMessage -Message "No paths found to analyze"
    Exit-WithCode -ExitCode [ExitCode]::Success
}

# Ensure PSScriptAnalyzer is available
try {
    Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

# Locate settings file if present
$settingsFile = Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1'
$settingsParam = @{}
if ($settingsFile -and -not [string]::IsNullOrWhiteSpace($settingsFile) -and (Test-Path -LiteralPath $settingsFile)) {
    Write-ScriptMessage -Message "Using settings file: $settingsFile"
    $settingsParam['Settings'] = $settingsFile
}

# Level 1: Analysis start
if ($debugLevel -ge 1) {
    Write-Verbose "[lint] Starting analysis of $($paths.Count) path(s)"
    if ($settingsFile) {
        Write-Verbose "[lint] Using settings file: $settingsFile"
    }
}

# Run analysis matching CI behavior exactly
# Use List for better performance than array concatenation
$results = [System.Collections.Generic.List[object]]::new()
$failedPaths = [System.Collections.Generic.List[string]]::new()
$lintStartTime = Get-Date
foreach ($p in $paths) {
    Write-ScriptMessage -Message "Analyzing $p"
    
    # Level 1: Individual path analysis
    if ($debugLevel -ge 1) {
        Write-Verbose "[lint] Analyzing path: $p"
    }
    
    $pathStartTime = Get-Date
    try {
        $r = Invoke-ScriptAnalyzer -Path $p -Recurse -Severity @('Error', 'Warning', 'Information') -Verbose @settingsParam -ErrorAction Stop
        $pathDuration = ((Get-Date) - $pathStartTime).TotalMilliseconds
        
        if ($r) {
            $results.AddRange($r)
            
            # Level 2: Path analysis timing
            if ($debugLevel -ge 2) {
                Write-Verbose "[lint] Path $p analyzed in ${pathDuration}ms - Found $($r.Count) issues"
            }
        }
    }
    catch {
        $failedPaths.Add($p)
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'lint.analyze-path' -Context @{
                path = $p
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to analyze $p`: $($_.Exception.Message)" -IsWarning
        }
        
        # Level 2: Error details
        if ($debugLevel -ge 2) {
            Write-Verbose "[lint] Path $p failed with error: $($_.Exception.Message)"
        }
    }
}

$lintDuration = ((Get-Date) - $lintStartTime).TotalMilliseconds

# Level 2: Overall timing
if ($debugLevel -ge 2) {
    Write-Verbose "[lint] Analysis completed in ${lintDuration}ms"
    Write-Verbose "[lint] Total issues found: $($results.Count), Failed paths: $($failedPaths.Count)"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $avgPathTime = if ($paths.Count -gt 0) { $lintDuration / $paths.Count } else { 0 }
    Write-Host "  [lint] Performance - Duration: ${lintDuration}ms, Avg per path: ${avgPathTime}ms, Paths: $($paths.Count), Issues: $($results.Count)" -ForegroundColor DarkGray
}

if ($failedPaths.Count -gt 0) {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        Write-StructuredWarning -Message "Some paths failed during linting" -OperationName 'lint.analyze' -Context @{
            failed_paths = $failedPaths -join ','
            failed_count = $failedPaths.Count
            total_paths  = $paths.Count
        } -Code 'LintPartialFailure'
    }
    else {
        Write-ScriptMessage -Message "Warning: Failed to analyze $($failedPaths.Count) path(s): $($failedPaths -join ', ')" -IsWarning
    }
    
    # If all paths failed, exit with error
    if ($failedPaths.Count -eq $paths.Count) {
        Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "All paths failed during linting"
    }
}

# Save report to JSON (matching CI behavior)
$reportData = $results | ForEach-Object {
    [PSCustomObject]@{
        FilePath = $_.ScriptName
        RuleName = $_.RuleName
        Severity = $_.Severity
        Message  = $_.Message
        Line     = $_.Line
        Column   = $_.Column
    }
}
$dataDir = Join-Path $repoRoot 'scripts' 'data'
$out = Join-Path $dataDir 'psscriptanalyzer-report.json'
Write-JsonFile -Path $out -InputObject $reportData -Depth 5 -EnsureDirectory
Write-ScriptMessage -Message "Saved report to $out"

# Fail if any Error-level findings (matching CI behavior)
$errorFindings = $results | Where-Object { $_.Severity -eq [SeverityLevel]::Error.ToString() }
if ($errorFindings) {
    Exit-WithCode -ExitCode [ExitCode]::ValidationFailure -Message "Errors found by PSScriptAnalyzer"
}

Exit-WithCode -ExitCode [ExitCode]::Success -Message "PSScriptAnalyzer: no issues found"


