<#
tests/unit/utility-validate-fragment-dependencies-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for validate-fragment-dependencies.ps1 validation script.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ValidateDepsScript = Join-Path $script:TestRepoRoot 'scripts/utils/fragment/validate-fragment-dependencies.ps1'
}

Describe 'validate-fragment-dependencies.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents dependency and circular dependency validation' {
            $content = Get-Content -LiteralPath $script:ValidateDepsScript -Raw
            $content | Should -Match 'circular dependencies'
            $content | Should -Match 'missing'
        }
    }

    Context 'Fragment loading integration' {
        It 'Imports FragmentLoading module for dependency resolution' {
            $content = Get-Content -LiteralPath $script:ValidateDepsScript -Raw
            $content | Should -Match 'FragmentLoading\.psm1'
        }

        It 'Resolves repository root relative to script location' {
            $content = Get-Content -LiteralPath $script:ValidateDepsScript -Raw
            $content | Should -Match 'Split-Path -Parent'
            $content | Should -Match 'profile\.d'
        }
    }

    Context 'Exit code handling' {
        It 'Uses EXIT_VALIDATION_FAILURE when dependency issues are found' {
            $content = Get-Content -LiteralPath $script:ValidateDepsScript -Raw
            $content | Should -Match 'EXIT_VALIDATION_FAILURE'
        }

        It 'Reports missing and circular dependency details' {
            $content = Get-Content -LiteralPath $script:ValidateDepsScript -Raw
            $content | Should -Match 'MissingDependencies'
            $content | Should -Match 'CircularDependencies'
        }
    }
}
