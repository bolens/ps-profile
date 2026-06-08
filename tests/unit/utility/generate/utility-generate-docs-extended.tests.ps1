<#
tests/unit/utility-generate-docs-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for generate-docs.ps1 API documentation generator.
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
    $script:GenerateDocsScript = Join-Path $script:TestRepoRoot 'scripts/utils/docs/generate-docs.ps1'
}

Describe 'generate-docs.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents OutputPath and DryRun parameters' {
            $content = Get-Content -LiteralPath $script:GenerateDocsScript -Raw
            $content | Should -Match '\.PARAMETER OutputPath'
            $content | Should -Match '\.PARAMETER DryRun'
        }

        It 'Defaults output to docs/api' {
            $content = Get-Content -LiteralPath $script:GenerateDocsScript -Raw
            $content | Should -Match 'docs/api'
        }
    }

    Context 'Documentation generation' {
        It 'Scans profile.d for comment-based help content' {
            $content = Get-Content -LiteralPath $script:GenerateDocsScript -Raw
            $content | Should -Match 'profile\.d'
            $content | Should -Match 'DocParser'
        }

        It 'Generates separate function and alias documentation sections' {
            $content = Get-Content -LiteralPath $script:GenerateDocsScript -Raw
            $content | Should -Match 'alias'
            $content | Should -Match 'function'
        }
    }

    Context 'Module imports' {
        It 'Uses documentation modules for parsing and generation' {
            $content = Get-Content -LiteralPath $script:GenerateDocsScript -Raw
            $content | Should -Match 'DocParser\.psm1'
            $content | Should -Match 'DocGenerator\.psm1'
        }
    }
}
