# ===============================================
# profile-lang-go-goreleaser.tests.ps1
# Unit tests for Release-GoProject function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-go.ps1')
}

Describe 'lang-go.ps1 - Release-GoProject' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'goreleaser' -Available $false
        Remove-Item -Path 'Function:\goreleaser' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:goreleaser' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when goreleaser is not available' {
            $result = Release-GoProject -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls goreleaser without arguments' {
            Setup-CapturingCommandMock -CommandName 'goreleaser' -Output 'Release created'

            $result = Release-GoProject -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            @((Get-TestCommandInvocationArgsFlat | Where-Object { $null -ne $_ -and $_ -ne '' })).Count | Should -Be 0
            $result | Should -Be 'Release created'
        }

        It 'Calls goreleaser with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'goreleaser' -Output 'Release created'

            Release-GoProject '--snapshot' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--snapshot'
        }
    }

    Context 'Error handling' {
        It 'Handles goreleaser execution errors' {
            Set-TestCommandThrowingMock -CommandName 'goreleaser' -Message 'goreleaser: command failed'

            { Release-GoProject -ErrorAction Stop } | Should -Throw
        }
    }
}
