<#
tests/integration/profile/updates.tests.ps1

.SYNOPSIS
    Profile updates integration tests.
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

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:TestProfileDir = New-TestTempDirectory -Prefix 'ProfileUpdates'
    $script:LastCheckFile = Join-Path $script:TestProfileDir '.profile-last-update-check'
}

Describe 'Profile Updates Integration Tests' {
    Context 'Test-ProfileUpdates function' {
        BeforeAll {
            # Set test mode to allow the fragment to load even without Host.UI
            $env:PS_PROFILE_TEST_MODE = '1'

            # Load bootstrap first
            . (Join-Path $script:ProfileDir 'bootstrap.ps1')

            # Load the profile-updates fragment
            . (Join-Path $script:ProfileDir 'profile-updates.ps1')
        }

        AfterAll {
            # Clean up test environment variable
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }

        BeforeEach {
            # Clean up any existing test files
            if ($script:LastCheckFile -and -not [string]::IsNullOrWhiteSpace($script:LastCheckFile) -and (Test-Path -LiteralPath $script:LastCheckFile)) {
                Remove-Item $script:LastCheckFile -Force
            }
            # Clear any existing global variables
            if (Get-Variable -Name 'ProfileUpdatesLoaded' -Scope Global -ErrorAction SilentlyContinue) {
                Remove-Variable -Name 'ProfileUpdatesLoaded' -Scope Global -Force
            }
        }

        It 'Test-ProfileUpdates function exists' {
            Get-Command Test-ProfileUpdates -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Test-ProfileUpdates can be called without error' {
            # Should not throw when called
            { Test-ProfileUpdates } | Should -Not -Throw
        }

        It 'Test-ProfileUpdates can be called with Force parameter' {
            # Should not throw when called with Force
            { Test-ProfileUpdates -Force } | Should -Not -Throw
        }

        It 'Test-ProfileUpdates can be called with MaxChanges parameter' {
            # Should not throw when called with MaxChanges
            { Test-ProfileUpdates -MaxChanges 5 } | Should -Not -Throw
        }

        It 'Test-ProfileUpdates can be called with both parameters' {
            # Should not throw when called with both parameters
            { Test-ProfileUpdates -Force -MaxChanges 3 } | Should -Not -Throw
        }
    }

    Context 'ProfileUpdatesLoaded global variable' {
        It 'Sets ProfileUpdatesLoaded global variable' {
            # Clear any existing variable
            if (Get-Variable -Name 'ProfileUpdatesLoaded' -Scope Global -ErrorAction SilentlyContinue) {
                Remove-Variable -Name 'ProfileUpdatesLoaded' -Scope Global -Force
            }

            # Set test mode to allow the fragment to load
            $env:PS_PROFILE_TEST_MODE = '1'

            try {
                # Load the module
                . (Join-Path $script:ProfileDir 'profile-updates.ps1')

                # Variable should be set
                Get-Variable -Name 'ProfileUpdatesLoaded' -Scope Global -ErrorAction SilentlyContinue | Should -Not -Be $null
                $global:ProfileUpdatesLoaded | Should -Be $true
            }
            finally {
                # Clean up test environment variable
                Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
            }
        }
    }
}

