# ===============================================
# profile-lang-go-build.tests.ps1
# Unit tests for Build-GoProject and Test-GoProject functions
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
    . (Join-Path $script:ProfileDir 'lang-go.ps1')
}

Describe 'lang-go.ps1 - Build-GoProject' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'go'
    }

    Context 'Tool not available' {
        It 'Returns null when go is not available' {
            $result = Build-GoProject -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls go build without arguments' {
            Setup-CapturingCommandMock -CommandName 'go' -Output 'Build complete'

            $result = Build-GoProject -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'build'
            $result | Should -Be 'Build complete'
        }

        It 'Calls go build with output flag' {
            Setup-CapturingCommandMock -CommandName 'go' -Output 'Build complete'

            Build-GoProject -Output 'myapp' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'build'
            $args | Should -Contain '-o'
            $args | Should -Contain 'myapp'
        }

        It 'Calls go build with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'go' -Output 'Build complete'

            Build-GoProject -Output $null '-ldflags', '-s -w' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'build'
            $args | Should -Contain '-ldflags'
        }
    }

    Context 'Error handling' {
        It 'Handles go build execution errors' {
            Set-TestCommandThrowingMock -CommandName 'go' -Message 'go: command failed'

                        $result = Build-GoProject -ErrorAction SilentlyContinue
        }
        catch {
            $result = $null

            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'lang-go.ps1 - Test-GoProject' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'go'
    }

    Context 'Tool not available' {
        It 'Returns null when go is not available' {
            $result = Test-GoProject -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls go test without flags' {
            Setup-CapturingCommandMock -CommandName 'go' -Output 'Tests passed'

            $result = Test-GoProject -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'test'
            $result | Should -Be 'Tests passed'
        }

        It 'Calls go test with verbose flag' {
            Setup-CapturingCommandMock -CommandName 'go' -Output 'Tests passed'

            Test-GoProject -VerboseOutput -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'test'
            $args | Should -Contain '-v'
        }

        It 'Calls go test with coverage flag' {
            Setup-CapturingCommandMock -CommandName 'go' -Output 'Tests passed'

            Test-GoProject -Coverage -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'test'
            $args | Should -Contain '-cover'
        }

        It 'Calls go test with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'go' -Output 'Tests passed'

            Test-GoProject './...' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'test'
            $args | Should -Contain './...'
        }
    }

    Context 'Error handling' {
        It 'Handles go test execution errors' {
            Set-TestCommandThrowingMock -CommandName 'go' -Message 'go: command failed'

                        $result = Test-GoProject -ErrorAction SilentlyContinue
        }
        catch {
            $result = $null

            $result | Should -BeNullOrEmpty
        }
    }
}
