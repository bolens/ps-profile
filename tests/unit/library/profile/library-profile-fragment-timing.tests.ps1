<#
tests/unit/library-profile-fragment-timing.tests.ps1

.SYNOPSIS
    Unit tests for ProfileFragmentTiming module.
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
    Import-Module (Join-Path $libPath 'profile/ProfileFragmentTiming.psm1') -DisableNameChecking -Force -Global
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    Remove-Variable -Name PSProfileFragmentTimes -Scope Global -ErrorAction SilentlyContinue
}

Describe 'ProfileFragmentTiming Module' {
    Context 'Initialize-FragmentTiming' {
        BeforeEach {
            Remove-Variable -Name PSProfileFragmentTimes -Scope Global -ErrorAction SilentlyContinue
            Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
        }

        AfterEach {
            Remove-Variable -Name PSProfileFragmentTimes -Scope Global -ErrorAction SilentlyContinue
            Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
        }

        It 'Creates timing list when debug mode is enabled' {
            $env:PS_PROFILE_DEBUG = '2'
            Initialize-FragmentTiming

            Measure-FragmentLoadTime -FragmentName 'init-probe' -Action { $null } | Out-Null

            @($global:PSProfileFragmentTimes).Count | Should -Be 1
            $global:PSProfileFragmentTimes[0].Fragment | Should -Be 'init-probe'
        }

        It 'Leaves timing list unset when debug mode is disabled' {
            Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            Initialize-FragmentTiming

            Get-Variable -Name PSProfileFragmentTimes -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
    }

    Context 'Measure-FragmentLoadTime' {
        AfterEach {
            Remove-Variable -Name PSProfileFragmentTimes -Scope Global -ErrorAction SilentlyContinue
            Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
        }

        It 'Executes action without tracking when debug is disabled' {
            $result = Measure-FragmentLoadTime -FragmentName 'quiet-fragment' -Action { 'done' }

            $result | Should -Be 'done'
            Get-Variable -Name PSProfileFragmentTimes -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Records timing entries when debug level is 2 or higher' {
            $env:PS_PROFILE_DEBUG = '2'
            Initialize-FragmentTiming

            $result = Measure-FragmentLoadTime -FragmentName 'timed-fragment' -Action {
                Start-Sleep -Milliseconds 20
                'loaded'
            }

            $result | Should -Be 'loaded'

            @($global:PSProfileFragmentTimes).Count | Should -Be 1
            $global:PSProfileFragmentTimes[0].Fragment | Should -Be 'timed-fragment'
            $global:PSProfileFragmentTimes[0].Duration | Should -BeGreaterThan 0
        }
    }
}
