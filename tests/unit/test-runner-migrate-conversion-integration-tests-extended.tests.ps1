<#
tests/unit/test-runner-migrate-conversion-integration-tests-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for migrate-conversion-integration-tests.ps1 migration script.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:MigrateScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/migrate-conversion-integration-tests.ps1'
}

Describe 'migrate-conversion-integration-tests.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Initialize-ConversionIntegrationForTestFile migration target' {
            $content = Get-Content -LiteralPath $script:MigrateScript -Raw
            $content | Should -Match 'Initialize-ConversionIntegrationForTestFile'
            $content | Should -Match 'LoadConversionModules'
        }

        It 'Supports WhatIfOnly preview mode' {
            $content = Get-Content -LiteralPath $script:MigrateScript -Raw
            $content | Should -Match 'WhatIfOnly'
            $content | Should -Match 'Would update'
        }
    }

    Context 'Replacement patterns' {
        It 'Replaces legacy Initialize-TestProfile conversion setup calls' {
            $content = Get-Content -LiteralPath $script:MigrateScript -Raw
            $content | Should -Match 'oldPatterns'
            $content | Should -Match 'EnsureFileConversion'
        }

        It 'Skips files that already use Initialize-ConversionIntegration helpers' {
            $content = Get-Content -LiteralPath $script:MigrateScript -Raw
            $content | Should -Match 'Initialize-ConversionIntegration'
            $content | Should -Match 'skipFiles'
        }
    }

    Context 'Discovery scope' {
        It 'Scans tests/integration/conversion recursively' {
            $content = Get-Content -LiteralPath $script:MigrateScript -Raw
            $content | Should -Match "'tests' 'integration' 'conversion'"
            $content | Should -Match '-Recurse'
        }
    }
}
