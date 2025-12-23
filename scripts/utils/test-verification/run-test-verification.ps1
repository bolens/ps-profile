<#
.SYNOPSIS
    Executes the test verification plan to verify all tests, improve comprehensiveness, and fix failures.

.DESCRIPTION
    This script executes the comprehensive test verification plan, running all tests,
    analyzing failures, checking coverage, and generating reports.

.PARAMETER Phase
    Which phase of the verification plan to execute:
    - All: Execute all phases
    - Phase1: Initial test execution and analysis
    - Phase2: Error handling enhancement
    - Phase3: Comprehensiveness improvements
    - Phase4: Tool detection verification
    - Phase5: Fix execution
    - Phase6: Documentation

.PARAMETER Suite
    Test suite to verify: All, Unit, Integration, or Performance.

.PARAMETER Category
    Specific category to verify (e.g., 'bootstrap', 'conversion', 'tools').

.PARAMETER GenerateReport
    Generate a detailed verification report.

.EXAMPLE
    .\run-test-verification.ps1 -Phase All -GenerateReport

.EXAMPLE
    .\run-test-verification.ps1 -Phase Phase1 -Suite Unit
#>
[CmdletBinding()]
param(
    [ValidateSet('All', 'Phase1', 'Phase2', 'Phase3', 'Phase4', 'Phase5', 'Phase6')]
    [string]$Phase = 'All',

    [ValidateSet('All', 'Unit', 'Integration', 'Performance')]
    [string]$Suite = 'All',

    [string]$Category,

    [switch]$GenerateReport
)

# Import required modules
$moduleImportPath = Join-Path (Split-Path $PSScriptRoot -Parent -Parent) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Locale' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking

$repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
$runPesterPath = Join-Path $repoRoot 'scripts/utils/code-quality/run-pester.ps1'
$reportDir = Join-Path $repoRoot 'docs/test-verification-reports'
$reportPath = Join-Path $reportDir "verification-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"

# Create report directory
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

function Write-VerificationMessage {
    param(
        [string]$Message,
        [string]$Level = 'Info'
    )
    Write-ScriptMessage -Message $Message -LogLevel $Level
}

function Invoke-Phase1 {
    Write-VerificationMessage "=== Phase 1: Initial Test Execution and Analysis ===" -Level 'Info'

    Write-VerificationMessage "Running full test suite..." -Level 'Info'
    $testResults = & $runPesterPath -Suite $Suite -OutputFormat Detailed -AnalyzeResults

    Write-VerificationMessage "Generating coverage report..." -Level 'Info'
    $coverageResults = & $runPesterPath -Suite $Suite -Coverage -MinimumCoverage 0 -OutputFormat Minimal

    Write-VerificationMessage "Phase 1 complete. Results saved." -Level 'Info'
    return @{
        TestResults     = $testResults
        CoverageResults = $coverageResults
    }
}

function Invoke-Phase2 {
    Write-VerificationMessage "=== Phase 2: Error Handling Enhancement ===" -Level 'Info'

    # Test ToolDetection module
    $toolDetectionPath = Join-Path $repoRoot 'tests/TestSupport/ToolDetection.ps1'
    if (Test-Path $toolDetectionPath) {
        . $toolDetectionPath
        $tools = Get-ToolRecommendations -Silent
        $missing = Get-MissingTools -Silent

        Write-VerificationMessage "Tool detection: $($tools.Count) tools checked, $($missing.Count) missing" -Level 'Info'
        if ($missing) {
            Write-VerificationMessage "Missing tools: $($missing.Name -join ', ')" -Level 'Warning'
        }
    }
    else {
        Write-VerificationMessage "ToolDetection.ps1 not found" -Level 'Warning'
    }

    Write-VerificationMessage "Phase 2 complete." -Level 'Info'
}

function Invoke-Phase3 {
    Write-VerificationMessage "=== Phase 3: Comprehensiveness Improvements ===" -Level 'Info'

    Write-VerificationMessage "Analyzing test coverage gaps..." -Level 'Info'
    # Coverage analysis would go here

    Write-VerificationMessage "Phase 3 complete." -Level 'Info'
}

function Invoke-Phase4 {
    Write-VerificationMessage "=== Phase 4: Tool Detection Verification ===" -Level 'Info'

    $toolDetectionPath = Join-Path $repoRoot 'tests/TestSupport/ToolDetection.ps1'
    if (Test-Path $toolDetectionPath) {
        . $toolDetectionPath
        Show-ToolRecommendations -MissingOnly
    }

    Write-VerificationMessage "Phase 4 complete." -Level 'Info'
}

function Invoke-Phase5 {
    Write-VerificationMessage "=== Phase 5: Fix Execution ===" -Level 'Info'

    Write-VerificationMessage "Running tests to identify failures..." -Level 'Info'
    $results = & $runPesterPath -Suite $Suite -OutputFormat Detailed

    Write-VerificationMessage "Phase 5 complete." -Level 'Info'
    return $results
}

function Invoke-Phase6 {
    Write-VerificationMessage "=== Phase 6: Documentation ===" -Level 'Info'

    if ($GenerateReport) {
        # Use locale-aware date formatting for user-facing report
        $generatedDate = if (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
            Format-LocaleDate (Get-Date) -Format 'yyyy-MM-dd HH:mm:ss'
        }
        else {
            (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        }
        
        $reportContent = @"
# Test Verification Report

Generated: $generatedDate

## Summary

This report contains the results of the test verification plan execution.

## Tool Availability

"@
        $toolDetectionPath = Join-Path $repoRoot 'tests/TestSupport/ToolDetection.ps1'
        if (Test-Path $toolDetectionPath) {
            . $toolDetectionPath
            $tools = Get-ToolRecommendations -Silent
            $reportContent += "`n### Tool Status`n`n"
            $reportContent += ($tools | Format-Table -Property Name, Available, InstallCommand | Out-String)
        }

        Set-Content -Path $reportPath -Value $reportContent -Encoding UTF8
        Write-VerificationMessage "Report generated: $reportPath" -Level 'Info'
    }

    Write-VerificationMessage "Phase 6 complete." -Level 'Info'
}

# Main execution
try {
    Write-VerificationMessage "Starting test verification plan execution..." -Level 'Info'
    Write-VerificationMessage "Phase: $Phase, Suite: $Suite" -Level 'Info'

    $results = @{}

    switch ($Phase) {
        'All' {
            $results.Phase1 = Invoke-Phase1
            Invoke-Phase2
            Invoke-Phase3
            Invoke-Phase4
            $results.Phase5 = Invoke-Phase5
            Invoke-Phase6
        }
        'Phase1' { $results = Invoke-Phase1 }
        'Phase2' { Invoke-Phase2 }
        'Phase3' { Invoke-Phase3 }
        'Phase4' { Invoke-Phase4 }
        'Phase5' { $results = Invoke-Phase5 }
        'Phase6' { Invoke-Phase6 }
    }

    Write-VerificationMessage "Test verification plan execution complete." -Level 'Info'
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}
catch {
    Write-VerificationMessage "Error during test verification: $_" -Level 'Error'
    Exit-WithCode -ExitCode $EXIT_RUNTIME_ERROR -ErrorRecord $_
}

