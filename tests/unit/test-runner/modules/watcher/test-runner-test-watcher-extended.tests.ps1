<#
tests/unit/test-runner-test-watcher-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestWatcher file matching patterns.
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
    Import-Module (Join-Path $modulePath 'TestWatcher.psm1') -Force -Global
}

Describe 'TestWatcher extended scenarios' {
    Context 'Test-WatcherFileMatch' {
        It 'Matches custom test file patterns' {
            Test-WatcherFileMatch -FileName 'sample.spec.tests.ps1' -FullPath '/tmp/sample.spec.tests.ps1' -TestFiles @('*.spec.tests.ps1') -SourceFiles @('*.ps1') |
                Should -Be $true
        }

        It 'Matches profile modules via source file patterns' {
            Test-WatcherFileMatch -FileName 'ProfileLoader.psm1' -FullPath '/tmp/modules/ProfileLoader.psm1' |
                Should -Be $true
        }

        It 'Matches nested paths ending in .psm1 through extension fallback' {
            Test-WatcherFileMatch -FileName 'NestedModule.psm1' -FullPath '/tmp/deep/nested/NestedModule.psm1' -TestFiles @('*.tests.ps1') -SourceFiles @('*.custom.ps1') |
                Should -Be $true
        }

        It 'Rejects non-PowerShell artifacts such as JSON files' {
            Test-WatcherFileMatch -FileName 'package.json' -FullPath '/tmp/package.json' |
                Should -Be $false
        }
    }
}
