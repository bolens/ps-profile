# ===============================================
# profile-lang-python-script.tests.ps1
# Unit tests for Invoke-PythonScript function
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

Describe 'lang-python.ps1 - Invoke-PythonScript' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames @('python3', 'python')
    }

    Context 'Tool not available' {
        It 'Returns null when python is not available' {
            $result = Invoke-PythonScript -Script 'script.py' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls python3 when available' {
            Setup-CapturingCommandMock -CommandName 'python3' -Output 'Script output'

            $result = Invoke-PythonScript -Script 'script.py' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'script.py'
            $result | Should -Be 'Script output'
        }

        It 'Falls back to python when python3 is not available' {
            Setup-CapturingCommandMock -CommandName 'python' -Output 'Script output'
            Mark-TestCommandsUnavailable -CommandNames 'python3'

            $result = Invoke-PythonScript -Script 'script.py' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'script.py'
            $result | Should -Be 'Script output'
        }

        It 'Calls python with one-liner arguments' {
            Setup-CapturingCommandMock -CommandName 'python3' -Output 'Hello'

            $result = Invoke-PythonScript -Script '' '-c', 'print("Hello")' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-c'
            $args | Should -Contain 'print("Hello")'
            $result | Should -Be 'Hello'
        }
    }

    Context 'Error handling' {
        It 'Handles python execution errors' {
            Set-TestCommandThrowingMock -CommandName 'python3' -Message 'python3: command failed'

            { Invoke-PythonScript -Script 'invalid.py' -ErrorAction Stop } | Should -Throw
        }
    }
}
