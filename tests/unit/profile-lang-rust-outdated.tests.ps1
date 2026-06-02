# ===============================================
# profile-lang-rust-outdated.tests.ps1
# Unit tests for Test-RustOutdated function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-rust-audit.ps1')
}

Describe 'lang-rust.ps1 - Test-RustOutdated' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'cargo-outdated' -Available $false
        Remove-Item -Path 'Function:\cargo-outdated' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:cargo-outdated' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when cargo-outdated is not available' {
            $result = Test-RustOutdated -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls cargo-outdated without arguments' {
            Setup-CapturingCommandMock -CommandName 'cargo-outdated' -Output 'All dependencies are up to date'

            $result = Test-RustOutdated -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            @((Get-TestCommandInvocationArgsFlat | Where-Object { $null -ne $_ -and $_ -ne '' })).Count | Should -Be 0
            $result | Should -Be 'All dependencies are up to date'
        }

        It 'Calls cargo-outdated with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'cargo-outdated' -Output 'Outdated dependencies found'

            Test-RustOutdated '--aggressive' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--aggressive'
        }
    }

    Context 'Error handling' {
        It 'Handles cargo-outdated execution errors' {
            Set-TestCommandThrowingMock -CommandName 'cargo-outdated' -Message 'cargo-outdated: command failed'

            { Test-RustOutdated -ErrorAction Stop } | Should -Throw
        }
    }
}
