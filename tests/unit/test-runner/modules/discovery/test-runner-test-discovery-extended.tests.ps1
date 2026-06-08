<#
tests/unit/test-runner-test-discovery-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for test path discovery and directory expansion.
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
    $modulePath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/utils/code-quality/modules'
    $libPath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib'
    Import-Module (Join-Path $libPath 'file/FileSystem.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestPathResolution.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempRoot = New-TestTempDirectory -Prefix 'TestDiscoveryExtended'
}

AfterAll {
    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Test discovery extended scenarios' {
    Context 'Get-TestFilesFromDirectory' {
        It 'Finds test files in nested subdirectories' {
            $nestedDir = Join-Path $script:TempRoot 'nested' 'suite'
            New-Item -ItemType Directory -Path $nestedDir -Force | Out-Null
            $deepFile = Join-Path $nestedDir 'deep.tests.ps1'
            Set-Content -LiteralPath $deepFile -Value 'Describe deep {}' -Encoding UTF8

            $files = @(Get-TestFilesFromDirectory -Directory $script:TempRoot)

            $files | Should -Contain $deepFile
        }

        It 'Returns sorted unique file paths' {
            $fileA = Join-Path $script:TempRoot 'alpha.tests.ps1'
            $fileB = Join-Path $script:TempRoot 'beta.tests.ps1'
            Set-Content -LiteralPath $fileA -Value 'Describe alpha {}' -Encoding UTF8
            Set-Content -LiteralPath $fileB -Value 'Describe beta {}' -Encoding UTF8

            $files = @(Get-TestFilesFromDirectory -Directory $script:TempRoot)

            $files | Should -Be ($files | Sort-Object -Unique)
        }
    }

    Context 'Get-TestPaths' {
        It 'Resolves multiple explicit test files' {
            $fileA = Join-Path $script:TempRoot 'multi-a.tests.ps1'
            $fileB = Join-Path $script:TempRoot 'multi-b.tests.ps1'
            Set-Content -LiteralPath $fileA -Value 'Describe a {}' -Encoding UTF8
            Set-Content -LiteralPath $fileB -Value 'Describe b {}' -Encoding UTF8

            $relativeA = $fileA.Substring($script:TestRepoRoot.Length).TrimStart('/', '\')
            $relativeB = $fileB.Substring($script:TestRepoRoot.Length).TrimStart('/', '\')
            $paths = @(Get-TestPaths -Suite 'Unit' -TestFile @($relativeA, $relativeB) -RepoRoot $script:TestRepoRoot)

            @($paths).Count | Should -Be 2
            $paths | Should -Contain $fileA
            $paths | Should -Contain $fileB
        }

        It 'Uses suite expansion when TestFile is an empty array' {
            $paths = @(Get-TestPaths -Suite 'Unit' -TestFile @() -RepoRoot $script:TestRepoRoot)

            @($paths | Where-Object { $_ -like '*tests/unit*' -and $_.EndsWith('.tests.ps1') }).Count |
                Should -BeGreaterThan 0
        }
    }

    Context 'Get-TestSuitePaths' {
        It 'Includes integration tests when suite is All' {
            $paths = @(Get-TestSuitePaths -Suite 'All' -RepoRoot $script:TestRepoRoot)

            @($paths | Where-Object { $_ -like '*tests/integration*' }).Count | Should -BeGreaterThan 0
        }
    }
}
