<#
tests/unit/test-support-scoop-helpers.tests.ps1

.SYNOPSIS
    Unit tests for TestScoopHelpers utilities.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
}

Describe 'TestScoopHelpers Module' {
    Context 'Test-ScoopPackageAvailable' {
        It 'Returns false when scoop is not installed' {
            if (Get-Command scoop -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'scoop is installed on this host'
                return
            }

            Test-ScoopPackageAvailable -PackageName 'bat' | Should -Be $false
        }

        It 'Returns false for packages that are not installed' {
            if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'scoop is not installed on this host'
                return
            }

            Test-ScoopPackageAvailable -PackageName 'zzz-nonexistent-scoop-package-xyz' | Should -Be $false
        }
    }
}
