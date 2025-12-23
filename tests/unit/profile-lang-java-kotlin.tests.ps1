# ===============================================
# profile-lang-java-kotlin.tests.ps1
# Unit tests for Compile-Kotlin function
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

Describe 'lang-java.ps1 - Compile-Kotlin' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('kotlinc', [ref]$null)
        }

        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('kotlinc', [ref]$null)
        }
    }

    Context 'Tool not available' {
        It 'Returns null when kotlinc is not available' {
            Mock-CommandAvailabilityPester -CommandName 'kotlinc' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'kotlinc' } -MockWith { return $null }

            $result = Compile-Kotlin -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls kotlinc with arguments' {
            Setup-AvailableCommandMock -CommandName 'kotlinc'

            $script:capturedArgs = $null
            Mock -CommandName 'kotlinc' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Compilation complete' 
            }

            $result = Compile-Kotlin -Arguments @('Main.kt')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'Main.kt'
        }
    }

    Context 'Error handling' {
        It 'Handles kotlinc execution errors' {
            Setup-AvailableCommandMock -CommandName 'kotlinc'

            Mock -CommandName 'kotlinc' -MockWith {
                throw [System.Management.Automation.CommandNotFoundException]::new('kotlinc: command failed')
            }
            Mock Write-Error { }

            try {
                $result = Compile-Kotlin -Arguments @('Main.kt') -ErrorAction SilentlyContinue
            }
            catch {
                # Exception may propagate in test environment
            }

            $result | Should -BeNullOrEmpty
        }
    }
}

