# ===============================================
# profile-lang-python-pipx.tests.ps1
# Unit tests for pipx-related functions
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

Describe 'lang-python.ps1 - Install-PythonApp' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('pipx', [ref]$null)
        }

        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('pipx', [ref]$null)
        }
    }

    Context 'Tool not available' {
        It 'Returns null when pipx is not available' {
            Mock-CommandAvailabilityPester -CommandName 'pipx' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'pipx' } -MockWith { return $null }

            $result = Install-PythonApp -Packages @('black') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls pipx install with package names' {
            Setup-AvailableCommandMock -CommandName 'pipx'

            $script:capturedArgs = $null
            Mock -CommandName 'pipx' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Installed black' 
            }

            $result = Install-PythonApp -Packages @('black')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'install'
            $script:capturedArgs | Should -Contain 'black'
        }

        It 'Calls pipx install with additional arguments' {
            Setup-AvailableCommandMock -CommandName 'pipx'

            $script:capturedArgs = $null
            Mock -CommandName 'pipx' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Installed pytest' 
            }

            $result = Install-PythonApp -Packages @('pytest') -Arguments @('--include-deps')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'install'
            $script:capturedArgs | Should -Contain '--include-deps'
            $script:capturedArgs | Should -Contain 'pytest'
        }
    }

    Context 'Error handling' {
        It 'Handles pipx execution errors' {
            Setup-AvailableCommandMock -CommandName 'pipx'

            Mock -CommandName 'pipx' -MockWith {
                throw [System.Management.Automation.CommandNotFoundException]::new('pipx: command failed')
            }
            Mock Write-Error { }

            $result = Install-PythonApp -Packages @('invalid-package') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

Describe 'lang-python.ps1 - Invoke-Pipx' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('pipx', [ref]$null)
        }

        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('pipx', [ref]$null)
        }
    }

    Context 'Tool not available' {
        It 'Returns null when pipx is not available' {
            Mock-CommandAvailabilityPester -CommandName 'pipx' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'pipx' } -MockWith { return $null }

            $result = Invoke-Pipx -Package 'black' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls pipx run with package and arguments' {
            Setup-AvailableCommandMock -CommandName 'pipx'

            $script:capturedArgs = $null
            Mock -CommandName 'pipx' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Formatting complete' 
            }

            $result = Invoke-Pipx -Package 'black' -Arguments @('--check', '.')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'run'
            $script:capturedArgs | Should -Contain 'black'
            $script:capturedArgs | Should -Contain '--check'
        }
    }

    Context 'Error handling' {
        It 'Handles pipx execution errors' {
            Setup-AvailableCommandMock -CommandName 'pipx'

            Mock -CommandName 'pipx' -MockWith {
                throw [System.Management.Automation.CommandNotFoundException]::new('pipx: command failed')
            }
            Mock Write-Error { }

            $result = Invoke-Pipx -Package 'invalid-package' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
            Should -Invoke Write-Error -Times 1
        }
    }
}

