. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Enhanced History Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    }

    Context 'Enhanced history functions' {
        BeforeAll {
            # Set test mode to enable test-friendly behavior
            $env:PS_PROFILE_TEST_MODE = '1'

            # Load the enhanced history fragment directly to ensure functions are available
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $enhancedHistoryFragment = Join-Path $script:ProfileDir '74-enhanced-history.ps1'
            # Clear the guard variable to allow loading
            Remove-Variable -Name 'EnhancedHistoryLoaded' -Scope Global -ErrorAction SilentlyContinue
            . $enhancedHistoryFragment

            # Verify the fragment loaded by checking if a known function exists
            $fragmentLoaded = Get-Command Find-HistoryFuzzy -CommandType Function -ErrorAction SilentlyContinue
            Write-Host "Fragment loaded successfully: $($null -ne $fragmentLoaded)" -ForegroundColor Yellow

            # Mock Read-Host to avoid interactive prompts in tests
            Mock Read-Host { return "n" }
        }

        It 'Find-HistoryFuzzy function is available' {
            Get-Command Find-HistoryFuzzy -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Find-HistoryFuzzy executes without error' {
            { Find-HistoryFuzzy -Pattern "test" } | Should -Not -Throw
        }

        It 'Find-HistoryQuick function is available' {
            Get-Command Find-HistoryQuick -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Find-HistoryQuick executes without error' {
            { Find-HistoryQuick -Pattern "test" } | Should -Not -Throw
        }

        It 'Show-HistoryStats function is available' {
            Get-Command Show-HistoryStats -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-HistoryStats executes without error' {
            { Show-HistoryStats } | Should -Not -Throw
        }

        It 'Remove-HistoryDuplicates function is available' {
            Get-Command Remove-HistoryDuplicates -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Remove-HistoryDuplicates executes without error' {
            { Remove-HistoryDuplicates } | Should -Not -Throw
        }

        It 'Remove-OldHistory function is available' {
            Get-Command Remove-OldHistory -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Remove-OldHistory executes without error' {
            { Remove-OldHistory -Days 30 } | Should -Not -Throw
        }

        It 'Invoke-LastCommand function is available' {
            Get-Command Invoke-LastCommand -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Invoke-LastCommand executes without error' {
            { Invoke-LastCommand } | Should -Not -Throw
        }

        It 'Show-RecentCommands function is available' {
            Get-Command Show-RecentCommands -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-RecentCommands executes without error' {
            { Show-RecentCommands } | Should -Not -Throw
        }

        It 'r function is available' {
            Get-Command r -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'r executes without error' {
            # Test the r function with a pattern to avoid interactive confirmation
            # Call the function directly since the alias may not be available in test context
            { & (Get-Command r -CommandType Function) -CommandInput "test" } | Should -Not -Throw
        }

        It 'Search-HistoryInteractive function is available' {
            Get-Command Search-HistoryInteractive -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Search-HistoryInteractive executes without error' {
            # This function detects test mode and returns early to avoid interactive input
            { Search-HistoryInteractive } | Should -Not -Throw
        }
    }
}
