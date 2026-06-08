<#
tests/unit/library-fragment-loading-class-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FragmentDependencyTestResult helper class.
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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'fragment' 'FragmentLoading.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module FragmentLoading -ErrorAction SilentlyContinue -Force
}

Describe 'FragmentDependencyTestResult extended scenarios' {
    Context 'FragmentDependencyTestResult class' {
        It 'Reports no issues for a default instance without dependency problems' {
            InModuleScope FragmentLoading {
                $result = [FragmentDependencyTestResult]::new()

                $result.Valid | Should -Be $false
                $result.HasIssues() | Should -Be $false
                $result.ToString() | Should -Not -Match 'Missing:'
            }
        }

        It 'Detects missing dependency issues' {
            InModuleScope FragmentLoading {
                $result = [FragmentDependencyTestResult]::new()
                $result.MissingDependencies = @('05-utilities.ps1')

                $result.HasIssues() | Should -Be $true
                $result.ToString() | Should -Match 'Missing: 05-utilities.ps1'
            }
        }

        It 'Detects circular dependency issues' {
            InModuleScope FragmentLoading {
                $result = [FragmentDependencyTestResult]::new()
                $result.CircularDependencies = @('11-git.ps1 -> 22-containers.ps1')

                $result.HasIssues() | Should -Be $true
                $result.ToString() | Should -Match 'Circular:'
            }
        }

        It 'Summarizes both missing and circular dependency problems' {
            InModuleScope FragmentLoading {
                $result = [FragmentDependencyTestResult]::new()
                $result.MissingDependencies = @('00-bootstrap.ps1')
                $result.CircularDependencies = @('30-tools.ps1 -> 31-tools.ps1')

                $summary = $result.ToString()

                $summary | Should -Match 'Missing: 00-bootstrap.ps1'
                $summary | Should -Match 'Circular: 30-tools.ps1 -> 31-tools.ps1'
            }
        }
    }
}
