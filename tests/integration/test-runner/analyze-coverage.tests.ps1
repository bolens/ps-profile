<#
tests/integration/test-runner/analyze-coverage.tests.ps1

.SYNOPSIS
    Integration tests for analyze-coverage.ps1 developer workflow script.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:AnalyzeCoverageScript = Join-Path $script:RepoRoot 'scripts' 'utils' 'code-quality' 'analyze-coverage.ps1'
    $script:PsExe = (Get-Command pwsh -ErrorAction Stop).Source
}

Describe 'analyze-coverage integration' {
    Context 'Script structure' {
        It 'Exists with comment-based help' {
            Test-Path -LiteralPath $script:AnalyzeCoverageScript | Should -Be $true
            $help = Get-Help $script:AnalyzeCoverageScript -ErrorAction SilentlyContinue
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It 'Documents Path and OutputPath parameters' {
            $content = Get-Content -LiteralPath $script:AnalyzeCoverageScript -Raw
            $content | Should -Match '\.PARAMETER Path'
            $content | Should -Match '\.PARAMETER OutputPath'
        }
    }

    Context 'Coverage analysis execution' {
        It 'Requires Pester 5+ before running analysis' {
            $content = Get-Content -LiteralPath $script:AnalyzeCoverageScript -Raw
            $content | Should -Match "Pester 5\.0\+"
            $content | Should -Match 'PS_PROFILE_TEST_MODE'
        }

        It 'Completes without setup errors when the target path does not exist' {
            $missingPath = Join-Path $script:RepoRoot 'profile.d' '__missing-coverage-target__.ps1'
            $output = & $script:PsExe -NoProfile -File $script:AnalyzeCoverageScript -Path $missingPath 2>&1
            $LASTEXITCODE | Should -BeIn @(0, 1, 2, 3)
            ($output -join ' ') | Should -Match 'No source files|No matching test files'
        }
    }
}
