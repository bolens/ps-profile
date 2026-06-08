<#
tests/unit/test-runner-test-categorization-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestCategorization category resolution.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestCategorization.psm1') -Force -Global
}

Describe 'TestCategorization extended scenarios' {
    Context 'Get-TestCategory' {
        It 'Prefers explicit Unit tags over file naming' {
            $test = [pscustomobject]@{
                Name = 'integration-style name'
                File = '/tmp/profile-integration.tests.ps1'
                Tags = @('Unit')
            }

            Get-TestCategory -Test $test | Should -Be 'Unit'
        }

        It 'Prefers explicit Performance tags over file naming' {
            $test = [pscustomobject]@{
                Name = 'generic test'
                File = '/tmp/library-common.tests.ps1'
                Tags = @('Performance')
            }

            Get-TestCategory -Test $test | Should -Be 'Performance'
        }

        It 'Detects integration tests from file names' {
            $test = [pscustomobject]@{
                Name = 'loads profile fragments'
                File = '/tmp/tests/integration/tools/sample-integration.tests.ps1'
                Tags = @()
            }

            Get-TestCategory -Test $test | Should -Be 'Integration'
        }

        It 'Detects performance tests from file names' {
            $test = [pscustomobject]@{
                Name = 'measures startup time'
                File = '/tmp/tests/performance/modern-cli-enhanced-performance.tests.ps1'
                Tags = @()
            }

            Get-TestCategory -Test $test | Should -Be 'Performance'
        }

        It 'Detects integration tests from test names' {
            $test = [pscustomobject]@{
                Name = 'Integration scenario for git helpers'
                File = '/tmp/custom.tests.ps1'
                Tags = @()
            }

            Get-TestCategory -Test $test | Should -Be 'Integration'
        }

        It 'Defaults to Unit when no stronger signal exists' {
            $test = [pscustomobject]@{
                Name = 'returns expected value'
                File = '/tmp/library-common.tests.ps1'
                Tags = @()
            }

            Get-TestCategory -Test $test | Should -Be 'Unit'
        }
    }
}
