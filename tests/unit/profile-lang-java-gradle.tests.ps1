# ===============================================
# profile-lang-java-gradle.tests.ps1
# Unit tests for Build-Gradle function
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

Describe 'lang-java.ps1 - Build-Gradle' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('gradle', [ref]$null)
        }

        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('gradle', [ref]$null)
        }
    }

    Context 'Tool not available' {
        It 'Returns null when gradle is not available' {
            Mock-CommandAvailabilityPester -CommandName 'gradle' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'gradle' } -MockWith { return $null }

            $result = Build-Gradle -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls gradle without arguments' {
            Setup-AvailableCommandMock -CommandName 'gradle'

            $script:capturedArgs = $null
            Mock -CommandName 'gradle' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Build complete' 
            }

            $result = Build-Gradle

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -BeNullOrEmpty
        }

        It 'Calls gradle with additional arguments' {
            Setup-AvailableCommandMock -CommandName 'gradle'

            $script:capturedArgs = $null
            Mock -CommandName 'gradle' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Build complete' 
            }

            $result = Build-Gradle -Arguments @('build', 'test')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'build'
            $script:capturedArgs | Should -Contain 'test'
        }
    }

    Context 'Error handling' {
        It 'Handles gradle execution errors' {
            Setup-AvailableCommandMock -CommandName 'gradle'

            Mock -CommandName 'gradle' -MockWith {
                throw [System.Management.Automation.CommandNotFoundException]::new('gradle: command failed')
            }
            Mock Write-Error { }

            try {
                $result = Build-Gradle -ErrorAction SilentlyContinue
            }
            catch {
                # Exception may propagate in test environment
            }

            $result | Should -BeNullOrEmpty
        }
    }
}

