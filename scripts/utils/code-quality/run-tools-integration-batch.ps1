#Requires -Version 7.0
<#
.SYNOPSIS
    Runs tools integration tests.

.DESCRIPTION
    Tools tests share global functions/aliases across files, so the default is per-file
    isolation (one run-pester process per *.tests.ps1, discovered recursively). Use
    -SingleSession for one combined run (faster but requires pwsh -NonInteractive).

.PARAMETER RelativePath
    Optional subdirectory under tests/integration/tools (default: run all tools tests).

.PARAMETER RepoRoot
    Repository root directory.

.PARAMETER SingleSession
    Run all matching files in one Pester session (use with pwsh -NonInteractive).

.PARAMETER Quiet
    Pass -Quiet to run-pester.

.PARAMETER NamePattern
    Optional case-insensitive regex matched against each test file basename
    (e.g. '^[0-9a-d]' for CI shard splits).

.PARAMETER PerFileTimeoutSeconds
    Abort each PerFile run-pester process after this many seconds (default: 600).
    Prevents a single hung file from burning the full 90m CI job timeout.

.EXAMPLE
    pwsh -NonInteractive -NoProfile -File scripts/utils/code-quality/run-tools-integration-batch.ps1

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-tools-integration-batch.ps1 -RelativePath network
#>
param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),

    [string]$RelativePath = '',

    [switch]$SingleSession,

    [switch]$Quiet,

    [string]$NamePattern = '',

    [ValidateRange(0, 7200)]
    [int]$PerFileTimeoutSeconds = 600
)

$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

$toolsRoot = Join-Path $RepoRoot 'tests' 'integration' 'tools'
$testDir = if ([string]::IsNullOrWhiteSpace($RelativePath)) {
    $toolsRoot
}
else {
    Join-Path $toolsRoot $RelativePath
}

if (-not (Test-Path -LiteralPath $testDir)) {
    Write-Error "Test directory not found: $testDir"
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
}

$runner = Join-Path $RepoRoot 'scripts' 'utils' 'code-quality' 'run-pester.ps1'
$files = @(Get-ChildItem -Path $testDir -Filter '*.tests.ps1' -File -Recurse | Sort-Object FullName)

if (-not [string]::IsNullOrWhiteSpace($NamePattern)) {
    $files = @($files | Where-Object { $_.Name -match $NamePattern })
}

if ($files.Count -eq 0) {
    $hint = if ([string]::IsNullOrWhiteSpace($NamePattern)) { '' } else { " (NamePattern: $NamePattern)" }
    Write-Error "No *.tests.ps1 files under: $testDir$hint"
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
}

function Get-PesterRunStats {
    param(
        [string]$Output,
        [string]$ResultXmlPath
    )

    $passed = -1
    $failed = -1
    $skipped = 0

    if ($Output -match 'Tests Passed:\s*(\d+)') {
        $passed = [int]$Matches[1]
        if ($Output -match 'Failed:\s*(\d+)') { $failed = [int]$Matches[1] }
        if ($Output -match 'Skipped:\s*(\d+)') { $skipped = [int]$Matches[1] }
    }
    elseif ($Output -match 'Tests completed:\s*Passed=(\d+),\s*Failed=(\d+),\s*Skipped=(\d+)') {
        $passed = [int]$Matches[1]
        $failed = [int]$Matches[2]
        $skipped = [int]$Matches[3]
    }
    elseif ($ResultXmlPath -and (Test-Path -LiteralPath $ResultXmlPath)) {
        try {
            [xml]$xml = Get-Content -LiteralPath $ResultXmlPath -ErrorAction Stop
            $root = $xml.'test-results'
            if ($root) {
                $total = [int]$root.total
                $failures = [int]$root.failures + [int]$root.errors
                $skippedCount = [int]$root.skipped + [int]$root.ignored
                $passed = $total - $failures - $skippedCount
                $failed = $failures
                $skipped = $skippedCount
            }
        }
        catch {
            # Fall through; caller uses exit code.
        }
    }

    [pscustomobject]@{
        Passed  = $passed
        Failed  = $failed
        Skipped = $skipped
    }
}

function Invoke-ToolsBatchRunner {
    param(
        [string[]]$RunnerArgs,

        [int]$TimeoutSeconds = 0
    )

    if ($TimeoutSeconds -le 0) {
        $output = & pwsh -NonInteractive @RunnerArgs 2>&1 | Out-String
        $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
        return [pscustomobject]@{
            Output   = $output
            ExitCode = $exitCode
            TimedOut = $false
        }
    }

    # File redirects avoid WaitForExit + pipe-buffer deadlock.
    $pwshExe = (Get-Command pwsh -ErrorAction Stop).Source
    $allArgs = @('-NonInteractive') + @($RunnerArgs)
    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()
    try {
        $process = Start-Process -FilePath $pwshExe -ArgumentList $allArgs -NoNewWindow -PassThru `
            -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
        if ($timedOut) {
            try {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                $process.WaitForExit(5000) | Out-Null
            }
            catch { }
        }
        else {
            $process.WaitForExit() | Out-Null
        }

        $stdout = if (Test-Path -LiteralPath $stdoutPath) { Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue } else { '' }
        $stderr = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue } else { '' }
        $output = [string]$stdout + [string]$stderr
        if ($timedOut) {
            if ($output -notmatch 'Timed out after') {
                $output += "`nTimed out after ${TimeoutSeconds}s`n"
            }
            return [pscustomobject]@{
                Output   = $output
                ExitCode = 1
                TimedOut = $true
            }
        }

        return [pscustomobject]@{
            Output   = $output
            ExitCode = $process.ExitCode
            TimedOut = $false
        }
    }
    finally {
        Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

function New-BatchRunnerArgs {
    param(
        [string]$TargetPath,
        [string]$ResultPath
    )

    $args = @(
        '-NoProfile'
        '-File'
        $runner
        '-Suite'
        'Integration'
        '-Path'
        $TargetPath
    )
    if ($Quiet) {
        $args += '-Quiet'
    }
    if ($ResultPath) {
        $args += '-TestResultPath'
        $args += $ResultPath
    }
    return $args
}

function Get-PesterFailureLines {
    param(
        [string]$Output,
        [string]$ResultXmlPath
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    [regex]::Matches($Output, '(?m)^\s+\[-\].*') | ForEach-Object { $lines.Add($_.Value.Trim()) }

    $xmlCandidates = @()
    if ($ResultXmlPath -and -not [string]::IsNullOrWhiteSpace($ResultXmlPath)) {
        if (Test-Path -LiteralPath $ResultXmlPath -PathType Leaf) {
            $xmlCandidates += $ResultXmlPath
        }
        elseif (Test-Path -LiteralPath $ResultXmlPath -PathType Container) {
            $xmlCandidates += @(Get-ChildItem -LiteralPath $ResultXmlPath -Filter '*.xml' -Recurse -File -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FullName)
        }
    }

    foreach ($xmlPath in $xmlCandidates) {
        try {
            [xml]$xml = Get-Content -LiteralPath $xmlPath -Raw -ErrorAction Stop
            foreach ($case in @($xml.SelectNodes('//test-case[@result="Failure" or @result="Error"]'))) {
                $name = [string]$case.GetAttribute('name')
                $messageNode = $case.SelectSingleNode('.//failure/message')
                $message = if ($messageNode) { [string]$messageNode.InnerText } else { '' }
                if ([string]::IsNullOrWhiteSpace($name) -and [string]::IsNullOrWhiteSpace($message)) {
                    continue
                }
                $summary = if ($message) { "${name}: $message" } else { $name }
                if (-not [string]::IsNullOrWhiteSpace($summary) -and -not $lines.Contains($summary)) {
                    $lines.Add($summary.Trim())
                }
            }
        }
        catch {
            # Ignore unreadable result XML; output-based lines may still be available.
        }
    }

    return @($lines)
}

$label = if ([string]::IsNullOrWhiteSpace($RelativePath)) { 'tools' } else { "tools/$RelativePath" }
Write-Host "Batch: $label ($($files.Count) files)" -ForegroundColor Cyan

if ($SingleSession) {
    Write-Host 'Mode: single session (requires pwsh -NonInteractive)' -ForegroundColor DarkGray
    Write-Host ''

    $resultDir = Join-Path $RepoRoot 'tests' 'test-artifacts' 'tools-batch'
    $null = New-Item -ItemType Directory -Path $resultDir -Force -ErrorAction SilentlyContinue

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $run = Invoke-ToolsBatchRunner -RunnerArgs (New-BatchRunnerArgs -TargetPath $testDir -ResultPath $resultDir) -TimeoutSeconds 0
    $sw.Stop()

    $stats = Get-PesterRunStats -Output $run.Output -ResultXmlPath (Join-Path $resultDir 'test-results.xml')
    $batchFailed = $run.ExitCode -ne 0 -or ($stats.Failed -gt 0)

    $color = if ($batchFailed) { 'Red' } elseif ($stats.Passed -ge 0) { 'Green' } else { 'Yellow' }
    Write-Host "  $($stats.Passed)P / $($stats.Failed)F / $($stats.Skipped)S in $([math]::Round($sw.Elapsed.TotalSeconds, 1))s" -ForegroundColor $color

    if ($batchFailed) {
        Write-Host "Batch failed: $label" -ForegroundColor Red
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE
    }

    Write-Host "All tests passed in batch: $label" -ForegroundColor Green
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}

Write-Host 'Mode: per-file (default for tools isolation)' -ForegroundColor DarkGray
Write-Host ''

$resultDir = Join-Path $RepoRoot 'tests' 'test-artifacts' 'tools-batch'
$null = New-Item -ItemType Directory -Path $resultDir -Force -ErrorAction SilentlyContinue

$results = @()
foreach ($file in $files) {
    $relName = $file.FullName.Substring($toolsRoot.Length).TrimStart('/', '\')
    Write-Host "=== $relName ===" -ForegroundColor Cyan
    $fileResultDir = Join-Path $resultDir (($relName -replace '[\\/:\*\?"<>\|]', '-').Trim('-'))
    if (Test-Path -LiteralPath $fileResultDir) {
        Remove-Item -LiteralPath $fileResultDir -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
    $null = New-Item -ItemType Directory -Path $fileResultDir -Force -ErrorAction SilentlyContinue

    $run = Invoke-ToolsBatchRunner -RunnerArgs (New-BatchRunnerArgs -TargetPath $file.FullName -ResultPath $fileResultDir) -TimeoutSeconds $PerFileTimeoutSeconds
    $stats = Get-PesterRunStats -Output $run.Output -ResultXmlPath (Join-Path $fileResultDir 'test-results.xml')
    if ($stats.Failed -lt 0) {
        $stats = Get-PesterRunStats -Output $run.Output -ResultXmlPath $fileResultDir
    }
    if ($run.ExitCode -ne 0 -and $stats.Failed -le 0) {
        $stats = [pscustomobject]@{
            Passed  = [Math]::Max(0, $stats.Passed)
            Failed  = 1
            Skipped = [Math]::Max(0, $stats.Skipped)
        }
    }
    $failLines = @(Get-PesterFailureLines -Output $run.Output -ResultXmlPath $fileResultDir)
    if ($run.ExitCode -ne 0 -and $failLines.Count -eq 0 -and ($run.TimedOut -or $run.Output -match 'Timed out after')) {
        $failLines = @("Timed out after ${PerFileTimeoutSeconds}s")
    }

    $results += [pscustomobject]@{
        File     = $relName
        Passed   = $stats.Passed
        Failed   = $stats.Failed
        Skipped  = $stats.Skipped
    }

    $color = if ($stats.Failed -gt 0) { 'Red' } elseif ($stats.Passed -ge 0) { 'Green' } else { 'Yellow' }
    Write-Host "  $($stats.Passed)P / $($stats.Failed)F / $($stats.Skipped)S" -ForegroundColor $color
    if ($failLines.Count -gt 0) {
        $failLines | Select-Object -First 5 | ForEach-Object {
            Write-Host "    $_" -ForegroundColor DarkRed
        }
    }
}

Write-Host ''
Write-Host "--- Summary ($label) ---" -ForegroundColor Cyan
$results | Format-Table -AutoSize
$bad = @($results | Where-Object { $_.Failed -gt 0 })
if ($bad.Count -gt 0) {
    Write-Host "Files with failures: $($bad.Count)" -ForegroundColor Red
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE
}

Write-Host "All tests passed in batch: $label" -ForegroundColor Green
Exit-WithCode -ExitCode $EXIT_SUCCESS
