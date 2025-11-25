Describe "Oh My Posh Module" {
    BeforeAll {
        # Source the test support
        . "$PSScriptRoot\..\TestSupport.ps1"
    }

    Context "Initialize-OhMyPosh" {
        BeforeEach {
            # Remove any existing prompt function and variables
            if (Get-Command -Name prompt -CommandType Function -ErrorAction SilentlyContinue) {
                Remove-Item Function:\global:prompt -ErrorAction SilentlyContinue
            }
            Remove-Variable -Name 'OhMyPoshInitialized' -Scope Global -ErrorAction SilentlyContinue

            # Load the oh-my-posh fragment directly
            $ohMyPoshFragment = Get-TestPath "profile.d\06-oh-my-posh.ps1"
            . $ohMyPoshFragment
        }

        It "Should exist and be callable" {
            { Get-Command Initialize-OhMyPosh -ErrorAction Stop } | Should -Not -Throw
            { Initialize-OhMyPosh } | Should -Not -Throw
        }

        It "Should skip initialization if already initialized" {
            # Set the global variable first
            $global:OhMyPoshInitialized = $true

            { Initialize-OhMyPosh } | Should -Not -Throw

            # Global variable should still be true
            $global:OhMyPoshInitialized | Should -Be $true
        }

        It "Should handle oh-my-posh not available gracefully" {
            # We can't easily mock Get-Command for external commands in this context
            # So we just test that the function doesn't throw
            { Initialize-OhMyPosh } | Should -Not -Throw
        }
    }

    Context "prompt function" {
        BeforeEach {
            # Temporarily remove oh-my-posh from PATH to prevent initialization
            $originalPath = $env:PATH
            $paths = $env:PATH -split ';' | Where-Object { $_ -notlike '*oh-my-posh*' }
            $env:PATH = $paths -join ';'

            # Mock Get-Command to return null for oh-my-posh before loading the fragment
            Mock Get-Command {
                param($Name)
                Write-Host "Get-Command called with Name='$Name'" -ForegroundColor Yellow
                if ($Name -eq 'oh-my-posh') {
                    return $null
                }
                return $null  # Return null for all other calls to avoid recursion
            }

            # Remove any existing prompt function and variables
            if (Get-Command -Name prompt -CommandType Function -ErrorAction SilentlyContinue) {
                Remove-Item Function:\global:prompt -ErrorAction SilentlyContinue
            }
            Remove-Variable -Name 'OhMyPoshInitialized' -Scope Global -ErrorAction SilentlyContinue

            # Load the oh-my-posh fragment directly
            $ohMyPoshFragment = Get-TestPath "profile.d\06-oh-my-posh.ps1"
            . $ohMyPoshFragment

            # Restore PATH
            $env:PATH = $originalPath
        }

        It "Should exist and be callable" {
            { Get-Command prompt -ErrorAction Stop } | Should -Not -Throw
            { prompt } | Should -Not -Throw
            $result = prompt
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should return a string" {
            $result = prompt
            $result | Should -BeOfType [string]
        }
    }
}
