# ===============================================
# profile-lang-python-venv.tests.ps1
# Unit tests for New-PythonVirtualEnv function
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

Describe 'lang-python.ps1 - New-PythonVirtualEnv' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('uv', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('python3', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('python', [ref]$null)
        }

        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('uv', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('python3', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('python', [ref]$null)
        }
    }

    Context 'Tool not available' {
        It 'Returns null when neither uv nor python is available' {
            Mock-CommandAvailabilityPester -CommandName 'uv' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'python3' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'python' -Available $false

            $result = New-PythonVirtualEnv -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Prefers uv when available' {
            Setup-AvailableCommandMock -CommandName 'uv'

            $script:capturedArgs = $null
            Mock -CommandName 'uv' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Virtual environment created' 
            }

            $result = New-PythonVirtualEnv

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'venv'
            $script:capturedArgs | Should -Contain '.venv'
        }

        It 'Falls back to python -m venv when uv is not available' {
            Mock-CommandAvailabilityPester -CommandName 'uv' -Available $false
            Setup-AvailableCommandMock -CommandName 'python3'

            $script:capturedArgs = $null
            Mock -CommandName 'python3' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Virtual environment created' 
            }

            $result = New-PythonVirtualEnv

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '-m'
            $script:capturedArgs | Should -Contain 'venv'
        }

        It 'Uses custom path when specified' {
            Setup-AvailableCommandMock -CommandName 'uv'

            $script:capturedArgs = $null
            Mock -CommandName 'uv' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Virtual environment created' 
            }

            $result = New-PythonVirtualEnv -Path 'venv'

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'venv'
        }

        It 'Uses Python version when specified (uv only)' {
            Setup-AvailableCommandMock -CommandName 'uv'

            $script:capturedArgs = $null
            Mock -CommandName 'uv' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Virtual environment created' 
            }

            $result = New-PythonVirtualEnv -PythonVersion '3.11'

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--python'
            $script:capturedArgs | Should -Contain '3.11'
        }
    }

    Context 'Error handling' {
        It 'Falls back to python when uv fails' {
            Setup-AvailableCommandMock -CommandName 'uv'
            Setup-AvailableCommandMock -CommandName 'python3'

            Mock -CommandName 'uv' -MockWith {
                throw [System.Management.Automation.CommandNotFoundException]::new('uv: command failed')
            }

            $script:capturedArgs = $null
            Mock -CommandName 'python3' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Virtual environment created' 
            }

            $result = New-PythonVirtualEnv -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '-m'
        }
    }
}

