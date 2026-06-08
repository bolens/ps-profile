# ===============================================
# profile-lang-java-scala.tests.ps1
# Unit tests for Compile-Scala function
# ===============================================

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-java-compilers.ps1')
}

Describe 'lang-java.ps1 - Compile-Scala' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'scalac' -Available $false
        Remove-Item -Path 'Function:\scalac' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:scalac' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when scalac is not available' {
            $result = Compile-Scala -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls scalac with arguments' {
            Setup-CapturingCommandMock -CommandName 'scalac' -Output 'Compilation complete'

            $result = Compile-Scala 'Main.scala' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'Main.scala'
            $result | Should -Be 'Compilation complete'
        }
    }

    Context 'Error handling' {
        It 'Handles scalac execution errors' {
            Set-TestCommandThrowingMock -CommandName 'scalac' -Message 'scalac: command failed'

            { Compile-Scala 'Main.scala' -ErrorAction Stop } | Should -Throw
        }
    }
}
