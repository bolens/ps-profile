<#
tests/unit/validation/check/validation-check-commit-messages.tests.ps1

.SYNOPSIS
    Behavioral tests for check-commit-messages.ps1 with an isolated Git command.
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
    $script:CheckCommitMessagesScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-commit-messages.ps1'

    function global:Invoke-CommitGitFixture {
        param(
            [Parameter(ValueFromRemainingArguments)]
            [string[]]$Arguments
        )

        switch ($Arguments[0]) {
            'fetch' {
                if ($global:CommitGitFetchThrows) {
                    throw 'fixture fetch failed'
                }
                $global:LASTEXITCODE = 0
            }
            'rev-list' {
                $global:LASTEXITCODE = $global:CommitGitRevListExitCode
                $global:CommitGitCommits
            }
            'log' {
                $commit = $Arguments[-1]
                $global:LASTEXITCODE = $global:CommitGitLogExitCode
                $global:CommitGitSubjects[$commit]
            }
        }
    }
}

Describe 'check-commit-messages.ps1 execution' {
    BeforeEach {
        $global:CommitGitCommits = @()
        $global:CommitGitSubjects = @{}
        $global:CommitGitRevListExitCode = 0
        $global:CommitGitLogExitCode = 0
        $global:CommitGitFetchThrows = $false
    }

    It 'accepts an empty commit range after a failed optional fetch' {
        $global:CommitGitFetchThrows = $true

        $output = & $script:CheckCommitMessagesScript `
            -Base 'fixture/main' `
            -GitExecutable 'Invoke-CommitGitFixture' 2>&1 | Out-String

        $output | Should -Match 'No commits to check against fixture/main'
    }

    It 'accepts conventional, merge, revert, auto-merge, and blank subjects' {
        $global:CommitGitCommits = @('a1', 'b2', 'c3', 'd4', 'e5', 'f6')
        $global:CommitGitSubjects = @{
            a1 = 'feat(core): add portable check'
            b2 = 'Merge branch feature'
            c3 = 'Revert "bad change"'
            d4 = 'Auto-merge dependabot update'
            e5 = ''
            f6 = 'ci: validate commits'
        }

        $output = & $script:CheckCommitMessagesScript `
            -Base 'fixture/main' `
            -GitExecutable 'Invoke-CommitGitFixture' `
            -SkipFetch 2>&1 | Out-String

        $output | Should -Match 'All commit subjects conform'
    }

    It 'reports each invalid commit subject' {
        $global:CommitGitCommits = @('bad1', 'bad2')
        $global:CommitGitSubjects = @{
            bad1 = 'Add feature'
            bad2 = 'fix missing colon'
        }

        {
            & $script:CheckCommitMessagesScript `
                -GitExecutable 'Invoke-CommitGitFixture' `
                -SkipFetch
        } | Should -Throw '*Found 2 commit(s) with invalid commit subjects*'
    }

    It 'reports failure to read the commit range' {
        $global:CommitGitRevListExitCode = 128

        {
            & $script:CheckCommitMessagesScript `
                -GitExecutable 'Invoke-CommitGitFixture' `
                -SkipFetch
        } | Should -Throw '*Unable to read commit range*git exit code 128*'
    }

    It 'reports failure to read a commit subject' {
        $global:CommitGitCommits = @('broken')
        $global:CommitGitLogExitCode = 7

        {
            & $script:CheckCommitMessagesScript `
                -GitExecutable 'Invoke-CommitGitFixture' `
                -SkipFetch
        } | Should -Throw '*Unable to read commit broken*git exit code 7*'
    }
}
