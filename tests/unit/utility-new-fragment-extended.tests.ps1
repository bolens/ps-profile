<#
tests/unit/utility-new-fragment-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for new-fragment.ps1 fragment scaffolding script.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:NewFragmentScript = Join-Path $script:TestRepoRoot 'scripts/utils/fragment/new-fragment.ps1'
}

Describe 'new-fragment.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Name Number Dependencies and Description parameters' {
            $content = Get-Content -LiteralPath $script:NewFragmentScript -Raw
            $content | Should -Match '\.PARAMETER Name'
            $content | Should -Match '\.PARAMETER Number'
            $content | Should -Match '\.PARAMETER Dependencies'
            $content | Should -Match '\.PARAMETER Description'
        }

        It 'Uses FragmentTier enum for fragment classification' {
            $content = Get-Content -LiteralPath $script:NewFragmentScript -Raw
            $content | Should -Match 'FragmentTier'
        }
    }

    Context 'Fragment scaffolding' {
        It 'Generates idempotent fragment boilerplate guidance' {
            $content = Get-Content -LiteralPath $script:NewFragmentScript -Raw
            $content | Should -Match 'Set-AgentModeFunction'
            $content | Should -Match 'idempotent'
        }

        It 'Creates README template alongside the fragment file' {
            $content = Get-Content -LiteralPath $script:NewFragmentScript -Raw
            $content | Should -Match 'README'
        }
    }

    Context 'Dependency handling' {
        It 'Defaults fragment dependencies to bootstrap' {
            $content = Get-Content -LiteralPath $script:NewFragmentScript -Raw
            $content | Should -Match "'bootstrap'"
        }
    }
}
