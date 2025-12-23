

Describe 'Profile Updates Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        # Use test-data directory instead of system temp
        $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
        $testDataRoot = Join-Path $repoRoot 'tests' 'test-data'
        if ($testDataRoot -and -not [string]::IsNullOrWhiteSpace($testDataRoot) -and -not (Test-Path -LiteralPath $testDataRoot)) {
            New-Item -ItemType Directory -Path $testDataRoot -Force | Out-Null
        }
        $script:TestProfileDir = Join-Path $testDataRoot 'PesterTestProfileUpdates'
        # Create test directory if it doesn't exist
        if ($script:TestProfileDir -and -not [string]::IsNullOrWhiteSpace($script:TestProfileDir) -and -not (Test-Path -LiteralPath $script:TestProfileDir)) {
            New-Item -ItemType Directory -Path $script:TestProfileDir -Force | Out-Null
        }
        $script:LastCheckFile = Join-Path $script:TestProfileDir '.profile-last-update-check'
    }
    
    AfterAll {
        # Clean up test directory
        if ($script:TestProfileDir -and -not [string]::IsNullOrWhiteSpace($script:TestProfileDir) -and (Test-Path -LiteralPath $script:TestProfileDir)) {
            Remove-Item -Path $script:TestProfileDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

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

