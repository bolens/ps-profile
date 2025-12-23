# ===============================================
# profile-lang-java-ant.tests.ps1
# Unit tests for Build-Ant function
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

Describe 'lang-java.ps1 - Build-Ant' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('ant', [ref]$null)
        }

        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('ant', [ref]$null)
        }
    }

    Context 'Tool not available' {
        It 'Returns null when ant is not available' {
            Mock-CommandAvailabilityPester -CommandName 'ant' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'ant' } -MockWith { return $null }

            $result = Build-Ant -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls ant without arguments' {
            Setup-AvailableCommandMock -CommandName 'ant'

            $script:capturedArgs = $null
            Mock -CommandName 'ant' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Build complete' 
            }

            $result = Build-Ant

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -BeNullOrEmpty
        }

        It 'Calls ant with additional arguments' {
            Setup-AvailableCommandMock -CommandName 'ant'

            $script:capturedArgs = $null
            Mock -CommandName 'ant' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Build complete' 
            }

            $result = Build-Ant -Arguments @('clean', 'build')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'clean'
            $script:capturedArgs | Should -Contain 'build'
        }
    }

    Context 'Error handling' {
        It 'Handles ant execution errors' {
            Setup-AvailableCommandMock -CommandName 'ant'

            Mock -CommandName 'ant' -MockWith {
                throw [System.Management.Automation.CommandNotFoundException]::new('ant: command failed')
            }
            Mock Write-Error { }

            try {
                $result = Build-Ant -ErrorAction SilentlyContinue
            }
            catch {
                # Exception may propagate in test environment
            }

            $result | Should -BeNullOrEmpty
        }
    }
}

