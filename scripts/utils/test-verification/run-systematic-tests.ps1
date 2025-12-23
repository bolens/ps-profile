<#
.SYNOPSIS
    Runs tests systematically by category to identify failures for targeted fixing.

.DESCRIPTION
    Executes tests in a prioritized order (smallest to largest categories) to quickly
    identify failures and enable targeted fixing. Generates failure reports and
    pattern analysis.

.PARAMETER Category
    Run tests for a specific category only (e.g., 'Bootstrap', 'Tools', 'Conversion-Data').

.PARAMETER Priority
    Run tests up to a specific priority level (1-6).

.PARAMETER StopOnFailure
    Stop execution when first category has failures (default: false, continues through all).

.PARAMETER GenerateReport
    Generate detailed failure report and pattern analysis.

.EXAMPLE
    .\run-systematic-tests.ps1

.EXAMPLE
    .\run-systematic-tests.ps1 -Category Bootstrap

.EXAMPLE
    .\run-systematic-tests.ps1 -Priority 3 -StopOnFailure
#>
[CmdletBinding()]
param(
    [string]$Category,
    
    [ValidateRange(1, 6)]
    [int]$Priority = 6,
    
    [switch]$StopOnFailure,
    
    [switch]$GenerateReport
)

# Import required modules
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
try {
    Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop -Global
    
    Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
    Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
    Import-LibModule -ModuleName 'Locale' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
    Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
}
catch {
    Write-Host "Failed to import required modules: $_" -ForegroundColor Red
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
    else {
        Write-Error "Failed to import required modules: $($_.Exception.Message)" -ErrorAction Stop
    }
}

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $runPesterPath = Join-Path $repoRoot 'scripts/utils/code-quality/run-pester.ps1'
    $reportDir = Join-Path $repoRoot 'docs/test-verification-reports'
}
catch {
    Write-Host "Failed to get repository root: $_" -ForegroundColor Red
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
    else {
        Write-Error "Failed to get repository root: $($_.Exception.Message)" -ErrorAction Stop
    }
}

# Create report directory
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

function Write-CategoryMessage {
    param(
        [string]$Message,
        [string]$Level = 'Info'
    )
    if (Get-Command Write-ScriptMessage -ErrorAction SilentlyContinue) {
        Write-ScriptMessage -Message $Message -LogLevel $Level
    }
    else {
        $color = switch ($Level) {
            'Error' { 'Red' }
            'Warning' { 'Yellow' }
            'Info' { 'Cyan' }
            default { 'White' }
        }
        Write-Host $Message -ForegroundColor $color
    }
}

# Define test categories in execution order
$categories = @(
    # Priority 1: Small categories first (quick feedback)
    @{ Name = 'Bootstrap'; Path = 'tests/integration/bootstrap'; Priority = 1; Type = 'Integration' },
    @{ Name = 'Error-Handling'; Path = 'tests/integration/error-handling'; Priority = 1; Type = 'Integration' },
    @{ Name = 'Cross-Platform'; Path = 'tests/integration/cross-platform'; Priority = 1; Type = 'Integration' },
    @{ Name = 'Utilities'; Path = 'tests/integration/utilities'; Priority = 1; Type = 'Integration' },
    
    # Priority 2: Core functionality
    @{ Name = 'Profile'; Path = 'tests/integration/profile'; Priority = 2; Type = 'Integration' },
    @{ Name = 'Fragments'; Path = 'tests/integration/fragments'; Priority = 2; Type = 'Integration' },
    @{ Name = 'Filesystem'; Path = 'tests/integration/filesystem'; Priority = 2; Type = 'Integration' },
    
    # Priority 3: Feature categories
    @{ Name = 'Terminal'; Path = 'tests/integration/terminal'; Priority = 3; Type = 'Integration' },
    @{ Name = 'System'; Path = 'tests/integration/system'; Priority = 3; Type = 'Integration' },
    @{ Name = 'Test-Runner'; Path = 'tests/integration/test-runner'; Priority = 3; Type = 'Integration' },
    @{ Name = 'Tools'; Path = 'tests/integration/tools'; Priority = 3; Type = 'Integration' },
    
    # Priority 4: Large categories (run after fixing smaller issues)
    @{ Name = 'Conversion-Data'; Path = 'tests/integration/conversion/data'; Priority = 4; Type = 'Integration' },
    @{ Name = 'Conversion-Document'; Path = 'tests/integration/conversion/document'; Priority = 4; Type = 'Integration' },
    @{ Name = 'Conversion-Media'; Path = 'tests/integration/conversion/media'; Priority = 4; Type = 'Integration' },
    
    # Priority 5: Unit tests (run after integration tests are stable)
    @{ Name = 'Unit'; Path = 'tests/unit'; Priority = 5; Type = 'Unit' },
    
    # Priority 6: Performance tests (run last)
    @{ Name = 'Performance'; Path = 'tests/performance'; Priority = 6; Type = 'Performance' }
)

# Filter by category if specified
if ($Category) {
    $categories = $categories | Where-Object { $_.Name -eq $Category }
    if (-not $categories) {
        Write-CategoryMessage "Category '$Category' not found. Available categories: $($categories.Name -join ', ')" -Level 'Error'
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE
    }
}

# Filter by priority
$categories = $categories | Where-Object { $_.Priority -le $Priority }

# Sort by priority
$categories = $categories | Sort-Object Priority

Write-CategoryMessage "=== Systematic Test Execution ===" -Level 'Info'
Write-CategoryMessage "Categories to run: $($categories.Count)" -Level 'Info'
Write-CategoryMessage "Priority level: Up to $Priority" -Level 'Info'

$allResults = @()
$failureSummary = @()

foreach ($cat in $categories) {
    Write-CategoryMessage "`n=== Running $($cat.Name) Tests (Priority $($cat.Priority)) ===" -Level 'Info'
    
    $resultPath = Join-Path $reportDir "$($cat.Name)-results.xml"
    $startTime = Get-Date
    
    try {
        # Run tests in a completely separate PowerShell process
        # This avoids recursion detection and environment variable issues
        # Ensure TestSupport.ps1 is available by setting working directory and loading it
        $testSupportPath = Join-Path $repoRoot 'tests' 'TestSupport.ps1'
        $testScript = @"
`$env:PS_PROFILE_TEST_RUNNER_ACTIVE = `$null
`$env:PS_PROFILE_TEST_MODE = '1'
Set-Location '$($repoRoot.Replace("'", "''"))'
if (Test-Path '$($testSupportPath.Replace("'", "''"))') {
    . '$($testSupportPath.Replace("'", "''"))'
}
& '$($runPesterPath.Replace("'", "''"))' -TestFile '$($cat.Path.Replace("'", "''"))' -OutputFormat Minimal -OutputPath '$($resultPath.Replace("'", "''"))'
"@
        
        # Execute in separate process
        $process = Start-Process -FilePath 'pwsh' `
            -ArgumentList @('-NoProfile', '-Command', $testScript) `
            -Wait `
            -PassThru `
            -NoNewWindow `
            -RedirectStandardOutput (Join-Path $reportDir "$($cat.Name)-stdout.txt") `
            -RedirectStandardError (Join-Path $reportDir "$($cat.Name)-stderr.txt")
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        # Parse results from XML file (most reliable)
        $passed = 0
        $failed = 0
        $skipped = 0
        $total = 0
        
        if (Test-Path $resultPath) {
            try {
                [xml]$xmlResult = Get-Content $resultPath -ErrorAction Stop
                if ($xmlResult -and $xmlResult.'test-results') {
                    $passed = if ([string]::IsNullOrWhiteSpace($xmlResult.'test-results'.passed)) { 0 } else { [int]$xmlResult.'test-results'.passed }
                    $failed = if ([string]::IsNullOrWhiteSpace($xmlResult.'test-results'.failures)) { 0 } else { [int]$xmlResult.'test-results'.failures }
                    $skipped = if ([string]::IsNullOrWhiteSpace($xmlResult.'test-results'.skipped)) { 0 } else { [int]$xmlResult.'test-results'.skipped }
                    $total = if ([string]::IsNullOrWhiteSpace($xmlResult.'test-results'.total)) { 0 } else { [int]$xmlResult.'test-results'.total }
                }
            }
            catch {
                Write-CategoryMessage "Warning: Failed to parse XML results for $($cat.Name): $_" -Level 'Warning'
                # If XML parsing fails, mark as error
                $failed = 1
                $total = 1
            }
        }
        else {
            Write-CategoryMessage "Warning: Result XML file not found for $($cat.Name): $resultPath" -Level 'Warning'
            $failed = 1
            $total = 1
        }
        
        $cat.Result = $result
        $cat.Passed = $passed
        $cat.Failed = $failed
        $cat.Skipped = $skipped
        $cat.Total = $total
        $cat.Duration = $duration
        $cat.ResultPath = $resultPath
        
        $allResults += $cat
        
        if ($failed -gt 0) {
            $durationStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber ([math]::Round($duration, 2)) -Format 'N2'
            }
            else {
                [math]::Round($duration, 2).ToString("N2")
            }
            Write-CategoryMessage "⚠️  $($cat.Name): $failed failures out of $total tests (Duration: ${durationStr}s)" -Level 'Warning'
            $failureSummary += $cat
            
            if ($StopOnFailure) {
                Write-CategoryMessage "Stopping on first failure as requested." -Level 'Info'
                break
            }
        }
        else {
            $durationStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber ([math]::Round($duration, 2)) -Format 'N2'
            }
            else {
                [math]::Round($duration, 2).ToString("N2")
            }
            Write-CategoryMessage "✅ $($cat.Name): All $total tests passed (Duration: ${durationStr}s)" -Level 'Info'
        }
    }
    catch {
        Write-CategoryMessage "❌ Error running $($cat.Name): $_" -Level 'Error'
        $cat.Error = $_.Exception.Message
        $allResults += $cat
        $failureSummary += $cat
        
        if ($StopOnFailure) {
            break
        }
    }
}

# Generate summary
Write-CategoryMessage "`n=== Execution Summary ===" -Level 'Info'
$totalTests = ($allResults | Measure-Object -Property Total -Sum).Sum
$totalPassed = ($allResults | Measure-Object -Property Passed -Sum).Sum
$totalFailed = ($allResults | Measure-Object -Property Failed -Sum).Sum
$totalSkipped = ($allResults | Measure-Object -Property Skipped -Sum).Sum
$totalDuration = ($allResults | Measure-Object -Property Duration -Sum).Sum

Write-CategoryMessage "Total Tests: $totalTests" -Level 'Info'
Write-CategoryMessage "Passed: $totalPassed" -Level 'Info'
Write-CategoryMessage "Failed: $totalFailed" -Level 'Info'
Write-CategoryMessage "Skipped: $totalSkipped" -Level 'Info'
$totalDurationStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber ([math]::Round($totalDuration, 2)) -Format 'N2'
}
else {
    [math]::Round($totalDuration, 2).ToString("N2")
}
Write-CategoryMessage "Total Duration: ${totalDurationStr}s" -Level 'Info'

if ($failureSummary.Count -gt 0) {
    Write-CategoryMessage "`nCategories with failures: $($failureSummary.Count)" -Level 'Warning'
    $failureSummary | ForEach-Object {
        Write-CategoryMessage "  - $($_.Name): $($_.Failed) failures" -Level 'Warning'
    }
}

# Generate detailed report if requested
if ($GenerateReport) {
    $reportPath = Join-Path $reportDir "systematic-test-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    
    # Use locale-aware date formatting for user-facing report
    $generatedDate = if (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
        Format-LocaleDate (Get-Date) -Format 'yyyy-MM-dd HH:mm:ss'
    }
    else {
        (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }
    
    $report = @"
# Systematic Test Execution Report

Generated: $generatedDate

## Summary

- **Total Categories:** $($allResults.Count)
- **Total Tests:** $totalTests
- **Passed:** $totalPassed
- **Failed:** $totalFailed
- **Skipped:** $totalSkipped
- **Pass Rate:** $(if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber ([math]::Round(($totalPassed / $totalTests) * 100, 2)) -Format 'N2'
} else {
    [math]::Round(($totalPassed / $totalTests) * 100, 2).ToString("N2")
})%
- **Total Duration:** $(if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber ([math]::Round($totalDuration, 2)) -Format 'N2'
} else {
    [math]::Round($totalDuration, 2).ToString("N2")
})s

## Results by Category

| Category | Priority | Tests | Passed | Failed | Skipped | Duration (s) | Status |
|----------|----------|-------|--------|--------|---------|--------------|--------|
$($allResults | ForEach-Object { 
    $durationStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
        Format-LocaleNumber ([math]::Round($_.Duration, 2)) -Format 'N2'
    } else {
        [math]::Round($_.Duration, 2).ToString("N2")
    }
    "| $($_.Name) | $($_.Priority) | $($_.Total) | $($_.Passed) | $($_.Failed) | $($_.Skipped) | $durationStr | $(if ($_.Failed -gt 0) { '❌' } else { '✅' }) |"
} | Out-String)

## Categories with Failures

$($failureSummary | ForEach-Object { @"

### $($_.Name) - $($_.Failed) failures

- **Total Tests:** $($_.Total)
- **Passed:** $($_.Passed)
- **Failed:** $($_.Failed)
- **Skipped:** $($_.Skipped)
- **Duration:** $(if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber ([math]::Round($_.Duration, 2)) -Format 'N2'
} else {
    [math]::Round($_.Duration, 2).ToString("N2")
})s
- **Result File:** $($_.ResultPath)

"@ } | Out-String)

## Next Steps

1. Review failure details in result XML files
2. Identify common failure patterns
3. Apply targeted fixes based on patterns
4. Re-run affected categories to verify fixes
"@

    Set-Content -Path $reportPath -Value $report -Encoding UTF8
    Write-CategoryMessage "`nDetailed report generated: $reportPath" -Level 'Info'
}

if ($totalFailed -gt 0) {
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Test execution completed with $totalFailed failures"
    }
    else {
        Write-Host "Test execution completed with $totalFailed failures" -ForegroundColor Yellow
        Write-Error "Test execution completed with $totalFailed failures" -ErrorAction Stop
    }
}
else {
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "All tests passed successfully"
    }
    else {
        Write-Host "All tests passed successfully" -ForegroundColor Green
        return
    }
}

