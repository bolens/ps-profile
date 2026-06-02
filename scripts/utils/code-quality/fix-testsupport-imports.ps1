#Requires -Version 7.0
$roots = @(
    (Join-Path $PSScriptRoot '..' '..' '..' 'tests' 'integration')
    (Join-Path $PSScriptRoot '..' '..' '..' 'tests' 'performance')
)

$replacements = @(
    @{
        Old = "Join-Path `$PSScriptRoot '..\..\' 'TestSupport.ps1'"
        New = "Join-Path `$PSScriptRoot '..\..\TestSupport.ps1'"
    }
    @{
        Old = "Join-Path `$PSScriptRoot '..\' 'TestSupport.ps1'"
        New = "Join-Path `$PSScriptRoot '..\TestSupport.ps1'"
    }
)

$count = 0
foreach ($root in $roots) {
    Get-ChildItem -Path $root -Filter '*.tests.ps1' -Recurse -File | ForEach-Object {
        $content = Get-Content -LiteralPath $_.FullName -Raw
        $updated = $content
        foreach ($pair in $replacements) {
            $updated = $updated.Replace($pair.Old, $pair.New)
        }

        if ($updated -ne $content) {
            [System.IO.File]::WriteAllText($_.FullName, $updated)
            $count++
            Write-Output $_.FullName
        }
    }
}

Write-Output "Fixed $count file(s)."
