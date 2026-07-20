#Requires -Version 7.0
<#
.SYNOPSIS
    Runs Pester CI shards selected from local git changes (same filter rules as GitHub Actions).

.DESCRIPTION
    Detects changed files (working tree / staged, or -ChangedSince), maps them to CI shards
    via PesterCiShardFilter.psm1, then runs each selected shard through run-pester-ci-shard.ps1.

.PARAMETER ChangedSince
    Git ref to diff against (e.g. main, origin/main, HEAD~3). When omitted, uses working-tree changes.

.PARAMETER IncludeUntracked
    Include untracked files when detecting working-tree changes.

.PARAMETER All
    Run the full shard set.

.PARAMETER ListOnly
    Print selected shards and exit without running tests.

.PARAMETER Quiet
    Pass -Quiet to each shard runner.

.PARAMETER RepoRoot
    Repository root.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester-changed-shards.ps1 -Quiet

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester-changed-shards.ps1 -ChangedSince origin/main -Quiet
#>
[CmdletBinding()]
param(
    [string]$ChangedSince,

    [switch]$IncludeUntracked,

    [switch]$All,

    [switch]$ListOnly,

    [switch]$Quiet,

    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$filterModule = Join-Path $PSScriptRoot 'modules' 'PesterCiShardFilter.psm1'
$shardRunner = Join-Path $PSScriptRoot 'run-pester-ci-shard.ps1'
Import-Module $filterModule -Force -DisableNameChecking -ErrorAction Stop

function Get-LocalChangedFiles {
    param(
        [string]$Root,
        [string]$Since,
        [switch]$Untracked
    )

    Push-Location $Root
    try {
        $files = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

        if (-not [string]::IsNullOrWhiteSpace($Since)) {
            $diff = @(git diff --name-only --diff-filter=ACMRD "$Since...HEAD" 2>$null)
            if ($LASTEXITCODE -ne 0) {
                $diff = @(git diff --name-only --diff-filter=ACMRD "$Since" 2>$null)
            }
            foreach ($f in $diff) {
                if (-not [string]::IsNullOrWhiteSpace($f)) { [void]$files.Add($f.Trim()) }
            }
            return @($files)
        }

        foreach ($f in @(git diff --name-only --diff-filter=ACMRD HEAD 2>$null)) {
            if (-not [string]::IsNullOrWhiteSpace($f)) { [void]$files.Add($f.Trim()) }
        }
        foreach ($f in @(git diff --name-only --cached --diff-filter=ACMRD 2>$null)) {
            if (-not [string]::IsNullOrWhiteSpace($f)) { [void]$files.Add($f.Trim()) }
        }
        if ($Untracked) {
            foreach ($f in @(git ls-files --others --exclude-standard 2>$null)) {
                if (-not [string]::IsNullOrWhiteSpace($f)) { [void]$files.Add($f.Trim()) }
            }
        }

        return @($files)
    }
    finally {
        Pop-Location
    }
}

$shards = if ($All) {
    Resolve-PesterCiShards -All
}
else {
    $changed = @(Get-LocalChangedFiles -Root $RepoRoot -Since $ChangedSince -Untracked:$IncludeUntracked)
    Write-Host ("Changed files: {0}" -f $changed.Count) -ForegroundColor DarkGray
    Resolve-PesterCiShards -ChangedFiles $changed
}

if ($shards.Count -eq 0) {
    Write-Host 'No CI shards match the current changes; skipping Pester.' -ForegroundColor Yellow
    exit 0
}

Write-Host ("Selected shards ({0}): {1}" -f $shards.Count, ($shards -join ', ')) -ForegroundColor Cyan

if ($ListOnly) {
    $shards | ForEach-Object { Write-Output $_ }
    exit 0
}

$failed = [System.Collections.Generic.List[string]]::new()
foreach ($shard in $shards) {
    Write-Host ""
    Write-Host "=== shard: $shard ===" -ForegroundColor Cyan
    $args = @('-NoProfile', '-NonInteractive', '-File', $shardRunner, '-Shard', $shard)
    if ($Quiet) { $args += '-Quiet' }
    & pwsh @args
    if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        $failed.Add($shard)
    }
}

if ($failed.Count -gt 0) {
    Write-Error ("Changed-shard run failed: {0}" -f ($failed -join ', '))
    exit 1
}

Write-Host 'All selected shards passed.' -ForegroundColor Green
exit 0
