# ===============================================
# profile-lang-rust-watch.tests.ps1
# Unit tests for Watch-RustProject function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-rust-tools.ps1')
}

Describe 'lang-rust.ps1 - Watch-RustProject' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'cargo-watch' -Available $false
        Remove-Item -Path 'Function:\cargo-watch' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:cargo-watch' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when cargo-watch is not available' {
            $result = Watch-RustProject -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls cargo-watch with default check command' {
            Setup-CapturingCommandMock -CommandName 'cargo-watch' -Output 'Watching for changes...'

            $result = Watch-RustProject -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-x'
            $args | Should -Contain 'cargo check'
            $result | Should -Be 'Watching for changes...'
        }

        It 'Calls cargo-watch with specified command' {
            Setup-CapturingCommandMock -CommandName 'cargo-watch' -Output 'Watching for changes...'

            Watch-RustProject -Command 'test' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-x'
            $args | Should -Contain 'cargo test'
        }

        It 'Calls cargo-watch with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'cargo-watch' -Output 'Watching for changes...'

            Watch-RustProject -Command 'run' '--release' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--'
            $args | Should -Contain '--release'
        }
    }

    Context 'Error handling' {
        It 'Handles cargo-watch execution errors' {
            Set-TestCommandThrowingMock -CommandName 'cargo-watch' -Message 'cargo-watch: command failed'

            { Watch-RustProject -ErrorAction Stop } | Should -Throw
        }
    }
}
