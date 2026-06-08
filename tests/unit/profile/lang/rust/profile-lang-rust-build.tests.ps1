# ===============================================
# profile-lang-rust-build.tests.ps1
# Unit tests for Build-RustRelease and Update-RustDependencies functions
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
    . (Join-Path $script:ProfileDir 'lang-rust-build.ps1')
}

Describe 'lang-rust.ps1 - Build-RustRelease' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'cargo'
    }

    Context 'Tool not available' {
        It 'Returns null when cargo is not available' {
            $result = Build-RustRelease -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls cargo build --release without arguments' {
            Setup-CapturingCommandMock -CommandName 'cargo' -Output 'Build complete'

            $result = Build-RustRelease -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'build'
            $args | Should -Contain '--release'
            $result | Should -Be 'Build complete'
        }

        It 'Calls cargo build --release with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'cargo' -Output 'Build complete'

            Build-RustRelease '--bin', 'myapp' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'build'
            $args | Should -Contain '--release'
            $args | Should -Contain '--bin'
            $args | Should -Contain 'myapp'
        }
    }

    Context 'Error handling' {
        It 'Handles cargo build execution errors' {
            Set-TestCommandThrowingMock -CommandName 'cargo' -Message 'cargo: command failed'

            { Build-RustRelease -ErrorAction Stop } | Should -Throw
        }
    }
}

Describe 'lang-rust.ps1 - Update-RustDependencies' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'cargo'
    }

    Context 'Tool not available' {
        It 'Returns null when cargo is not available' {
            $result = Update-RustDependencies -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls cargo update without arguments' {
            Setup-CapturingCommandMock -CommandName 'cargo' -Output 'Dependencies updated'

            $result = Update-RustDependencies -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'update'
            $result | Should -Be 'Dependencies updated'
        }

        It 'Calls cargo update with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'cargo' -Output 'Dependencies updated'

            Update-RustDependencies '--package', 'serde' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'update'
            $args | Should -Contain '--package'
            $args | Should -Contain 'serde'
        }
    }

    Context 'Error handling' {
        It 'Handles cargo update execution errors' {
            Set-TestCommandThrowingMock -CommandName 'cargo' -Message 'cargo: command failed'

            { Update-RustDependencies -ErrorAction Stop } | Should -Throw
        }
    }
}
