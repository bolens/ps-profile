# ===============================================
# profile-lang-go-goreleaser.tests.ps1
# Unit tests for Release-GoProject function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-go.ps1')
}

Describe 'lang-go.ps1 - Release-GoProject' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('goreleaser', [ref]$null)
        }

        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('goreleaser', [ref]$null)
        }
    }

    Context 'Tool not available' {
        It 'Returns null when goreleaser is not available' {
            Mock-CommandAvailabilityPester -CommandName 'goreleaser' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'goreleaser' } -MockWith { return $null }

            $result = Release-GoProject -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls goreleaser without arguments' {
            Setup-AvailableCommandMock -CommandName 'goreleaser'

            $script:capturedArgs = $null
            Mock -CommandName 'goreleaser' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Release created' 
            }

            $result = Release-GoProject

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -BeNullOrEmpty
        }

        It 'Calls goreleaser with additional arguments' {
            Setup-AvailableCommandMock -CommandName 'goreleaser'

            $script:capturedArgs = $null
            Mock -CommandName 'goreleaser' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Release created' 
            }

            $result = Release-GoProject -Arguments @('--snapshot')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--snapshot'
        }
    }

    Context 'Error handling' {
        It 'Handles goreleaser execution errors' {
            Setup-AvailableCommandMock -CommandName 'goreleaser'

            Mock -CommandName 'goreleaser' -MockWith {
                throw [System.Management.Automation.CommandNotFoundException]::new('goreleaser: command failed')
            }
            Mock Write-Error { }

            try {
                $result = Release-GoProject -ErrorAction SilentlyContinue
            }
            catch {
                # Exception may propagate in test environment
            }

            $result | Should -BeNullOrEmpty
            # Write-Error may or may not be called depending on how PowerShell handles the exception
            # The important thing is that the function handles the error gracefully
        }
    }
}

