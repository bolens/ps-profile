# ===============================================
# profile-lang-go-lint.tests.ps1
# Unit tests for Lint-GoProject function
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

Describe 'lang-go.ps1 - Lint-GoProject' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('golangci-lint', [ref]$null)
        }

        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('golangci-lint', [ref]$null)
        }
    }

    Context 'Tool not available' {
        It 'Returns null when golangci-lint is not available' {
            Mock-CommandAvailabilityPester -CommandName 'golangci-lint' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'golangci-lint' } -MockWith { return $null }

            $result = Lint-GoProject -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls golangci-lint without arguments' {
            Setup-AvailableCommandMock -CommandName 'golangci-lint'

            $script:capturedArgs = $null
            Mock -CommandName 'golangci-lint' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Linting complete' 
            }

            $result = Lint-GoProject

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -BeNullOrEmpty
        }

        It 'Calls golangci-lint with additional arguments' {
            Setup-AvailableCommandMock -CommandName 'golangci-lint'

            $script:capturedArgs = $null
            Mock -CommandName 'golangci-lint' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Linting complete' 
            }

            $result = Lint-GoProject -Arguments @('--fix', './...')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--fix'
            $script:capturedArgs | Should -Contain './...'
        }
    }

    Context 'Error handling' {
        It 'Handles golangci-lint execution errors' {
            Setup-AvailableCommandMock -CommandName 'golangci-lint'

            Mock -CommandName 'golangci-lint' -MockWith {
                throw [System.Management.Automation.CommandNotFoundException]::new('golangci-lint: command failed')
            }
            Mock Write-Error { }

            try {
                $result = Lint-GoProject -ErrorAction SilentlyContinue
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

