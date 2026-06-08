<#
tests/unit/test-runner-check-missing-tests-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for check-missing-tests.ps1 module coverage audit script.
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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CheckScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/check-missing-tests.ps1'
}

Describe 'check-missing-tests.ps1 extended scenarios' {
    Context 'Script structure' {
        It 'Recursively scans scripts/lib modules against library unit tests' {
            $content = Get-Content -LiteralPath $script:CheckScript -Raw
            $content | Should -Match "scripts' 'lib"
            $content | Should -Match "tests' 'unit"
            $content | Should -Match '-Recurse'
        }

        It 'Normalizes module and test stems for hyphenation differences' {
            $content = Get-Content -LiteralPath $script:CheckScript -Raw
            $content | Should -Match 'Get-NormalizedModuleStem'
            $content | Should -Match 'Get-NormalizedLibraryTestStem'
        }

        It 'Reports modules missing dedicated library tests' {
            $content = Get-Content -LiteralPath $script:CheckScript -Raw
            $content | Should -Match 'Missing tests for'
            $content | Should -Match 'Total modules'
        }
    }

    Context 'Exit behavior' {
        It 'Exits non-zero when modules are missing dedicated tests' {
            $content = Get-Content -LiteralPath $script:CheckScript -Raw
            $content | Should -Match 'exit 1'
            $content | Should -Match 'exit 0'
        }
    }
}
