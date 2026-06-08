<#
tests/unit/library-path-utilities-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for PathUtilities relative path edge cases.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'path' 'PathUtilities.psm1') -DisableNameChecking -Force

    $script:TempRoot = New-TestTempDirectory -Prefix 'PathUtilitiesExtended'
    $script:BaseDir = Join-Path $script:TempRoot 'base'
    $script:TargetFile = Join-Path $script:TempRoot 'target' 'sample.txt'

    New-Item -ItemType Directory -Path (Split-Path $script:TargetFile) -Force | Out-Null
    Set-Content -LiteralPath $script:TargetFile -Value 'sample' -Encoding UTF8
}

AfterAll {
    Remove-Module PathUtilities -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PathUtilities extended scenarios' {
    Context 'Get-RelativePath' {
        It 'Calculates relative paths between sibling directories' {
            $relative = Get-RelativePath -From $script:BaseDir -To $script:TargetFile

            $relative | Should -Not -BeNullOrEmpty
            ($relative -replace '\\', '/') | Should -Match 'target'
        }

        It 'Returns a dot-relative path for the same directory' {
            $relative = Get-RelativePath -From $script:BaseDir -To $script:BaseDir

            $relative | Should -Match '^\.'
        }
    }

    Context 'ConvertTo-RepoRelativePath' {
        It 'Converts nested files under the repository root' {
            $relative = ConvertTo-RepoRelativePath -Path $script:TargetFile -RepoRoot $script:TempRoot

            ($relative -replace '\\', '/') | Should -Match 'target/sample\.txt'
        }

        It 'Handles trailing separators on the repository root' {
            $repoRoot = "$($script:TempRoot)/"
            $relative = ConvertTo-RepoRelativePath -Path $script:TargetFile -RepoRoot $repoRoot

            $relative | Should -Not -BeNullOrEmpty
            ($relative -replace '\\', '/') | Should -Match 'target'
        }
    }

    Context 'Normalize-Path' {
        It 'Resolves existing paths to absolute form without a repository root' {
            $normalized = Normalize-Path -Path $script:TargetFile

            [System.IO.Path]::IsPathRooted($normalized) | Should -Be $true
            Test-Path -LiteralPath $normalized | Should -Be $true
        }
    }
}
