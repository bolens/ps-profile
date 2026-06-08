<#
tests/unit/test-runner-analyze-coverage-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for analyze-coverage.ps1 script structure and configuration.
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
    $script:AnalyzeCoverageScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/analyze-coverage.ps1'
}

Describe 'analyze-coverage.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Path and OutputPath parameters' {
            $content = Get-Content -LiteralPath $script:AnalyzeCoverageScript -Raw
            $content | Should -Match '\.PARAMETER Path'
            $content | Should -Match '\.PARAMETER OutputPath'
        }

        It 'Defaults analysis to profile.d/bootstrap' {
            $content = Get-Content -LiteralPath $script:AnalyzeCoverageScript -Raw
            $content | Should -Match "Path = @\('profile\.d/bootstrap'\)"
        }
    }

    Context 'Non-interactive execution' {
        It 'Sets PS_PROFILE_NONINTERACTIVE before running tests' {
            $content = Get-Content -LiteralPath $script:AnalyzeCoverageScript -Raw
            $content | Should -Match "PS_PROFILE_NONINTERACTIVE = '1'"
            $content | Should -Match "ConfirmPreference = 'None'"
        }

        It 'Requires Pester 5.0 or newer' {
            $content = Get-Content -LiteralPath $script:AnalyzeCoverageScript -Raw
            $content | Should -Match "Pester 5\.0\+ is required"
            $content | Should -Match "MinimumVersion 5\.0"
        }
    }

    Context 'Test-to-source mapping' {
        It 'Maintains explicit testToSourceMappings for library tests' {
            $content = Get-Content -LiteralPath $script:AnalyzeCoverageScript -Raw
            $content | Should -Match 'testToSourceMappings'
            $content | Should -Match "'profile-module-loading'"
            $content | Should -Match 'sourceToTestMappings'
        }
    }
}
