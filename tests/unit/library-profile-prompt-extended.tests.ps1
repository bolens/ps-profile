<#
tests/unit/library-profile-prompt-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ProfilePrompt initialization edge cases.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Join-Path $PSScriptRoot '../../scripts/lib'
    Import-Module (Join-Path $libPath 'profile/ProfilePrompt.psm1') -DisableNameChecking -Force -Global
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    Remove-Item Function:\Initialize-Starship -ErrorAction SilentlyContinue
    Remove-Item Function:\global:Initialize-Starship -ErrorAction SilentlyContinue
    Remove-Item Function:\Update-PerformanceInsightsPrompt -ErrorAction SilentlyContinue
    Remove-Item Function:\global:Update-PerformanceInsightsPrompt -ErrorAction SilentlyContinue
    Remove-Item Function:\prompt -ErrorAction SilentlyContinue
    Remove-Item Function:\global:prompt -ErrorAction SilentlyContinue
}

Describe 'ProfilePrompt extended scenarios' {
    BeforeEach {
        Clear-TestStartProcessCapture
        Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
        Remove-Item Function:\Initialize-Starship -ErrorAction SilentlyContinue
        Remove-Item Function:\global:Initialize-Starship -ErrorAction SilentlyContinue
        Remove-Item Function:\Update-PerformanceInsightsPrompt -ErrorAction SilentlyContinue
        Remove-Item Function:\global:Update-PerformanceInsightsPrompt -ErrorAction SilentlyContinue
        Remove-Item Function:\prompt -ErrorAction SilentlyContinue
        Remove-Item Function:\global:prompt -ErrorAction SilentlyContinue
    }

    AfterEach {
        Get-TestStartProcessCapture | Should -BeNullOrEmpty
    }

    Context 'Initialize-ProfilePrompt' {
        It 'Updates performance insights when the helper is registered' {
            $script:PerformanceInsightsUpdated = $false

            function global:Initialize-Starship {
                function global:prompt {
                    return 'PS> '
                }
            }

            function global:Update-PerformanceInsightsPrompt {
                $script:PerformanceInsightsUpdated = $true
            }

            { Initialize-ProfilePrompt } | Should -Not -Throw
            $script:PerformanceInsightsUpdated | Should -Be $true
        }

        It 'Continues when Update-PerformanceInsightsPrompt throws' {
            function global:Initialize-Starship {
                function global:prompt {
                    return 'PS> '
                }
            }

            function global:Update-PerformanceInsightsPrompt {
                throw 'perf-wrapper-failed'
            }

            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Does not require a prompt function when Initialize-Starship succeeds without one' {
            function global:Initialize-Starship {
                return
            }

            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Uses Test-CachedCommand for starship availability when registered' {
            $script:CachedCommandChecked = $false

            function global:Test-CachedCommand {
                param([string]$Name)
                if ($Name -eq 'starship') {
                    $script:CachedCommandChecked = $true
                }
                return $false
            }

            { Initialize-ProfilePrompt } | Should -Not -Throw
            $script:CachedCommandChecked | Should -Be $true
        }
    }
}
