# ===============================================
# profile-git-enhanced-changelog.tests.ps1
# Unit tests for New-GitChangelog function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
}

Describe 'git-enhanced.ps1 - New-GitChangelog' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'git-cliff' -Available $false
        Remove-Item -Path 'Function:\git-cliff' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:git-cliff' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when git-cliff is not available' {
            $result = New-GitChangelog -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls git-cliff with default output path' {
            Setup-CapturingCommandMock -CommandName 'git-cliff' -Output 'CHANGELOG.md'

            New-GitChangelog -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--output'
            $args | Should -Contain 'CHANGELOG.md'
        }

        It 'Calls git-cliff with custom output path' {
            Setup-CapturingCommandMock -CommandName 'git-cliff' -Output 'docs/CHANGELOG.md'

            New-GitChangelog -OutputPath 'docs/CHANGELOG.md' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--output'
            $args | Should -Contain 'docs/CHANGELOG.md'
        }

        It 'Calls git-cliff with config path' {
            Setup-CapturingCommandMock -CommandName 'git-cliff'

            New-GitChangelog -ConfigPath 'cliff.toml' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--config'
            $args | Should -Contain 'cliff.toml'
        }

        It 'Calls git-cliff with tag' {
            Setup-CapturingCommandMock -CommandName 'git-cliff'

            New-GitChangelog -Tag 'v1.0.0' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--tag'
            $args | Should -Contain 'v1.0.0'
        }

        It 'Calls git-cliff with latest flag' {
            Setup-CapturingCommandMock -CommandName 'git-cliff'

            New-GitChangelog -Latest -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--latest'
        }

        It 'Returns output path on success' {
            Setup-CapturingCommandMock -CommandName 'git-cliff' -ExitCode 0

            $result = New-GitChangelog -OutputPath 'CHANGELOG.md' -ErrorAction SilentlyContinue

            $result | Should -Be 'CHANGELOG.md'
        }

        It 'Handles git-cliff execution errors' {
            Setup-CapturingCommandMock -CommandName 'git-cliff' -ExitCode 1

            { New-GitChangelog -ErrorAction Stop } | Should -Throw
        }
    }
}
