<#
tests/unit/utility/create/utility-create-release.tests.ps1

.SYNOPSIS
    Behavioral tests for create-release.ps1 with isolated command fixtures.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $null -eq $current.Parent) { break }
        $current = $current.Parent
    }

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CreateReleaseScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'release' 'create-release.ps1'

    function global:Invoke-ReleaseGitFixture {
        $arguments = @($args)
        $global:ReleaseGitCalls.Add(($arguments -join ' '))
        $global:LASTEXITCODE = 0
        if ($arguments[0] -eq 'describe') {
            return 'v1.2.3'
        }
        if ($arguments[0] -eq 'log') {
            return @($global:ReleaseCommitSubjects)
        }
    }

    function global:Invoke-ReleaseChangelogFixture {
        param([switch]$Unreleased)
        $global:ReleaseChangelogCalled = $Unreleased.IsPresent
        $global:LASTEXITCODE = 0
    }
}

Describe 'create-release.ps1 execution' {
    BeforeEach {
        $global:ReleaseCommitSubjects = @('docs: update release notes')
        $global:ReleaseGitCalls = [System.Collections.Generic.List[string]]::new()
        $global:ReleaseChangelogCalled = $false
    }

    It 'selects a patch release for non-feature commits' {
        { & $script:CreateReleaseScript -DryRun -GitExecutable 'Invoke-ReleaseGitFixture' } | Should -Not -Throw
        $global:ReleaseGitCalls | Should -Contain 'describe --tags --abbrev=0'
    }

    It 'selects a minor release when feature commits are present' {
        $global:ReleaseCommitSubjects = @('feat(release): add release automation', 'fix: correct notes')
        { & $script:CreateReleaseScript -DryRun -GitExecutable 'Invoke-ReleaseGitFixture' } | Should -Not -Throw
    }

    It 'selects a major release when breaking commits are present' {
        $global:ReleaseCommitSubjects = @('feat!: remove deprecated hook')
        { & $script:CreateReleaseScript -DryRun -GitExecutable 'Invoke-ReleaseGitFixture' } | Should -Not -Throw
    }

    It 'generates a changelog, tags, and pushes a release' {
        $global:ReleaseCommitSubjects = @('fix(release): correct published archive')

        {
            & $script:CreateReleaseScript `
                -GitExecutable 'Invoke-ReleaseGitFixture' `
                -ChangelogScript 'Invoke-ReleaseChangelogFixture'
        } | Should -Not -Throw

        $global:ReleaseChangelogCalled | Should -BeTrue
        $global:ReleaseGitCalls | Should -Contain 'tag -a v1.2.4 -m Release v1.2.4'
        $global:ReleaseGitCalls | Should -Contain 'push origin v1.2.4'
    }
}
