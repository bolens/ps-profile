# Coverage Verification Script
# Run this script directly in PowerShell to verify utility module coverage

param(
    [string[]]$Modules = @('Command', 'DataFile', 'EnvFile', 'RequirementsLoader', 'CacheKey', 'JsonUtilities', 'RegexUtilities', 'StringSimilarity', 'Collections', 'Cache')
)

$ErrorActionPreference = 'Continue'

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "Utility Modules Coverage Verification" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""

$results = @()

foreach ($module in $Modules) {
    Write-Host "Checking $module.psm1..." -ForegroundColor Yellow
    
    $modulePath = "scripts/lib/utilities/$module.psm1"
    if (-not (Test-Path $modulePath)) {
        Write-Host "  ⚠ Module not found: $modulePath" -ForegroundColor Red
        continue
    }
    
    try {
        # Run coverage analysis with timeout to prevent hanging
        $scriptPath = Resolve-Path 'scripts/utils/code-quality/analyze-coverage.ps1'
        $job = Start-Job -ScriptBlock {
            param($scriptPath, $modulePath)
            & pwsh -NoProfile -NonInteractive -File $scriptPath -Path $modulePath 2>&1 | Out-String
        } -ArgumentList $scriptPath, $modulePath
        
        $timeout = 60 # 60 seconds timeout
        $completed = Wait-Job -Job $job -Timeout $timeout
        
        if (-not $completed) {
            Stop-Job -Job $job -Force
            Remove-Job -Job $job -Force
            Write-Host "  ⚠️  TIMEOUT (exceeded ${timeout}s)" -ForegroundColor Yellow
            $results += [PSCustomObject]@{
                Module           = $module
                Coverage         = 0
                Passed           = 0
                Failed           = 0
                CommandsExecuted = 0
                CommandsAnalyzed = 0
                Status           = "⚠️  TIMEOUT"
            }
            Write-Host ""
            continue
        }
        
        $output = Receive-Job -Job $job
        Remove-Job -Job $job -Force
        
        # Extract key metrics - try multiple patterns to catch different output formats
        $coverageMatch = $output | Select-String -Pattern 'Overall Coverage:\s*(\d+\.?\d*)%'
        if (-not $coverageMatch) {
            $coverageMatch = $output | Select-String -Pattern 'Covered\s+(\d+\.?\d*)%\s*/\s*75%'
        }
        
        # Try multiple patterns for test results
        $testsMatch = $output | Select-String -Pattern 'Test Results:.*?(\d+)\s+passed,\s*(\d+)\s+failed'
        if (-not $testsMatch) {
            $testsMatch = $output | Select-String -Pattern 'Tests Passed:\s*(\d+),\s*Failed:\s*(\d+)'
        }
        if (-not $testsMatch) {
            $testsMatch = $output | Select-String -Pattern '(\d+)\s+passed,\s*(\d+)\s+failed'
        }
        if (-not $testsMatch) {
            $testsMatch = $output | Select-String -Pattern 'Passed:\s*(\d+).*Failed:\s*(\d+)'
        }
        
        # Try multiple patterns for commands
        $commandsMatch = $output | Select-String -Pattern 'Commands Analyzed:\s*(\d+).*Commands Executed:\s*(\d+)'
        if (-not $commandsMatch) {
            $commandsMatch = $output | Select-String -Pattern '(\d+)\s+analyzed Commands.*(\d+)\s+executed'
        }
        
        $coverage = if ($coverageMatch) { [double]$coverageMatch.Matches[0].Groups[1].Value } else { 0 }
        $passed = if ($testsMatch) { [int]$testsMatch.Matches[0].Groups[1].Value } else { 0 }
        $failed = if ($testsMatch) { [int]$testsMatch.Matches[0].Groups[2].Value } else { 0 }
        $analyzed = if ($commandsMatch) { [int]$commandsMatch.Matches[0].Groups[1].Value } else { 0 }
        $executed = if ($commandsMatch) { [int]$commandsMatch.Matches[0].Groups[2].Value } else { 0 }
        
        $status = if ($coverage -ge 75 -and $failed -eq 0) { "✅ PASS" } 
        elseif ($coverage -ge 75) { "⚠️  WARN" } 
        else { "❌ FAIL" }
        
        $color = if ($coverage -ge 75) { 'Green' } else { 'Red' }
        
        Write-Host "  $status Coverage: $coverage% | Tests: $passed passed, $failed failed | Commands: $executed/$analyzed" -ForegroundColor $color
        
        $results += [PSCustomObject]@{
            Module           = $module
            Coverage         = $coverage
            Passed           = $passed
            Failed           = $failed
            CommandsExecuted = $executed
            CommandsAnalyzed = $analyzed
            Status           = $status
        }
    }
    catch {
        Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Module           = $module
            Coverage         = 0
            Passed           = 0
            Failed           = 0
            CommandsExecuted = 0
            CommandsAnalyzed = 0
            Status           = "❌ ERROR"
        }
    }
    
    Write-Host ""
}

# Summary
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""

$results | Format-Table -AutoSize

$aboveThreshold = ($results | Where-Object { $_.Coverage -ge 75 }).Count
$total = $results.Count
$allPassing = ($results | Where-Object { $_.Failed -eq 0 }).Count

Write-Host ""
Write-Host "Modules above 75% coverage: $aboveThreshold of $total" -ForegroundColor $(if ($aboveThreshold -eq $total) { 'Green' } else { 'Yellow' })
Write-Host "Modules with all tests passing: $allPassing of $total" -ForegroundColor $(if ($allPassing -eq $total) { 'Green' } else { 'Yellow' })

if ($aboveThreshold -eq $total -and $allPassing -eq $total) {
    Write-Host ""
    Write-Host "🎉 All utility modules meet coverage and test requirements!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host ""
    Write-Host "⚠️  Some modules need attention" -ForegroundColor Yellow
    exit 1
}

