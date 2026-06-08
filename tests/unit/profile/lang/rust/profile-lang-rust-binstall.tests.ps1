# ===============================================
# profile-lang-rust-binstall.tests.ps1
# Unit tests for Install-RustBinary function
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
    . (Join-Path $script:ProfileDir 'lang-rust-tools.ps1')
}

Describe 'lang-rust.ps1 - Install-RustBinary' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'cargo-binstall' -Available $false
        Remove-Item -Path 'Function:\cargo-binstall' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:cargo-binstall' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when cargo-binstall is not available' {
            $result = Install-RustBinary -Packages @('cargo-watch') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls cargo-binstall with package names' {
            Setup-CapturingCommandMock -CommandName 'cargo-binstall' -Output 'Installed cargo-watch'

            $result = Install-RustBinary -Packages @('cargo-watch') -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'cargo-watch'
            $result | Should -Be 'Installed cargo-watch'
        }

        It 'Calls cargo-binstall with version flag when specified' {
            Setup-CapturingCommandMock -CommandName 'cargo-binstall' -Output 'Installed cargo-audit'

            Install-RustBinary -Packages @('cargo-audit') -Version '0.18.0' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--version'
            $args | Should -Contain '0.18.0'
            $args | Should -Contain 'cargo-audit'
        }

        It 'Calls cargo-binstall with multiple packages' {
            Setup-CapturingCommandMock -CommandName 'cargo-binstall' -Output 'Installed packages'

            Install-RustBinary -Packages @('cargo-watch', 'cargo-audit') -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'cargo-watch'
            $args | Should -Contain 'cargo-audit'
        }
    }

    Context 'Error handling' {
        It 'Handles cargo-binstall execution errors' {
            Set-TestCommandThrowingMock -CommandName 'cargo-binstall' -Message 'cargo-binstall: command failed'

            { Install-RustBinary -Packages @('invalid-package') -ErrorAction Stop } | Should -Throw
        }
    }
}
