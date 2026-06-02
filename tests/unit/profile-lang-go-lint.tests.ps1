# ===============================================
# profile-lang-go-lint.tests.ps1
# Unit tests for Lint-GoProject function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-go.ps1')
}

Describe 'lang-go.ps1 - Lint-GoProject' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'golangci-lint' -Available $false
        Remove-Item -Path 'Function:\golangci-lint' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:golangci-lint' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when golangci-lint is not available' {
            $result = Lint-GoProject -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls golangci-lint without arguments' {
            Setup-CapturingCommandMock -CommandName 'golangci-lint' -Output 'Linting complete'

            $result = Lint-GoProject -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            @((Get-TestCommandInvocationArgsFlat | Where-Object { $null -ne $_ -and $_ -ne '' })).Count | Should -Be 0
            $result | Should -Be 'Linting complete'
        }

        It 'Calls golangci-lint with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'golangci-lint' -Output 'Linting complete'

            Lint-GoProject '--fix', './...' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--fix'
            $args | Should -Contain './...'
        }
    }

    Context 'Error handling' {
        It 'Handles golangci-lint execution errors' {
            Set-TestCommandThrowingMock -CommandName 'golangci-lint' -Message 'golangci-lint: command failed'

            { Lint-GoProject -ErrorAction Stop } | Should -Throw
        }
    }
}
