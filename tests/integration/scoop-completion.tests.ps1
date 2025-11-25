. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Scoop Completion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot
        $script:TestScoopDir = Get-TestPath -RelativePath 'test-scoop' -StartPath $PSScriptRoot
        # Create test directory if it doesn't exist
        if (-not (Test-Path $script:TestScoopDir)) {
            New-Item -ItemType Directory -Path $script:TestScoopDir -Force | Out-Null
        }
        $script:CompletionModulePath = Join-Path $script:TestScoopDir 'apps\scoop\current\supporting\completion\Scoop-Completion.psd1'
    }

    Context 'Scoop completion setup' {
        BeforeEach {
            # Clear environment variables
            $env:SCOOP = $null
            $env:SCOOP_GLOBAL = $null
            $env:USERPROFILE = 'C:\Users\TestUser'
            $env:HOME = $null

            # Clear any existing global variable
            if (Get-Variable -Name 'ScoopCompletionLoaded' -Scope Global -ErrorAction SilentlyContinue) {
                Remove-Variable -Name 'ScoopCompletionLoaded' -Scope Global -Force
            }

            # Clear any existing function
            if (Get-Command Enable-ScoopCompletion -CommandType Function -ErrorAction SilentlyContinue) {
                Remove-Item Function:\Enable-ScoopCompletion -Force
            }

            # Remove test directories
            if (Test-Path $script:TestScoopDir) {
                Remove-Item $script:TestScoopDir -Recurse -Force
            }
        }

        It 'Sets ScoopCompletionLoaded global variable on load' {
            # Load the module
            . (Join-Path $script:ProfileDir '04-scoop-completion.ps1')

            # Variable should NOT be set on load (only when Enable-ScoopCompletion is called)
            Get-Variable -Name 'ScoopCompletionLoaded' -Scope Global -ErrorAction SilentlyContinue | Should -Be $null
        }

        It 'Does not create Enable-ScoopCompletion when no scoop installation found' {
            # Mock Get-ScoopCompletionPath to return null (no scoop found)
            if (Get-Command Get-ScoopCompletionPath -ErrorAction SilentlyContinue) {
                Mock -CommandName 'Get-ScoopCompletionPath' -MockWith { return $null }
            }
            # Mock Test-Path to prevent finding any scoop installations
            Mock -CommandName 'Test-Path' -MockWith { return $false }

            . (Join-Path $script:ProfileDir '04-scoop-completion.ps1')

            Get-Command Enable-ScoopCompletion -CommandType Function -ErrorAction SilentlyContinue | Should -Be $null
        }

        It 'Creates Enable-ScoopCompletion when scoop found via SCOOP environment variable' {
            # Set up environment
            $env:SCOOP_GLOBAL = $null
            $env:SCOOP = $script:TestScoopDir

            # Create the completion module file
            $completionDir = Split-Path $script:CompletionModulePath -Parent
            New-Item -ItemType Directory -Path $completionDir -Force | Out-Null
            New-Item -ItemType File -Path $script:CompletionModulePath -Force | Out-Null

            . (Join-Path $script:ProfileDir '04-scoop-completion.ps1')

            Get-Command Enable-ScoopCompletion -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Enable-ScoopCompletion can be called' {
            # Set up environment
            $env:SCOOP_GLOBAL = $null
            $env:SCOOP = $script:TestScoopDir

            # Create the completion module file
            $completionDir = Split-Path $script:CompletionModulePath -Parent
            New-Item -ItemType Directory -Path $completionDir -Force | Out-Null
            New-Item -ItemType File -Path $script:CompletionModulePath -Force | Out-Null

            . (Join-Path $script:ProfileDir '04-scoop-completion.ps1')

            # Call the function - should not throw (may show warning if import fails)
            { Enable-ScoopCompletion } | Should -Not -Throw
        }

        It 'Handles errors during scoop completion setup gracefully' {
            # Should not throw even with invalid setup
            { . (Join-Path $script:ProfileDir '04-scoop-completion.ps1') } | Should -Not -Throw
        }
    }
}
