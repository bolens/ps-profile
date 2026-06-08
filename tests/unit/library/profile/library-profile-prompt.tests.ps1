<#
tests/unit/library-profile-prompt.tests.ps1

.SYNOPSIS
    Unit tests for ProfilePrompt module.
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
    $libPath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib'
    Import-Module (Join-Path $libPath 'profile/ProfilePrompt.psm1') -DisableNameChecking -Force -Global
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    Remove-Item Function:\Initialize-Starship -ErrorAction SilentlyContinue
    Remove-Item Function:\global:Initialize-Starship -ErrorAction SilentlyContinue
}

Describe 'ProfilePrompt Module' {
    Context 'Initialize-ProfilePrompt' {
        BeforeEach {
            Clear-TestStartProcessCapture
            Remove-Item Function:\Initialize-Starship -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Initialize-Starship -ErrorAction SilentlyContinue
        }

        AfterEach {
            Get-TestStartProcessCapture | Should -BeNullOrEmpty
            Remove-Item Function:\Initialize-Starship -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Initialize-Starship -ErrorAction SilentlyContinue
        }

        It 'Does not throw when Starship helpers are unavailable' {
            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Calls Initialize-Starship when the helper is registered' {
            $script:StarshipInitialized = $false
            function global:Initialize-Starship {
                $script:StarshipInitialized = $true
            }
            function global:prompt {
                return 'PS> '
            }

            Initialize-ProfilePrompt

            $script:StarshipInitialized | Should -Be $true
        }

        It 'Continues when Initialize-Starship throws' {
            function global:Initialize-Starship {
                throw 'starship-init-failed'
            }

            { Initialize-ProfilePrompt } | Should -Not -Throw
        }
    }
}
