<#
tests/unit/test-support-scoop-helpers.tests.ps1

.SYNOPSIS
    Unit tests for TestScoopHelpers utilities.
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
