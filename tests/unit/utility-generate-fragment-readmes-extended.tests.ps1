<#
tests/unit/utility-generate-fragment-readmes-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for generate-fragment-readmes.ps1 fragment README generator.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ReadmeScript = Join-Path $script:TestRepoRoot 'scripts/utils/docs/generate-fragment-readmes.ps1'
}

Describe 'generate-fragment-readmes.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Force OutputPath and DryRun parameters' {
            $content = Get-Content -LiteralPath $script:ReadmeScript -Raw
            $content | Should -Match '\.PARAMETER Force'
            $content | Should -Match '\.PARAMETER OutputPath'
            $content | Should -Match '\.PARAMETER DryRun'
        }

        It 'Defaults output to docs/fragments' {
            $content = Get-Content -LiteralPath $script:ReadmeScript -Raw
            $content | Should -Match 'docs/fragments'
        }
    }

    Context 'README generation' {
        It 'Scans profile.d fragments for purpose and function summaries' {
            $content = Get-Content -LiteralPath $script:ReadmeScript -Raw
            $content | Should -Match 'profile\.d'
            $content | Should -Match 'Set-AgentModeFunction'
        }

        It 'Preserves existing README files unless Force is specified' {
            $content = Get-Content -LiteralPath $script:ReadmeScript -Raw
            $content | Should -Match 'preserved unless -Force is used'
        }
    }
}
