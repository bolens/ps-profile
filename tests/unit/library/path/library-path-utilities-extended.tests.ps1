<#
tests/unit/library-path-utilities-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for PathUtilities relative path edge cases.
#>

BeforeAll {
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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:PathUtilitiesPath = Join-Path $script:LibPath 'path' 'PathUtilities.psm1'
    Import-Module $script:PathUtilitiesPath -DisableNameChecking -Force

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

    Context 'PathUtilities test environment hooks' {
        It 'Resolves existing paths through Validation before calculating relatives' {
            Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue

            $relative = Get-RelativePath -From $script:BaseDir -To $script:TargetFile

            $relative | Should -Not -BeNullOrEmpty
            ($relative -replace '\\', '/') | Should -Match 'target'
        }

        It 'Uses URI-based fallback when forced through the test environment hook' {
            $originalFlag = $env:PS_PROFILE_PATH_UTILITIES_FORCE_URI_FALLBACK
            $env:PS_PROFILE_PATH_UTILITIES_FORCE_URI_FALLBACK = '1'

            try {
                $relative = Get-RelativePath -From $script:BaseDir -To $script:TargetFile
                $relative | Should -Not -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_PATH_UTILITIES_FORCE_URI_FALLBACK -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PATH_UTILITIES_FORCE_URI_FALLBACK = $originalFlag
                }
            }
        }

        It 'Returns the original target when URI schemes differ' {
            $originalFlag = $env:PS_PROFILE_PATH_UTILITIES_FORCE_URI_FALLBACK
            $env:PS_PROFILE_PATH_UTILITIES_FORCE_URI_FALLBACK = '1'

            try {
                $relative = Get-RelativePath -From 'file:///tmp/base' -To 'http://example.com/target'
                $relative | Should -Be 'http://example.com/target'
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_PATH_UTILITIES_FORCE_URI_FALLBACK -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PATH_UTILITIES_FORCE_URI_FALLBACK = $originalFlag
                }
            }
        }

        It 'Uses manual validation when PS_PROFILE_PATH_UTILITIES_SKIP_VALIDATION is enabled' {
            $missingFrom = Join-Path $script:TempRoot 'missing-from'
            $missingTo = Join-Path $script:TempRoot 'missing-to'
            $originalFlag = $env:PS_PROFILE_PATH_UTILITIES_SKIP_VALIDATION
            $env:PS_PROFILE_PATH_UTILITIES_SKIP_VALIDATION = '1'

            try {
                $relative = Get-RelativePath -From $missingFrom -To $missingTo
                $relative | Should -Not -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_PATH_UTILITIES_SKIP_VALIDATION -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PATH_UTILITIES_SKIP_VALIDATION = $originalFlag
                }
            }
        }

        It 'Converts repository-relative paths through Validation when available' {
            Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue

            $relative = ConvertTo-RepoRelativePath -Path $script:TargetFile -RepoRoot $script:TempRoot

            ($relative -replace '\\', '/') | Should -Match 'target/sample\.txt'
        }

        It 'Normalizes paths relative to a validated repository root' {
            Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue

            $normalized = Normalize-Path -Path $script:TargetFile -RepoRoot $script:TempRoot

            ($normalized -replace '\\', '/') | Should -Match 'target/sample\.txt'
        }

        It 'Uses string-based fallback when URI conversion fails' {
            $originalFlag = $env:PS_PROFILE_PATH_UTILITIES_FORCE_URI_FALLBACK
            $env:PS_PROFILE_PATH_UTILITIES_FORCE_URI_FALLBACK = '1'

            try {
                $fromPath = Join-Path $script:TempRoot 'fallback-base'
                $toPath = Join-Path $fromPath 'nested' 'sample.txt'
                New-Item -ItemType Directory -Path (Split-Path $toPath) -Force | Out-Null

                $relative = Get-RelativePath -From $fromPath -To $toPath
                ($relative -replace '\\', '/') | Should -Match 'nested/sample\.txt'
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_PATH_UTILITIES_FORCE_URI_FALLBACK -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PATH_UTILITIES_FORCE_URI_FALLBACK = $originalFlag
                }
            }
        }

        It 'Keeps the original path when repository resolution fails' {
            $outsideFile = Join-Path (Split-Path $script:TempRoot -Parent) "outside-$(New-Guid).txt"
            Set-Content -LiteralPath $outsideFile -Value 'outside' -Encoding UTF8

            $originalFlag = $env:PS_PROFILE_PATH_UTILITIES_FORCE_RESOLVE_ERROR
            $env:PS_PROFILE_PATH_UTILITIES_FORCE_RESOLVE_ERROR = '1'

            try {
                $relative = ConvertTo-RepoRelativePath -Path $outsideFile -RepoRoot $script:TempRoot
                $relative | Should -Be $outsideFile
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_PATH_UTILITIES_FORCE_RESOLVE_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PATH_UTILITIES_FORCE_RESOLVE_ERROR = $originalFlag
                }

                Remove-Item -LiteralPath $outsideFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
