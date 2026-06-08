#Requires -Version 7.0
<#
.SYNOPSIS
    Cleans redundant or low-quality .EXAMPLE lines from comment help.

.DESCRIPTION
    Removes duplicate -Arguments @('--help') examples when a better example
    follows, and downgrades standalone --help examples to bare function names.
#>
param(
    [Parameter(Mandatory)]
    [string[]]$Path
)

foreach ($targetPath in $Path) {
    if (-not (Test-Path -LiteralPath $targetPath)) {
        continue
    }

    $files = if ((Get-Item -LiteralPath $targetPath).PSIsContainer) {
        Get-ChildItem -Path $targetPath -Recurse -Include '*.ps1', '*.psm1' -File
    }
    else {
        , (Get-Item -LiteralPath $targetPath)
    }

    foreach ($file in $files) {
        $text = Get-Content -LiteralPath $file.FullName -Raw
        $orig = $text

        $text = [regex]::Replace(
            $text,
            '(?ms)(^\s*\.EXAMPLE\s*\r?\n\s*\S+ -Arguments @\(''--help''\)\s*\r?\n)(?=^\s*\.EXAMPLE)',
            ''
        )

        $text = [regex]::Replace(
            $text,
            '(?m)^(\s*\.EXAMPLE\s*\r?\n)\s*([A-Za-z][A-Za-z0-9-]*) -Arguments @\(''--help''\)\s*$',
            '${1}    ${2}'
        )

        if ($text -ne $orig) {
            Set-Content -LiteralPath $file.FullName -Value $text -NoNewline -Encoding UTF8
            Write-Output "Cleaned: $($file.FullName)"
        }
    }
}
