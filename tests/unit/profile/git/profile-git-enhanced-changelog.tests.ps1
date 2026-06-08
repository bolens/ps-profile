# ===============================================
# profile-git-enhanced-changelog.tests.ps1
# Unit tests for New-GitChangelog function
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
    . (Join-Path $script:ProfileDir 'git-enhanced.ps1')

    $script:TestChangelogPath = Get-TestArtifactPath -FileName 'CHANGELOG.md'
    $script:TestDocsChangelogDir = Join-Path (New-TestTempDirectory -Prefix 'GitChangelogDocs') 'docs'
    New-Item -ItemType Directory -Path $script:TestDocsChangelogDir -Force | Out-Null
    $script:TestDocsChangelogPath = Join-Path $script:TestDocsChangelogDir 'CHANGELOG.md'
    $script:TestCliffConfigPath = Get-TestArtifactPath -FileName 'cliff.toml'
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
            Setup-CapturingCommandMock -CommandName 'git-cliff' -Output $script:TestChangelogPath

            New-GitChangelog -OutputPath $script:TestChangelogPath -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--output'
            $args | Should -Contain $script:TestChangelogPath
        }

        It 'Calls git-cliff with custom output path' {
            Setup-CapturingCommandMock -CommandName 'git-cliff' -Output $script:TestDocsChangelogPath

            New-GitChangelog -OutputPath $script:TestDocsChangelogPath -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--output'
            $args | Should -Contain $script:TestDocsChangelogPath
        }

        It 'Calls git-cliff with config path' {
            Setup-CapturingCommandMock -CommandName 'git-cliff'

            New-GitChangelog -ConfigPath $script:TestCliffConfigPath -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--config'
            $args | Should -Contain $script:TestCliffConfigPath
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

            $result = New-GitChangelog -OutputPath $script:TestChangelogPath -ErrorAction SilentlyContinue

            $result | Should -Be $script:TestChangelogPath
        }

        It 'Handles git-cliff execution errors' {
            Setup-CapturingCommandMock -CommandName 'git-cliff' -ExitCode 1

            { New-GitChangelog -ErrorAction Stop } | Should -Throw
        }
    }
}
