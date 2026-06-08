#Requires -Version 7.0
<#
.SYNOPSIS
    Replaces shallow TestSupport.ps1 relative imports with depth-aware resolution.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
)

$walkerBody = @'
$current = Get-Item $PSScriptRoot
while ($null -ne $current) {
    $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
    if (Test-Path -LiteralPath $testSupportPath) {
        . $testSupportPath
        break
    }
    if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
    $current = $current.Parent
}
'@

$roots = @(
    (Join-Path $RepoRoot 'tests' 'unit')
    (Join-Path $RepoRoot 'tests' 'integration')
    (Join-Path $RepoRoot 'tests' 'performance')
)

$pattern = '(?m)^(?<indent>[ \t]*)\.\s*(?:\(Join-Path\s+\$PSScriptRoot\s+''(?:(?:\.\.[\\/])+)?TestSupport\.ps1''\)|\$PSScriptRoot[\\/]\.\.(?:[\\/]\.\.)*[\\/]TestSupport\.ps1)\s*$'

$count = 0
foreach ($root in $roots) {
    if (-not (Test-Path -LiteralPath $root)) {
        continue
    }

    Get-ChildItem -Path $root -Filter '*.tests.ps1' -Recurse -File | ForEach-Object {
        $content = Get-Content -LiteralPath $_.FullName -Raw
        if ($content -notmatch 'TestSupport\.ps1') {
            return
        }

        $updated = [regex]::Replace($content, $pattern, {
            param($match)
            $indent = $match.Groups['indent'].Value
            $indentedWalker = ($walkerBody -split "`n" | ForEach-Object { "$indent$_" }) -join "`n"
            return $indentedWalker
        })

        if ($updated -ne $content) {
            [System.IO.File]::WriteAllText($_.FullName, $updated)
            $count++
            Write-Output $_.FullName
        }
    }
}

Write-Output "Fixed $count file(s)."
