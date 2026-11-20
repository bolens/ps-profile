#Requires -Version 7.0
<#
.SYNOPSIS
    Runs one complete Linux shadow bundle from the canonical shared planner.
.PARAMETER Bundle
    Stable Linux bundle number; no changed-path or failed-Git fallback.
.PARAMETER OutputPath
    Job-private shard XML and summary directory.
.PARAMETER PlanOnly
    Validates and emits all eight canonical bundles without executing tests.
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 8)][int]$Bundle = 1,
    [string]$OutputPath,
    [switch]$PlanOnly
)
$moduleImportPath = Join-Path $PSScriptRoot '../lib/ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global | Out-Null
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
try {
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $quality = Join-Path $root 'scripts/utils/code-quality'
    Import-Module (Join-Path $quality 'modules/PesterCiShardFilter.psm1') -DisableNameChecking -ErrorAction Stop
    Import-Module (Join-Path $quality 'modules/PesterCiJobs.psm1') -DisableNameChecking -ErrorAction Stop
    $all = @(Get-PesterCiAllShards)
    $jobs = @(Get-PesterCiJobs -Shards $all | Where-Object { $_.label -eq 'ubuntu-latest' } | Sort-Object job)
    $expected = @(Get-PesterCiShardMatrix -Shards $all | Where-Object { $_.label -eq 'ubuntu-latest' } | ForEach-Object shard | Sort-Object -Unique)
    $actual = @($jobs | ForEach-Object shards)
    if ($jobs.Count -ne 8 -or $expected.Count -ne 48 -or $actual.Count -ne 48 -or @($actual | Sort-Object -Unique).Count -ne 48 -or @(Compare-Object $expected ($actual | Sort-Object)).Count -ne 0) {
        throw 'Canonical Linux inventory must contain exactly eight disjoint bundles covering all 48 shards.'
    }
    if ($PlanOnly) { $jobs | ConvertTo-Json -Depth 8; return }
    if ($PSVersionTable.PSVersion.ToString() -ne '7.6.10') { throw 'PowerShell 7.6.10 is required.' }
    if ([string]::IsNullOrWhiteSpace($OutputPath)) { throw 'OutputPath is required for execution.' }
    $job = @($jobs | Where-Object job -EQ "bundle-$Bundle")
    if ($job.Count -ne 1 -or $job[0].maxParallelShards -ne 2) { throw 'Invalid canonical Linux bundle.' }
    $revision = & git -C $root rev-parse HEAD
    if ($LASTEXITCODE -ne 0 -or $revision -notmatch '^[0-9a-f]{40}$') { throw 'Cannot resolve actual source HEAD.' }
    Write-Host ('NATIVE_PESTER_PLAN ' + (@{ revision = $revision; bundle = $Bundle; shards = @($job[0].shards); runtime = $PSVersionTable.PSVersion.ToString() } | ConvertTo-Json -Compress))
    & (Join-Path $PSHOME 'pwsh') -NoLogo -NoProfile -NonInteractive -File (Join-Path $quality 'run-pester-ci-job.ps1') -ShardsJson (ConvertTo-Json -InputObject @($job[0].shards) -Compress) -RepoRoot $root -OutputPath $OutputPath -MaxParallelShards 2
    $status = $LASTEXITCODE
    if ($status -ne 0) { Exit-WithCode -ExitCode $status }
    $summary = @(Get-Content (Join-Path $OutputPath 'summary.json') -Raw | ConvertFrom-Json)
    $expectedShards = @($job[0].shards | Sort-Object)
    $reportedShards = @($summary | ForEach-Object Shard | Sort-Object)
    if ($summary.Count -ne $expectedShards.Count -or @(Compare-Object $expectedShards $reportedShards).Count -ne 0 -or
        @($summary | Where-Object { $_.ExitCode -ne 0 -or $_.Revision -ne $revision -or $_.Error }).Count -gt 0) {
        throw 'Missing or failed source-bound shard summary.'
    }
    Write-Host ('NATIVE_PESTER_RESULT ' + ($summary | ConvertTo-Json -Compress -Depth 8))
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
