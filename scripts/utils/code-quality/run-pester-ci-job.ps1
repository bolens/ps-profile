#Requires -Version 7.0
<#
.SYNOPSIS
    Runs a balanced CI job while preserving per-shard isolation and failure status.
.DESCRIPTION
    Accepts the selected shard list as JSON, delegates to the isolated job runner,
    and uses shared exit codes for setup and validation failures.
.PARAMETER ShardsJson
    JSON array of unique shard names from Get-PesterCiJobs.
.PARAMETER RepoRoot
    Source checkout whose exact HEAD is tested.
.PARAMETER OutputPath
    Directory for per-shard artifacts and the job summary.
.PARAMETER MaxParallelShards
    Maximum independent shard worker processes, default two for hosted CI.
.EXAMPLE
    ./run-pester-ci-job.ps1 -ShardsJson '["unit-support"]' -OutputPath ./tests/test-artifacts/ci-job
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ShardsJson,
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),
    [Parameter(Mandatory)][string]$OutputPath,
    [ValidateRange(1, 2)][int]$MaxParallelShards = 2
)
$moduleImportPath = Join-Path $PSScriptRoot '../../lib/ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-Module (Join-Path $PSScriptRoot 'modules/PesterCiJobs.psm1') -DisableNameChecking -ErrorAction Stop
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
try {
    $names = ConvertFrom-Json -InputObject $ShardsJson -NoEnumerate
    if ($names -isnot [array] -or $names.Count -eq 0 -or @($names | Where-Object { $_ -isnot [string] }).Count -gt 0) {
        throw 'ShardsJson must be a nonempty array of shard names.'
    }
    $result = Invoke-PesterCiJob -Shards $names -RepoRoot $RepoRoot -OutputPath $OutputPath -MaxParallelShards $MaxParallelShards
    $result.Results | Format-Table Shard, DurationSeconds, ExitCode, Error | Out-Host
    if (-not $result.Succeeded) { Exit-WithCode -ExitCode $EXIT_TEST_FAILURE }
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
