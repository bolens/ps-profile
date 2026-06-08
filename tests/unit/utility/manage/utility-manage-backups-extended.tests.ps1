<#
tests/unit/utility-manage-backups-extended.tests.ps1

.SYNOPSIS
    Extended behavioral tests for manage-backups.ps1 output and filtering.
#>

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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ManageBackupsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'manage-backups.ps1'
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'file' 'FileBackup.psm1') -DisableNameChecking -ErrorAction Stop
    $ConfirmPreference = 'None'
}

Describe 'manage-backups.ps1 extended scenarios' {
    Context 'List output' {
        It 'Reports when no backups are found' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsListEmpty'
            $result = Invoke-BackupTestScript -ScriptPath $script:ManageBackupsScript -ArgumentList @('-Action', 'List', '-RepoRoot', $repo)

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'No backups found'
        }

        It 'Prints backup details when backups exist' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsListDetails'
            $source = Join-Path $repo 'details.txt'
            Set-Content -LiteralPath $source -Value 'details-content' -NoNewline
            New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'cli-list-details' -SkipPrune | Out-Null

            $result = Invoke-BackupTestScript -ScriptPath $script:ManageBackupsScript -ArgumentList @(
                '-Action', 'List',
                '-RepoRoot', $repo,
                '-Category', 'cli-list-details',
                '-SourcePath', $source
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'cli-list-details'
            $result.Output | Should -Match 'SourcePath'
            $result.Output | Should -Match 'ManageBackupsListD'
        }
    }

    Context 'Comment-based help' {
        It 'Documents Latest, MaxAgeDays, Force, and RepoRoot parameters' {
            $content = Get-Content -LiteralPath $script:ManageBackupsScript -Raw
            $content | Should -Match '\.PARAMETER Latest'
            $content | Should -Match '\.PARAMETER MaxAgeDays'
            $content | Should -Match '\.PARAMETER Force'
            $content | Should -Match '\.PARAMETER RepoRoot'
            $content | Should -Match '\.PARAMETER Category'
        }
    }

    Context 'Category-wide prune' {
        It 'Prunes all backups in a category when SourcePath is omitted' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsPruneCategory'
            $first = Join-Path $repo 'first.txt'
            $second = Join-Path $repo 'second.txt'

            1..2 | ForEach-Object {
                Set-Content -LiteralPath $first -Value "first-$_" -NoNewline
                New-FileBackup -SourcePath $first -RepoRoot $repo -Category 'cli-prune-all' -SkipPrune | Out-Null
                Start-Sleep -Milliseconds 20
            }
            Set-Content -LiteralPath $second -Value 'second-v1' -NoNewline
            New-FileBackup -SourcePath $second -RepoRoot $repo -Category 'cli-prune-all' -SkipPrune | Out-Null

            $result = Invoke-BackupTestScript -ScriptPath $script:ManageBackupsScript -ArgumentList @(
                '-Action', 'Prune',
                '-RepoRoot', $repo,
                '-Category', 'cli-prune-all',
                '-KeepCount', '1'
            )

            $result.ExitCode | Should -Be 0
            @(Get-FileBackups -RepoRoot $repo -Category 'cli-prune-all' -SourcePath $first).Count | Should -Be 1
            @(Get-FileBackups -RepoRoot $repo -Category 'cli-prune-all' -SourcePath $second).Count | Should -Be 1
        }
    }
}
