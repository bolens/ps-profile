<#
tests/unit/test-runner-output-interceptor-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for OutputInterceptor behavior.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'OutputPathUtils.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'OutputSanitizer.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'OutputInterceptor.psm1') -Force -Global

    $script:TestRepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Initialize-OutputUtils -RepoRoot $script:TestRepoRoot
}

Describe 'OutputInterceptor extended behavior' {
    AfterEach {
        Stop-TestOutputInterceptor
    }
    Context 'Start-TestOutputInterceptor lifecycle' {
        It 'Ignores repeated Start calls without throwing' {
            { Start-TestOutputInterceptor } | Should -Not -Throw
            { Start-TestOutputInterceptor } | Should -Not -Throw
        }

        It 'Ignores Stop when interceptor was never started' {
            Stop-TestOutputInterceptor
            { Stop-TestOutputInterceptor } | Should -Not -Throw
        }

        It 'Restores Write-Host after Stop so subsequent calls succeed' {
            Start-TestOutputInterceptor
            Stop-TestOutputInterceptor

            { Write-Host 'restored write-host' } | Should -Not -Throw
        }
    }

    Context 'Module override state' {
        It 'Activates override flags after Start-TestOutputInterceptor' {
            InModuleScope OutputInterceptor {
                Start-TestOutputInterceptor
                try {
                    $script:WriteHostOverrideActive | Should -Be $true
                    $script:WriteWarningOverrideActive | Should -Be $true
                }
                finally {
                    Stop-TestOutputInterceptor
                }
            }
        }

        It 'Clears override flags and warning tracking after Stop-TestOutputInterceptor' {
            InModuleScope OutputInterceptor {
                Start-TestOutputInterceptor
                Stop-TestOutputInterceptor

                $script:WriteHostOverrideActive | Should -Be $false
                $script:WriteWarningOverrideActive | Should -Be $false
                $script:EmittedWarningMessages | Should -BeNullOrEmpty
            }
        }
    }
}
