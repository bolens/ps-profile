# ===============================================
# profile-lang-python-script.tests.ps1
# Unit tests for Invoke-PythonScript function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-python.ps1')
}

Describe 'lang-python.ps1 - Invoke-PythonScript' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('python3', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('python', [ref]$null)
        }

        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('python3', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('python', [ref]$null)
        }
    }

    Context 'Tool not available' {
        It 'Returns null when python is not available' {
            Mock-CommandAvailabilityPester -CommandName 'python3' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'python' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'python3' -or $Name -eq 'python' } -MockWith { return $null }

            $result = Invoke-PythonScript -Script 'script.py' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls python3 when available' {
            Setup-AvailableCommandMock -CommandName 'python3'

            $script:capturedArgs = $null
            Mock -CommandName 'python3' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Script output' 
            }

            $result = Invoke-PythonScript -Script 'script.py'

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'script.py'
        }

        It 'Falls back to python when python3 is not available' {
            Mock-CommandAvailabilityPester -CommandName 'python3' -Available $false
            Setup-AvailableCommandMock -CommandName 'python'

            $script:capturedArgs = $null
            Mock -CommandName 'python' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Script output' 
            }

            $result = Invoke-PythonScript -Script 'script.py'

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'script.py'
        }

        It 'Calls python with one-liner arguments' {
            Setup-AvailableCommandMock -CommandName 'python3'

            $script:capturedArgs = $null
            Mock -CommandName 'python3' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Hello' 
            }

            $result = Invoke-PythonScript -Arguments @('-c', 'print("Hello")')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '-c'
            $script:capturedArgs | Should -Contain 'print("Hello")'
        }
    }

    Context 'Error handling' {
        It 'Handles python execution errors' {
            Setup-AvailableCommandMock -CommandName 'python3'

            Mock -CommandName 'python3' -MockWith {
                throw [System.Management.Automation.CommandNotFoundException]::new('python3: command failed')
            }
            Mock Write-Error { }

            $result = Invoke-PythonScript -Script 'invalid.py' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

