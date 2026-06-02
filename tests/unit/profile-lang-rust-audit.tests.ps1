# ===============================================
# profile-lang-rust-audit.tests.ps1
# Unit tests for Audit-RustProject function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-rust-audit.ps1')
}

Describe 'lang-rust.ps1 - Audit-RustProject' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'cargo-audit' -Available $false
        Remove-Item -Path 'Function:\cargo-audit' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:cargo-audit' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when cargo-audit is not available' {
            $result = Audit-RustProject -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls cargo-audit without arguments' {
            Setup-CapturingCommandMock -CommandName 'cargo-audit' -Output 'No vulnerabilities found'

            $result = Audit-RustProject -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            @((Get-TestCommandInvocationArgsFlat | Where-Object { $null -ne $_ -and $_ -ne '' })).Count | Should -Be 0
            $result | Should -Be 'No vulnerabilities found'
        }

        It 'Calls cargo-audit with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'cargo-audit' -Output 'Audit complete'

            Audit-RustProject '--deny', 'warnings' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--deny'
            $args | Should -Contain 'warnings'
        }
    }

    Context 'Error handling' {
        It 'Handles cargo-audit execution errors' {
            Set-TestCommandThrowingMock -CommandName 'cargo-audit' -Message 'cargo-audit: command failed'

            { Audit-RustProject -ErrorAction Stop } | Should -Throw
        }
    }
}
