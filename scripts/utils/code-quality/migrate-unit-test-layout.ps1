#Requires -Version 7.0
<#
.SYNOPSIS
    Reorganizes flat unit and performance test files into category subdirectories.

.DESCRIPTION
    Moves tests/unit/*.tests.ps1 into tests/unit/<category>/... based on filename
    prefixes, and tests/performance/*.tests.ps1 into tests/performance/<category>/.

    Filenames are preserved so existing -Filter patterns (profile-, library-, etc.)
    continue to work. Discovery already supports recursive *.tests.ps1 search.

.PARAMETER RepoRoot
    Repository root directory.

.PARAMETER WhatIfOnly
    Print planned moves without changing files.

.PARAMETER PerformanceOnly
    Move only performance tests.

.PARAMETER UnitOnly
    Move only unit tests.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/migrate-unit-test-layout.ps1 -WhatIfOnly

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/migrate-unit-test-layout.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),

    [switch]$WhatIfOnly,

    [switch]$PerformanceOnly,

    [switch]$UnitOnly
)

$ErrorActionPreference = 'Stop'

function Get-UnitTestRelativeSubdir {
    param([string]$FileName)

    $base = $FileName -replace '\.tests\.ps1$', ''
    if ($base -eq 'test-support') {
        return 'test-support'
    }

    $parts = $base -split '-'

    if ($base -like 'test-runner-*') {
        $rest = ($base -replace '^test-runner-', '') -split '-'
        if ($rest[0] -eq 'test' -and $rest.Count -gt 1) {
            return (Join-Path 'test-runner' 'modules' $rest[1])
        }

        return (Join-Path 'test-runner' $rest[0])
    }

    if ($base -like 'test-support-*') {
        $rest = ($base -replace '^test-support-', '') -split '-'
        if ($rest.Count -eq 0 -or [string]::IsNullOrWhiteSpace($rest[0])) {
            return 'test-support'
        }

        return (Join-Path 'test-support' $rest[0])
    }

    $category = $parts[0]
    switch ($category) {
        'profile' {
            if ($parts.Count -lt 2) {
                return 'profile'
            }

            if ($parts[1] -eq 'conversion') {
                $sub = @('profile', 'conversion')
                if ($parts.Count -gt 2) {
                    $sub += $parts[2]
                }

                if ($parts.Count -gt 3 -and $parts[2] -in @('data', 'media', 'document')) {
                    $sub += $parts[3]

                    if ($parts[2] -eq 'data' -and $parts.Count -gt 5 -and $parts[3] -eq $parts[4] -and $parts[5] -in @('schema', 'protocol')) {
                        $sub += $parts[5]
                    }
                }

                return ($sub -join [IO.Path]::DirectorySeparatorChar)
            }

            if ($parts[1] -eq 'dev' -and $parts.Count -gt 2 -and $parts[2] -eq 'tools') {
                if ($parts.Count -gt 3) {
                    return (Join-Path 'profile' 'dev-tools' $parts[3])
                }

                return (Join-Path 'profile' 'dev-tools')
            }

            if ($parts[1] -eq 'main' -and $parts.Count -gt 2 -and $parts[2] -eq 'loader') {
                return (Join-Path 'profile' 'main' 'loader')
            }

            if ($parts[1] -eq 'lang' -and $parts.Count -gt 2) {
                return (Join-Path 'profile' 'lang' $parts[2])
            }

            if ($parts[1] -eq 'kubernetes' -and $parts.Count -gt 2 -and $parts[2] -eq 'kube') {
                return (Join-Path 'profile' 'kubernetes')
            }

            return (Join-Path 'profile' $parts[1])
        }
        default {
            if ($parts.Count -gt 1) {
                return (Join-Path $category $parts[1])
            }

            return $category
        }
    }
}

function Get-PerformanceTestRelativeSubdir {
    param([string]$FileName)

    $base = $FileName -replace '\.tests\.ps1$', ''
    if ($base -eq 'performance') {
        return 'core'
    }

    if ($base -like 'lang-*') {
        return 'lang'
    }

    if ($base -like 'test-runner-*') {
        return 'test-runner'
    }

    return 'profile'
}

function Move-TestFile {
    param(
        [System.IO.FileInfo]$File,
        [string]$TargetSubdir,
        [string]$SuiteRoot
    )

    $destDir = Join-Path $SuiteRoot $TargetSubdir
    $destPath = Join-Path $destDir $File.Name

    if ($File.FullName -eq $destPath) {
        return 'skipped'
    }

    if (-not (Test-Path -LiteralPath $destDir)) {
        if ($WhatIfOnly) {
            Write-Host "Would create: $destDir"
        }
        elseif ($PSCmdlet.ShouldProcess($destDir, 'Create directory')) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
    }

    if ($WhatIfOnly) {
        Write-Host "Would move: $($File.FullName) -> $destPath"
        return 'moved'
    }

    if ($PSCmdlet.ShouldProcess($File.FullName, "Move to $destPath")) {
        Move-Item -LiteralPath $File.FullName -Destination $destPath
        return 'moved'
    }

    return 'skipped'
}

$moved = 0
$skipped = 0

if (-not $PerformanceOnly) {
    $unitRoot = Join-Path $RepoRoot 'tests' 'unit'
    $unitFiles = @(Get-ChildItem -LiteralPath $unitRoot -Filter '*.tests.ps1' -File -ErrorAction Stop)
    Write-Host "Unit tests to relocate: $($unitFiles.Count)" -ForegroundColor Cyan

    foreach ($file in $unitFiles) {
        $subdir = Get-UnitTestRelativeSubdir -FileName $file.Name
        $result = Move-TestFile -File $file -TargetSubdir $subdir -SuiteRoot $unitRoot
        if ($result -eq 'moved') { $moved++ } else { $skipped++ }
    }
}

if (-not $UnitOnly) {
    $perfRoot = Join-Path $RepoRoot 'tests' 'performance'
    $perfFiles = @(Get-ChildItem -LiteralPath $perfRoot -Filter '*.tests.ps1' -File -ErrorAction Stop)
    Write-Host "Performance tests to relocate: $($perfFiles.Count)" -ForegroundColor Cyan

    foreach ($file in $perfFiles) {
        $subdir = Get-PerformanceTestRelativeSubdir -FileName $file.Name
        $result = Move-TestFile -File $file -TargetSubdir $subdir -SuiteRoot $perfRoot
        if ($result -eq 'moved') { $moved++ } else { $skipped++ }
    }
}

Write-Host "Migration complete. Moved: $moved, Skipped: $skipped" -ForegroundColor Green
