# ===============================================
# profile-lang-python-pipx.tests.ps1
# Unit tests for pipx-related functions
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
    . (Join-Path $script:ProfileDir 'lang-python-pipx.ps1')
}

Describe 'lang-python.ps1 - Install-PythonApp' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'pipx' -Available $false
        Remove-Item -Path 'Function:\pipx' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:pipx' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when pipx is not available' {
            $result = Install-PythonApp -Packages @('black') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls pipx install with package names' {
            Setup-CapturingCommandMock -CommandName 'pipx' -Output 'Installed black'

            $result = Install-PythonApp -Packages @('black') -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'install'
            $args | Should -Contain 'black'
            $result | Should -Be 'Installed black'
        }

        It 'Calls pipx install with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'pipx' -Output 'Installed pytest'

            $params = @{
                Packages  = @('pytest')
                Arguments = @('--include-deps')
            }
            Install-PythonApp @params -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'install'
            $args | Should -Contain '--include-deps'
            $args | Should -Contain 'pytest'
        }
    }

    Context 'Error handling' {
        It 'Handles pipx execution errors' {
            Set-TestCommandThrowingMock -CommandName 'pipx' -Message 'pipx: command failed'

            { Install-PythonApp -Packages @('invalid-package') -ErrorAction Stop } | Should -Throw '*pipx*'
        }
    }
}

Describe 'lang-python.ps1 - Invoke-Pipx' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'pipx' -Available $false
        Remove-Item -Path 'Function:\pipx' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:pipx' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when pipx is not available' {
            $result = Invoke-Pipx -Package 'black' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls pipx run with package and arguments' {
            Setup-CapturingCommandMock -CommandName 'pipx' -Output 'Formatting complete'

            $result = Invoke-Pipx -Package 'black' '--check', '.' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'run'
            $args | Should -Contain 'black'
            $args | Should -Contain '--check'
            $result | Should -Be 'Formatting complete'
        }
    }

    Context 'Error handling' {
        It 'Handles pipx execution errors' {
            Set-TestCommandThrowingMock -CommandName 'pipx' -Message 'pipx: command failed'

            { Invoke-Pipx -Package 'invalid-package' -ErrorAction Stop } | Should -Throw '*pipx*'
        }
    }
}
