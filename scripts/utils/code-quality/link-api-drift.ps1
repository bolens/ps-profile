<#
.SYNOPSIS
    Links generated API docs in docs/api to their source targets with drift.

.DESCRIPTION
    Parses the "Defined in:" source line from generated function and alias markdown
    files and runs `drift link` so API documentation bindings are recorded in
    drift.lock.

.PARAMETER DryRun
    Shows bindings that would be created without writing drift.lock.

.PARAMETER Refresh
    Re-links all discovered API docs, replacing existing bindings.

.PARAMETER DocPath
    Limits linking to specific markdown files or directories under docs/api/.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/link-api-drift.ps1

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/link-api-drift.ps1 -Refresh
#>

param(
    [switch]$DryRun,
    [switch]$Refresh,
    [string[]]$DocPath
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..')).Path
$docsApiRoot = Join-Path $repoRoot 'docs' 'api'
$docsBase = Join-Path $repoRoot 'docs'
$driftLockPath = Join-Path $repoRoot 'drift.lock'

function Get-ExistingDriftBindings {
    $bindings = @{}
    if (-not (Test-Path -LiteralPath $driftLockPath)) {
        return $bindings
    }

    foreach ($line in Get-Content -LiteralPath $driftLockPath) {
        if ($line -match '^(?<doc>.+?)\s+->\s+(?<target>.+?)\s+sig:') {
            $bindings["$($Matches.doc)|$($Matches.target)"] = $true
        }
    }

    return $bindings
}

function Resolve-SourcePathFromDoc {
    param(
        [string]$RelativeSource,
        [string]$DocsBasePath,
        [string]$RepoRootPath
    )

    $candidate = Join-Path $DocsBasePath ($RelativeSource -replace '/', [IO.Path]::DirectorySeparatorChar)
    $fullPath = [IO.Path]::GetFullPath($candidate)
    if (-not $fullPath.StartsWith($RepoRootPath, [StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }

    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        return $null
    }

    return ($fullPath.Substring($RepoRootPath.Length)).TrimStart('\', '/').Replace('\', '/')
}

if ($DocPath) {
    $docFiles = @(
        foreach ($path in $DocPath) {
            $resolved = if ([IO.Path]::IsPathRooted($path)) { $path } else { Join-Path $repoRoot $path }
            $resolved = (Resolve-Path -LiteralPath $resolved -ErrorAction Stop).Path
            if ((Get-Item -LiteralPath $resolved).PSIsContainer) {
                Get-ChildItem -Path $resolved -Filter '*.md' -Recurse -File
            }
            else {
                Get-Item -LiteralPath $resolved
            }
        }
    )
}
else {
    $docFiles = @(Get-ChildItem -Path $docsApiRoot -Filter '*.md' -Recurse -File)
}

$docFiles = @($docFiles | Where-Object { $_.Name -ne 'README.md' })

if (-not (Get-Command drift -ErrorAction SilentlyContinue)) {
    throw 'drift CLI not found on PATH'
}

$knownBindings = Get-ExistingDriftBindings
$linked = 0
$skippedExisting = 0
$skippedUnresolved = [System.Collections.Generic.List[string]]::new()
$failed = [System.Collections.Generic.List[string]]::new()

foreach ($docFile in $docFiles) {
    $docRelative = ($docFile.FullName.Substring($repoRoot.Length)).TrimStart('\', '/').Replace('\', '/')
    $content = Get-Content -LiteralPath $docFile.FullName -Raw
    if ($content -notmatch 'Defined in:\s*(?<path>\S+)') {
        $skippedUnresolved.Add($docRelative)
        continue
    }

    $source = Resolve-SourcePathFromDoc -RelativeSource $Matches.path -DocsBasePath $docsBase -RepoRootPath $repoRoot
    if (-not $source) {
        $skippedUnresolved.Add($docRelative)
        continue
    }

    $bindingKey = "$docRelative|$source"
    if (-not $Refresh -and $knownBindings.ContainsKey($bindingKey)) {
        $skippedExisting++
        continue
    }

    if ($DryRun) {
        Write-Host "would link: $docRelative -> $source"
        $linked++
        continue
    }

    $linkArgs = @($docRelative, $source)
    if ($Refresh) {
        $linkArgs += '--doc-is-still-accurate'
    }

    $output = & drift link @linkArgs 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -and $output -match 'refused: target changed since last link') {
        $output = & drift link $docRelative $source --doc-is-still-accurate 2>&1 | Out-String
    }

    if ($LASTEXITCODE -eq 0) {
        if ($output.Trim()) {
            Write-Host $output.Trim()
        }
        $knownBindings[$bindingKey] = $true
        $linked++
    }
    else {
        $failed.Add("$docRelative -> $source : $output")
    }
}

Write-Host ''
Write-Host 'Drift API linking summary:'
Write-Host "  Linked:             $linked"
Write-Host "  Skipped (existing): $skippedExisting"
Write-Host "  Unresolved:         $($skippedUnresolved.Count)"
Write-Host "  Failed:             $($failed.Count)"

if ($skippedUnresolved.Count -gt 0 -and $skippedUnresolved.Count -le 20) {
    Write-Host ''
    Write-Host 'Unresolved docs:'
    $skippedUnresolved | ForEach-Object { Write-Host "  $_" }
}
elseif ($skippedUnresolved.Count -gt 20) {
    Write-Host ''
    Write-Host 'First 20 unresolved docs:'
    $skippedUnresolved | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }
}

if ($failed.Count -gt 0) {
    Write-Host ''
    Write-Host 'Failures:'
    $failed | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }
    exit 1
}
