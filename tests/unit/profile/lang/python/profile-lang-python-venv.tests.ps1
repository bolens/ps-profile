# ===============================================
# profile-lang-python-venv.tests.ps1
# Unit tests for New-PythonVirtualEnv function
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
    . (Join-Path $script:ProfileDir 'lang-python-env.ps1')
}

Describe 'lang-python.ps1 - New-PythonVirtualEnv' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames @('uv', 'python3', 'python')
    }

    Context 'Tool not available' {
        It 'Returns null when neither uv nor python is available' {
            $result = New-PythonVirtualEnv -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Prefers uv when available' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output 'Virtual environment created'

            $result = New-PythonVirtualEnv -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'venv'
            $args | Should -Contain '.venv'
            $result | Should -Be 'Virtual environment created'
        }

        It 'Falls back to python -m venv when uv is not available' {
            Setup-CapturingCommandMock -CommandName 'python3' -Output 'Virtual environment created'
            Mark-TestCommandsUnavailable -CommandNames 'uv'

            $result = New-PythonVirtualEnv -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-m'
            $args | Should -Contain 'venv'
            $result | Should -Be 'Virtual environment created'
        }

        It 'Uses custom path when specified' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output 'Virtual environment created'

            New-PythonVirtualEnv -Path 'venv' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'venv'
        }

        It 'Uses Python version when specified (uv only)' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output 'Virtual environment created'

            New-PythonVirtualEnv -PythonVersion '3.11' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--python'
            $args | Should -Contain '3.11'
        }
    }

    Context 'Error handling' {
        It 'Falls back to python when uv fails' {
            Setup-CapturingCommandMock -CommandName 'python3' -Output 'Virtual environment created'

            $global:AssumedAvailableCommands['uv'] = $true
            $global:TestCachedCommandCache['uv'] = [pscustomobject]@{
                Result  = $true
                Expires = (Get-Date).AddHours(24)
            }
            $throwingUv = {
                throw [System.Management.Automation.CommandNotFoundException]::new('uv: command failed')
            }
            Set-Item -Path 'Function:\global:uv' -Value $throwingUv -Force
            Set-Item -Path 'Function:\uv' -Value $throwingUv -Force

            $result = New-PythonVirtualEnv -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-m'
        }
    }
}
