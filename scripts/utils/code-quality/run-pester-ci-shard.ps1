#Requires -Version 7.0
<#
.SYNOPSIS
    Runs one Pester CI shard (suite subset) for parallel GitHub Actions jobs.

.DESCRIPTION
    Maps a named shard to a bounded test path set so CI can run many jobs in parallel
    instead of one multi-hour full-suite job. Most shards use run-pester.ps1 with
    -Parallel; tools and conversion shards use the existing batch runners.

.PARAMETER Shard
    CI shard identifier. Use ListShards to print all valid values.

.PARAMETER RepoRoot
    Repository root directory.

.PARAMETER Quiet
    Reduce runner output (recommended for CI).

.PARAMETER Coverage
    Enable code coverage for this shard (use on a single shard only).

.PARAMETER ListShards
    Print valid shard names and exit.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester-ci-shard.ps1 -Shard unit-library -Quiet
#>
[CmdletBinding()]
param(
    [Parameter(ParameterSetName = 'Run')]
    [ValidateNotNullOrEmpty()]
    [string]$Shard,

    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),

    [switch]$Quiet,

    [switch]$Coverage,

    [Parameter(ParameterSetName = 'List')]
    [switch]$ListShards
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ConfirmPreference = 'None'
$global:ConfirmPreference = 'None'
$env:PS_PROFILE_NONINTERACTIVE = '1'
$env:PS_PROFILE_TEST_MODE = '1'
$env:PS_PROFILE_SUPPRESS_CONFIRMATIONS = '1'

$runner = Join-Path $RepoRoot 'scripts' 'utils' 'code-quality' 'run-pester.ps1'
$toolsBatch = Join-Path $RepoRoot 'scripts' 'utils' 'code-quality' 'run-tools-integration-batch.ps1'
$conversionBatch = Join-Path $RepoRoot 'scripts' 'utils' 'code-quality' 'run-conversion-integration-batch.ps1'
$conversionAllBatch = Join-Path $RepoRoot 'scripts' 'utils' 'code-quality' 'run-conversion-all-batch.ps1'
$performanceBatch = Join-Path $RepoRoot 'scripts' 'utils' 'code-quality' 'run-performance-batch.ps1'

function Get-PesterCiShardDefinitions {
  $integrationCore = @(
    'tests/integration/bootstrap'
    'tests/integration/system'
    'tests/integration/profile'
    'tests/integration/filesystem'
    'tests/integration/terminal'
    'tests/integration/fragments'
    'tests/integration/test-runner'
    'tests/integration/utilities'
    'tests/integration/error-handling'
    'tests/integration/validation'
    'tests/integration/cross-platform'
    'tests/integration/cloud-provider'
  )

  $unitProfileCore = @(
    'tests/unit/profile/lang'
    'tests/unit/profile/files'
    'tests/unit/profile/bootstrap'
    'tests/unit/profile/main'
    'tests/unit/profile/git'
    'tests/unit/profile/utilities'
    'tests/unit/profile/system'
  )

  $unitProfileInfra = @(
    'tests/unit/profile/dev-tools'
    'tests/unit/profile/cloud'
    'tests/unit/profile/api'
    'tests/unit/profile/ai'
    'tests/unit/profile/command'
    'tests/unit/profile/tool'
    'tests/unit/profile/embedded'
    'tests/unit/profile/containers'
    'tests/unit/profile/kubernetes'
    'tests/unit/profile/database'
    'tests/unit/profile/network'
    'tests/unit/profile/security'
    'tests/unit/profile/module'
    'tests/unit/profile/diagnostics'
  )

  $profileMiscDirs = @(Get-ChildItem -Path (Join-Path $RepoRoot 'tests/unit/profile') -Directory -ErrorAction SilentlyContinue |
    Where-Object {
      $_.Name -notin @(
        'conversion', 'lang', 'files', 'bootstrap', 'main', 'git', 'utilities', 'system',
        'dev-tools', 'cloud', 'api', 'ai', 'command', 'tool', 'embedded',
        'containers', 'kubernetes', 'database', 'network', 'security', 'module', 'diagnostics'
      )
    })

  $miscA = @($profileMiscDirs | Where-Object { $_.Name[0] -le 'm' } | ForEach-Object { Join-Path 'tests/unit/profile' $_.Name })
  $miscB = @($profileMiscDirs | Where-Object { $_.Name[0] -ge 'n' } | ForEach-Object { Join-Path 'tests/unit/profile' $_.Name })

  $convDataMisc = @(
    'data/base64'
    'data/columnar'
    'data/csv-xml'
    'data/database'
    'data/digest'
    'data/error-handling'
    'data/network'
    'data/roundtrip'
    'data/specialized'
    'data/text-formats'
    'data/time'
  )

  $convMedia = @(
    'media/audio'
    'media/colors'
    'media/images'
    'media/video'
  )

  return [ordered]@{
    # Library tests mutate shared process env/globals; run serially to avoid cross-test pollution.
    'unit-library'               = @{ Kind = 'Pester'; Suite = 'Unit'; Paths = @('tests/unit/library'); MaxParallelThreads = 1 }
    'unit-utility'               = @{ Kind = 'Pester'; Suite = 'Unit'; Paths = @('tests/unit/utility') }
    'unit-test-runner'           = @{ Kind = 'Pester'; Suite = 'Unit'; Paths = @('tests/unit/test-runner') }
    'unit-support'               = @{ Kind = 'Pester'; Suite = 'Unit'; Paths = @('tests/unit/test-support', 'tests/unit/validation') }
    'unit-profile-conversion'    = @{ Kind = 'Pester'; Suite = 'Unit'; Paths = @('tests/unit/profile/conversion') }
    'unit-profile-core'          = @{ Kind = 'Pester'; Suite = 'Unit'; Paths = $unitProfileCore; MaxParallelThreads = 1 }
    'unit-profile-infra'         = @{ Kind = 'Pester'; Suite = 'Unit'; Paths = $unitProfileInfra }
    'unit-profile-misc-a'        = @{ Kind = 'Pester'; Suite = 'Unit'; Paths = $miscA }
    'unit-profile-misc-b'        = @{ Kind = 'Pester'; Suite = 'Unit'; Paths = $miscB }
    'integration-tools'          = @{ Kind = 'ToolsBatch' }
    'integration-core'           = @{ Kind = 'Pester'; Suite = 'Integration'; Paths = $integrationCore }
    'conversion-document'        = @{ Kind = 'ConversionBatch'; Paths = @('document') }
    'conversion-media'           = @{ Kind = 'ConversionAllBatch'; Paths = $convMedia }
    'conversion-data-structured' = @{ Kind = 'ConversionBatch'; Paths = @('data/structured') }
    'conversion-data-units'      = @{ Kind = 'ConversionBatch'; Paths = @('data/units') }
    'conversion-data-encoding'   = @{ Kind = 'ConversionBatch'; Paths = @('data/encoding') }
    'conversion-data-binary'     = @{ Kind = 'ConversionAllBatch'; Paths = @('data/binary', 'data/binary-to-text') }
    'conversion-data-compression'  = @{ Kind = 'ConversionBatch'; Paths = @('data/compression') }
    'conversion-data-scientific' = @{ Kind = 'ConversionBatch'; Paths = @('data/scientific') }
    'conversion-data-misc'       = @{ Kind = 'ConversionAllBatch'; Paths = $convDataMisc }
    'performance'                = @{ Kind = 'PerformanceBatch' }
    'coverage-smoke'             = @{ Kind = 'Pester'; Suite = 'Unit'; Paths = @('tests/unit/profile/bootstrap', 'tests/unit/library'); Coverage = $true; MaxParallelThreads = 1 }
  }
}

function Invoke-PesterCiShardRunner {
  param(
    [string[]]$RunnerArgs
  )

  Write-Host ("Running: pwsh {0}" -f ($RunnerArgs -join ' ')) -ForegroundColor DarkGray
  & pwsh -NoProfile -NonInteractive @RunnerArgs
  if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

function Invoke-PesterShard {
  param(
    [hashtable]$Definition,
    [string]$ShardName
  )

  $resultDir = Join-Path $RepoRoot 'tests' 'test-artifacts' ('ci-' + $ShardName)
  $null = New-Item -ItemType Directory -Path $resultDir -Force -ErrorAction SilentlyContinue

  $paths = @($Definition.Paths | ForEach-Object {
      $candidate = $_
      if (-not [System.IO.Path]::IsPathRooted($candidate)) {
        $candidate = Join-Path $RepoRoot $candidate
      }
      $candidate
    })

  $params = @{
    Suite          = $Definition.Suite
    Path           = $paths
    CI             = $true
    TestResultPath = $resultDir
  }
  if ($Quiet) {
    $params.Quiet = $true
  }
  if ($Coverage -or ($Definition.Contains('Coverage') -and $Definition.Coverage)) {
    $params.Coverage = $true
  }
  # Pester 5.7 has no Run.Parallel / MaximumThreadCount / Initialization.
  # Only enable -Parallel when the shard asks for more than one thread; serial
  # shards must omit it so containers stay fully sequential (avoids TestDrive
  # collisions from aborted parallel container setup on Windows).
  if ($Definition.ContainsKey('MaxParallelThreads') -and $Definition.MaxParallelThreads -gt 1) {
    $params.MaxParallelThreads = $Definition.MaxParallelThreads
    $params.Parallel = $true
  }
  elseif (-not ($Definition.ContainsKey('MaxParallelThreads') -and $Definition.MaxParallelThreads -eq 1)) {
    $params.Parallel = $true
  }

  Write-Host ("Running: {0} -Suite {1} -Path ({2})" -f $runner, $Definition.Suite, ($paths -join ', ')) -ForegroundColor DarkGray
  & $runner @params
  if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

$definitions = Get-PesterCiShardDefinitions

if ($ListShards) {
  $definitions.Keys | ForEach-Object { Write-Output $_ }
  exit 0
}

if ([string]::IsNullOrWhiteSpace($Shard)) {
  Write-Error 'Specify -Shard or use -ListShards.'
  exit 2
}

$normalizedShard = $Shard.Trim()
if (-not $definitions.Contains($normalizedShard)) {
  Write-Error "Unknown CI shard '$normalizedShard'. Use -ListShards for valid names."
  exit 2
}

$definition = $definitions[$normalizedShard]
Write-Host "CI shard: $normalizedShard ($($definition.Kind))" -ForegroundColor Cyan

switch ($definition.Kind) {
  'Pester' {
    Invoke-PesterShard -Definition $definition -ShardName $normalizedShard
  }
  'ToolsBatch' {
    $args = @('-NoProfile', '-NonInteractive', '-File', $toolsBatch)
    if ($Quiet) { $args += '-Quiet' }
    Invoke-PesterCiShardRunner -RunnerArgs $args
  }
  'ConversionBatch' {
    foreach ($rel in $definition.Paths) {
      Write-Host "Conversion batch: $rel" -ForegroundColor Cyan
      # Sequential: Pester 5.7 has no Run.Parallel; -Parallel was a no-op that
      # still confused result aggregation on some hosts.
      $args = @('-NoProfile', '-NonInteractive', '-File', $conversionBatch, '-RelativePath', $rel)
      if ($Quiet) { $args += '-Quiet' }
      Invoke-PesterCiShardRunner -RunnerArgs $args
    }
  }
  'ConversionAllBatch' {
    $resultDir = Join-Path $RepoRoot 'tests' 'test-artifacts' ('ci-' + $normalizedShard)
    $null = New-Item -ItemType Directory -Path $resultDir -Force -ErrorAction SilentlyContinue
    foreach ($rel in $definition.Paths) {
      Write-Host "Conversion all-batch path: $rel" -ForegroundColor Cyan
      $args = @(
        '-NoProfile'
        '-NonInteractive'
        '-File'
        $conversionAllBatch
        '-RelativePath'
        $rel
      )
      if ($Quiet) { $args += '-Quiet' }
      Invoke-PesterCiShardRunner -RunnerArgs $args
    }
    # Surface conversion-batch NUnit XML for the workflow artifact upload path.
    $batchResults = Join-Path $RepoRoot 'tests' 'test-artifacts' 'conversion-batch'
    if (Test-Path -LiteralPath $batchResults) {
      Copy-Item -Path (Join-Path $batchResults '*') -Destination $resultDir -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
  'PerformanceBatch' {
    $args = @('-NoProfile', '-NonInteractive', '-File', $performanceBatch)
    if ($Quiet) { $args += '-Quiet' }
    Invoke-PesterCiShardRunner -RunnerArgs $args
  }
  default {
    Write-Error "Unsupported shard kind: $($definition.Kind)"
    exit 2
  }
}

Write-Host "CI shard passed: $normalizedShard" -ForegroundColor Green
exit 0
