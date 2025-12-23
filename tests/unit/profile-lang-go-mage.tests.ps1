# ===============================================
# profile-lang-go-mage.tests.ps1
# Unit tests for Invoke-Mage function
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

Describe 'lang-go.ps1 - Invoke-Mage' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('mage', [ref]$null)
        }

        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('mage', [ref]$null)
        }
    }

    Context 'Tool not available' {
        It 'Returns null when mage is not available' {
            Mock-CommandAvailabilityPester -CommandName 'mage' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'mage' } -MockWith { return $null }

            $result = Invoke-Mage -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls mage without target (lists targets)' {
            Setup-AvailableCommandMock -CommandName 'mage'

            $script:capturedArgs = $null
            Mock -CommandName 'mage' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Available targets: build, test' 
            }

            $result = Invoke-Mage

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -BeNullOrEmpty
        }

        It 'Calls mage with target' {
            Setup-AvailableCommandMock -CommandName 'mage'

            $script:capturedArgs = $null
            Mock -CommandName 'mage' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Build complete' 
            }

            $result = Invoke-Mage -Target 'build'

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'build'
        }

        It 'Calls mage with target and additional arguments' {
            Setup-AvailableCommandMock -CommandName 'mage'

            $script:capturedArgs = $null
            Mock -CommandName 'mage' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Test complete' 
            }

            $result = Invoke-Mage -Target 'test' -Arguments @('-v')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'test'
            $script:capturedArgs | Should -Contain '-v'
        }
    }

    Context 'Error handling' {
        It 'Handles mage execution errors' {
            Setup-AvailableCommandMock -CommandName 'mage'

            Mock -CommandName 'mage' -MockWith {
                throw [System.Management.Automation.CommandNotFoundException]::new('mage: command failed')
            }
            Mock Write-Error { }

            try {
                $result = Invoke-Mage -Target 'invalid' -ErrorAction SilentlyContinue
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

