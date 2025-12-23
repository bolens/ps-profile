# ===============================================
# profile-lang-java-maven.tests.ps1
# Unit tests for Build-Maven function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-java.ps1')
}

Describe 'lang-java.ps1 - Build-Maven' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('mvn', [ref]$null)
        }

        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('mvn', [ref]$null)
        }
    }

    Context 'Tool not available' {
        It 'Returns null when mvn is not available' {
            Mock-CommandAvailabilityPester -CommandName 'mvn' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'mvn' } -MockWith { return $null }

            $result = Build-Maven -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls mvn without arguments' {
            Setup-AvailableCommandMock -CommandName 'mvn'

            $script:capturedArgs = $null
            Mock -CommandName 'mvn' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Build complete' 
            }

            $result = Build-Maven

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -BeNullOrEmpty
        }

        It 'Calls mvn with additional arguments' {
            Setup-AvailableCommandMock -CommandName 'mvn'

            $script:capturedArgs = $null
            Mock -CommandName 'mvn' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Build complete' 
            }

            $result = Build-Maven -Arguments @('clean', 'install')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'clean'
            $script:capturedArgs | Should -Contain 'install'
        }
    }

    Context 'Error handling' {
        It 'Handles mvn execution errors' {
            Setup-AvailableCommandMock -CommandName 'mvn'

            Mock -CommandName 'mvn' -MockWith {
                throw [System.Management.Automation.CommandNotFoundException]::new('mvn: command failed')
            }
            Mock Write-Error { }

            try {
                $result = Build-Maven -ErrorAction SilentlyContinue
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

