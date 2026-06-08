#Requires -Version 7.0
<#
.SYNOPSIS
    Replaces shallow repo-root and scripts/ path resolution in test files.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
)

$roots = @(
    (Join-Path $RepoRoot 'tests' 'unit')
    (Join-Path $RepoRoot 'tests' 'integration')
    (Join-Path $RepoRoot 'tests' 'performance')
)

$count = 0
foreach ($root in $roots) {
    if (-not (Test-Path -LiteralPath $root)) {
        continue
    }

    Get-ChildItem -Path $root -Filter '*.tests.ps1' -Recurse -File | ForEach-Object {
        $content = Get-Content -LiteralPath $_.FullName -Raw
        $updated = $content

        $updated = $updated -replace '\$script:TestRepoRoot\s*=\s*Split-Path \(Split-Path \$PSScriptRoot -Parent\) -Parent', '$script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot'

        $updated = $updated -replace 'Join-Path \$PSScriptRoot ''(\.\./)+scripts', 'Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) ''scripts'

        if ($updated -ne $content) {
            [System.IO.File]::WriteAllText($_.FullName, $updated)
            $count++
            Write-Output $_.FullName
        }
    }
}

Write-Output "Fixed $count file(s)."
