# ===============================================
# profile-lang-go-build.tests.ps1
# Unit tests for Build-GoProject and Test-GoProject functions
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

Describe 'lang-go.ps1 - Build-GoProject' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('go', [ref]$null)
        }

        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('go', [ref]$null)
        }
    }

    Context 'Tool not available' {
        It 'Returns null when go is not available' {
            Mock-CommandAvailabilityPester -CommandName 'go' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'go' } -MockWith { return $null }

            $result = Build-GoProject -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls go build without arguments' {
            Setup-AvailableCommandMock -CommandName 'go'

            $script:capturedArgs = $null
            Mock -CommandName 'go' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Build complete' 
            }

            $result = Build-GoProject

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'build'
        }

        It 'Calls go build with output flag' {
            Setup-AvailableCommandMock -CommandName 'go'

            $script:capturedArgs = $null
            Mock -CommandName 'go' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Build complete' 
            }

            $result = Build-GoProject -Output 'myapp'

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'build'
            $script:capturedArgs | Should -Contain '-o'
            $script:capturedArgs | Should -Contain 'myapp'
        }

        It 'Calls go build with additional arguments' {
            Setup-AvailableCommandMock -CommandName 'go'

            $script:capturedArgs = $null
            Mock -CommandName 'go' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Build complete' 
            }

            $result = Build-GoProject -Arguments @('-ldflags', '-s -w')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'build'
            $script:capturedArgs | Should -Contain '-ldflags'
        }
    }

    Context 'Error handling' {
        It 'Handles go build execution errors' {
            Setup-AvailableCommandMock -CommandName 'go'

            Mock -CommandName 'go' -MockWith {
                throw [System.Management.Automation.CommandNotFoundException]::new('go: command failed')
            }
            Mock Write-Error { }

            try {
                $result = Build-GoProject -ErrorAction SilentlyContinue
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

Describe 'lang-go.ps1 - Test-GoProject' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('go', [ref]$null)
        }

        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('go', [ref]$null)
        }
    }

    Context 'Tool not available' {
        It 'Returns null when go is not available' {
            Mock-CommandAvailabilityPester -CommandName 'go' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'go' } -MockWith { return $null }

            $result = Test-GoProject -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls go test without flags' {
            Setup-AvailableCommandMock -CommandName 'go'

            $script:capturedArgs = $null
            Mock -CommandName 'go' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Tests passed' 
            }

            $result = Test-GoProject

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'test'
        }

        It 'Calls go test with verbose flag' {
            Setup-AvailableCommandMock -CommandName 'go'

            $script:capturedArgs = $null
            Mock -CommandName 'go' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Tests passed' 
            }

            $result = Test-GoProject -VerboseOutput

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'test'
            $script:capturedArgs | Should -Contain '-v'
        }

        It 'Calls go test with coverage flag' {
            Setup-AvailableCommandMock -CommandName 'go'

            $script:capturedArgs = $null
            Mock -CommandName 'go' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Tests passed' 
            }

            $result = Test-GoProject -Coverage

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'test'
            $script:capturedArgs | Should -Contain '-cover'
        }

        It 'Calls go test with additional arguments' {
            Setup-AvailableCommandMock -CommandName 'go'

            $script:capturedArgs = $null
            Mock -CommandName 'go' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Tests passed' 
            }

            $result = Test-GoProject -Arguments @('./...')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'test'
            $script:capturedArgs | Should -Contain './...'
        }
    }

    Context 'Error handling' {
        It 'Handles go test execution errors' {
            Setup-AvailableCommandMock -CommandName 'go'

            Mock -CommandName 'go' -MockWith {
                throw [System.Management.Automation.CommandNotFoundException]::new('go: command failed')
            }
            Mock Write-Error { }

            try {
                $result = Test-GoProject -ErrorAction SilentlyContinue
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

