# ===============================================
# profile-lang-java-ant.tests.ps1
# Unit tests for Build-Ant function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-java-build.ps1')
}

Describe 'lang-java.ps1 - Build-Ant' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'ant' -Available $false
        Remove-Item -Path 'Function:\ant' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:ant' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when ant is not available' {
            $result = Build-Ant -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls ant without arguments' {
            Setup-CapturingCommandMock -CommandName 'ant' -Output 'Build complete'

            $result = Build-Ant -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            @((Get-TestCommandInvocationArgsFlat | Where-Object { $null -ne $_ -and $_ -ne '' })).Count | Should -Be 0
            $result | Should -Be 'Build complete'
        }

        It 'Calls ant with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'ant' -Output 'Build complete'

            Build-Ant 'clean', 'build' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'clean'
            $args | Should -Contain 'build'
        }
    }

    Context 'Error handling' {
        It 'Handles ant execution errors' {
            Set-TestCommandThrowingMock -CommandName 'ant' -Message 'ant: command failed'

            { Build-Ant -ErrorAction Stop } | Should -Throw
        }
    }
}
