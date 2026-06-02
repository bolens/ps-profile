#Requires -Version 7.0
<#
.SYNOPSIS
    Moves top-level TestSupport.ps1 dot-sourcing into Pester BeforeAll hooks.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot
)

$scriptsRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Import-Module (Join-Path $scriptsRoot 'lib' 'ModuleImport.psm1') -DisableNameChecking -ErrorAction Stop
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}

$dotSourcePattern = '(?m)^\. \(Join-Path \$PSScriptRoot ''(?<rel>(?:\.\.[\\/])+)TestSupport\.ps1''\)\r?\n\r?\n'
$importLineTemplate = "    . (Join-Path `$PSScriptRoot '{0}TestSupport.ps1')`n"

$paths = @(
    (Join-Path $RepoRoot 'tests' 'integration')
    (Join-Path $RepoRoot 'tests' 'performance')
)

$updatedFiles = [System.Collections.Generic.List[string]]::new()

foreach ($root in $paths) {
    Get-ChildItem -Path $root -Filter '*.tests.ps1' -Recurse -File | ForEach-Object {
        $filePath = $_.FullName
        $content = Get-Content -LiteralPath $filePath -Raw
        if ($content -notmatch '(?m)^\. \(Join-Path \$PSScriptRoot ''(?:\.\.[\\/])+)TestSupport\.ps1''\)') {
            continue
        }

        $updated = $content

        $updated = [regex]::Replace(
            $updated,
            '(?ms)^\. \(Join-Path \$PSScriptRoot ''(?<rel>(?:\.\.[\\/])+)TestSupport\.ps1''\)\r?\n\r?\nBeforeAll \{\r?\n',
            {
                param($match)
                "BeforeAll {`n$([string]::Format($importLineTemplate, $match.Groups['rel'].Value))"
            },
            1
        )

        if ($updated -match '(?m)^\. \(Join-Path \$PSScriptRoot ''(?<rel>(?:\.\.[\\/])+)TestSupport\.ps1''\)') {
            $updated = [regex]::Replace(
                $updated,
                '(?ms)^\. \(Join-Path \$PSScriptRoot ''(?<rel>(?:\.\.[\\/])+)TestSupport\.ps1''\)\r?\n\r?\nDescribe ',
                {
                    param($match)
                    $import = [string]::Format($importLineTemplate, $match.Groups['rel'].Value).TrimEnd()
                    "BeforeAll {`n$import`n}`n`nDescribe "
                },
                1
            )
        }

        if ($updated -ne $content) {
            [System.IO.File]::WriteAllText($filePath, $updated)
            $updatedFiles.Add($filePath)
        }
    }
}

Write-Output "Updated $($updatedFiles.Count) file(s)."
$updatedFiles | ForEach-Object { Write-Output $_ }
