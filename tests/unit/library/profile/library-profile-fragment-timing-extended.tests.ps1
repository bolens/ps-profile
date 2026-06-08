<#
tests/unit/library-profile-fragment-timing-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ProfileFragmentTiming debug levels and tracking.
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
    Remove-Module ProfileFragmentTiming -ErrorAction SilentlyContinue -Force
    Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    Remove-Variable -Name PSProfileFragmentTimes -Scope Global -ErrorAction SilentlyContinue
}

Describe 'ProfileFragmentTiming extended scenarios' {
    BeforeEach {
        Remove-Variable -Name PSProfileFragmentTimes -Scope Global -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    }

    AfterEach {
        Remove-Variable -Name PSProfileFragmentTimes -Scope Global -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    }

    Context 'Measure-FragmentLoadTime debug levels' {
        It 'Executes the action without recording timing when debug is disabled' {
            $result = Measure-FragmentLoadTime -FragmentName 'quiet-fragment' -Action { 'done' }

            $result | Should -Be 'done'
            Get-Variable -Name PSProfileFragmentTimes -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Runs the action at debug level 1 without adding timing entries' {
            $env:PS_PROFILE_DEBUG = '1'
            Initialize-FragmentTiming

            $result = Measure-FragmentLoadTime -FragmentName 'basic-debug' -Action { 'loaded' }

            $result | Should -Be 'loaded'
            @($global:PSProfileFragmentTimes).Count | Should -Be 0
        }

        It 'Treats non-numeric PS_PROFILE_DEBUG values as basic debug without timing' {
            $env:PS_PROFILE_DEBUG = 'verbose'

            $result = Measure-FragmentLoadTime -FragmentName 'non-numeric-debug' -Action { 42 }

            $result | Should -Be 42
            Get-Variable -Name PSProfileFragmentTimes -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Records timestamp metadata at debug level 3' {
            $env:PS_PROFILE_DEBUG = '3'
            Initialize-FragmentTiming

            $null = Measure-FragmentLoadTime -FragmentName 'timestamped-fragment' -Action { Start-Sleep -Milliseconds 5 }

            $global:PSProfileFragmentTimes[0].Timestamp | Should -BeOfType [datetime]
            $global:PSProfileFragmentTimes[0].Fragment | Should -Be 'timestamped-fragment'
        }
    }

    Context 'Timing list accumulation' {
        It 'Appends multiple fragment measurements in order' {
            $env:PS_PROFILE_DEBUG = '2'
            Initialize-FragmentTiming

            $null = Measure-FragmentLoadTime -FragmentName 'first' -Action { 'one' }
            $null = Measure-FragmentLoadTime -FragmentName 'second' -Action { 'two' }

            @($global:PSProfileFragmentTimes).Count | Should -Be 2
            $global:PSProfileFragmentTimes[0].Fragment | Should -Be 'first'
            $global:PSProfileFragmentTimes[1].Fragment | Should -Be 'second'
        }
    }
}
