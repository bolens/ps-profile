# ===============================================
# profile-lang-java-kotlin.tests.ps1
# Unit tests for Compile-Kotlin function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-java-compilers.ps1')
}

Describe 'lang-java.ps1 - Compile-Kotlin' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'kotlinc' -Available $false
        Remove-Item -Path 'Function:\kotlinc' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:kotlinc' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when kotlinc is not available' {
            $result = Compile-Kotlin -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls kotlinc with arguments' {
            Setup-CapturingCommandMock -CommandName 'kotlinc' -Output 'Compilation complete'

            $result = Compile-Kotlin 'Main.kt' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'Main.kt'
            $result | Should -Be 'Compilation complete'
        }
    }

    Context 'Error handling' {
        It 'Handles kotlinc execution errors' {
            Set-TestCommandThrowingMock -CommandName 'kotlinc' -Message 'kotlinc: command failed'

            { Compile-Kotlin 'Main.kt' -ErrorAction Stop } | Should -Throw
        }
    }
}
