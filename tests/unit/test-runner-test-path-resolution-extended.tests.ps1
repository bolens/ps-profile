<#
tests/unit/test-runner-test-path-resolution-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestPathResolution discovery edge cases.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    $libPath = Join-Path $PSScriptRoot '../../scripts/lib'
    Import-Module (Join-Path $libPath 'file/FileSystem.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestPathResolution.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempRoot = New-TestTempDirectory -Prefix 'TestPathResolutionExtended'
}

AfterAll {
    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestPathResolution extended scenarios' {
    Context 'Get-SpecificTestPaths' {
        It 'Deduplicates and sorts multiple explicit test files' {
            $fileA = Join-Path $script:TempRoot 'alpha.tests.ps1'
            $fileB = Join-Path $script:TempRoot 'beta.tests.ps1'
            Set-Content -LiteralPath $fileA -Value 'Describe alpha {}' -Encoding UTF8
            Set-Content -LiteralPath $fileB -Value 'Describe beta {}' -Encoding UTF8

            $paths = @(Get-SpecificTestPaths -TestFile @($fileB, $fileA, $fileB) -Suite 'Unit' -RepoRoot $script:TestRepoRoot)

            @($paths).Count | Should -Be 2
            $paths | Should -Be ($paths | Sort-Object)
        }

        It 'Resolves absolute test file paths directly' {
            $testFile = Join-Path $script:TestRepoRoot 'tests/unit/library-common.tests.ps1'
            if (-not (Test-Path -LiteralPath $testFile)) {
                Set-ItResult -Skipped -Because 'library-common.tests.ps1 not found'
                return
            }

            $paths = @(Get-SpecificTestPaths -TestFile @($testFile) -Suite 'Unit' -RepoRoot $script:TestRepoRoot)
            $paths | Should -Contain $testFile
        }

        It 'Throws when a requested test path does not exist' {
            $missing = Join-Path $script:TempRoot 'missing-target.tests.ps1'

            { Get-SpecificTestPaths -TestFile @($missing) -Suite 'Unit' -RepoRoot $script:TestRepoRoot } |
                Should -Throw '*Test file or directory not found*'
        }

        It 'Skips blank entries in TestFile arrays' {
            $testFile = Join-Path $script:TempRoot 'only-valid.tests.ps1'
            Set-Content -LiteralPath $testFile -Value 'Describe valid {}' -Encoding UTF8

            $paths = @(Get-SpecificTestPaths -TestFile @('', '   ', $testFile) -Suite 'Unit' -RepoRoot $script:TestRepoRoot)

            @($paths).Count | Should -Be 1
            $paths[0] | Should -Be $testFile
        }
    }

    Context 'Get-TestPaths' {
        It 'Expands performance suite directories to test files' {
            $paths = @(Get-TestPaths -Suite 'Performance' -RepoRoot $script:TestRepoRoot)

            @($paths).Count | Should -BeGreaterThan 0
            @($paths | Where-Object { $_ -like '*tests/performance*' -and $_.EndsWith('.tests.ps1') }).Count |
                Should -BeGreaterThan 0
        }

        It 'Returns suite paths when TestFile is whitespace-only' {
            $paths = @(Get-TestPaths -Suite 'Unit' -TestFile @('   ') -RepoRoot $script:TestRepoRoot)

            @($paths).Count | Should -BeGreaterThan 0
            @($paths | Where-Object { $_ -like '*tests/unit*' }).Count | Should -BeGreaterThan 0
        }
    }
}
