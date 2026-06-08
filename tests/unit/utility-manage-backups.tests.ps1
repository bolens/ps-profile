<#
tests/unit/utility-manage-backups.tests.ps1

.SYNOPSIS
    Unit tests for manage-backups.ps1 list, restore, and prune actions.
#>

function global:Invoke-ManageBackupsScript {
    param(
        [string[]]$ArgumentList
    )

    & pwsh -NoProfile -File $script:ManageBackupsScript @ArgumentList 2>&1 | Out-Null
    return $LASTEXITCODE
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ManageBackupsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'manage-backups.ps1'
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'file' 'FileBackup.psm1') -DisableNameChecking -ErrorAction Stop
    $ConfirmPreference = 'None'
}

Describe 'manage-backups.ps1' {
    Context 'Comment-based help and module wiring' {
        It 'Documents List, Restore, and Prune actions' {
            $content = Get-Content -LiteralPath $script:ManageBackupsScript -Raw
            $content | Should -Match '\.PARAMETER Action'
            $content | Should -Match 'ValidateSet\(''List'', ''Restore'', ''Prune''\)'
            $content | Should -Match 'FileBackup'
        }
    }

    Context 'List action' {
        It 'Exits successfully when no backups exist in an isolated repository root' {
            $emptyRepo = New-TestTempDirectory -Prefix 'ManageBackupsEmpty'
            $exitCode = Invoke-ManageBackupsScript -ArgumentList @('-Action', 'List', '-RepoRoot', $emptyRepo)
            $exitCode | Should -Be 0
        }

        It 'Lists backups created under the requested repository root' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsList'
            $source = Join-Path $repo 'listed.txt'
            Set-Content -LiteralPath $source -Value 'listed' -NoNewline
            New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'cli-list' -SkipPrune | Out-Null

            $exitCode = Invoke-ManageBackupsScript -ArgumentList @('-Action', 'List', '-RepoRoot', $repo, '-Category', 'cli-list')
            $exitCode | Should -Be 0
        }
    }

    Context 'Restore action' {
        It 'Returns validation failure when restore arguments are incomplete' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsRestoreInvalid'
            $exitCode = Invoke-ManageBackupsScript -ArgumentList @('-Action', 'Restore', '-RepoRoot', $repo)
            $exitCode | Should -Be 1
        }

        It 'Restores the latest backup for a source file' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsRestore'
            $source = Join-Path $repo 'restore-me.txt'
            Set-Content -LiteralPath $source -Value 'original' -NoNewline
            New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'cli-restore' -SkipPrune | Out-Null
            Set-Content -LiteralPath $source -Value 'modified' -NoNewline

            $exitCode = Invoke-ManageBackupsScript -ArgumentList @(
                '-Action', 'Restore',
                '-RepoRoot', $repo,
                '-Category', 'cli-restore',
                '-SourcePath', $source,
                '-Latest',
                '-Force'
            )

            $exitCode | Should -Be 0
            Get-Content -LiteralPath $source -Raw | Should -Be 'original'
        }
    }

    Context 'Prune action' {
        It 'Returns validation failure when prune retention options are missing' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsPruneInvalid'
            $exitCode = Invoke-ManageBackupsScript -ArgumentList @('-Action', 'Prune', '-RepoRoot', $repo, '-KeepCount', '0')
            $exitCode | Should -Be 1
        }

        It 'Prunes old backups and exits successfully' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsPrune'
            $source = Join-Path $repo 'prune-me.txt'

            1..3 | ForEach-Object {
                Set-Content -LiteralPath $source -Value "v$_" -NoNewline
                New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'cli-prune' -SkipPrune | Out-Null
                Start-Sleep -Milliseconds 20
            }

            $exitCode = Invoke-ManageBackupsScript -ArgumentList @(
                '-Action', 'Prune',
                '-RepoRoot', $repo,
                '-Category', 'cli-prune',
                '-SourcePath', $source,
                '-KeepCount', '1'
            )

            $exitCode | Should -Be 0
            $remaining = Get-FileBackups -RepoRoot $repo -Category 'cli-prune' -SourcePath $source
            $remaining.Count | Should -Be 1
        }
    }
}
