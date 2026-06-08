<#
tests/unit/utility-manage-backups.tests.ps1

.SYNOPSIS
    Unit tests for manage-backups.ps1 list, restore, and prune actions.
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

Describe 'manage-backups.ps1' {
    Context 'Comment-based help and module wiring' {
        It 'Documents List, Restore, and Prune actions' {
            $content = Get-Content -LiteralPath $script:ManageBackupsScript -Raw
            $content | Should -Match '\.PARAMETER Action'
            $content | Should -Match 'ValidateSet\(''List'', ''Restore'', ''Prune''\)'
            $content | Should -Match 'FileBackup'
        }

        It 'Uses standardized exit codes for validation and runtime failures' {
            $content = Get-Content -LiteralPath $script:ManageBackupsScript -Raw
            $content | Should -Match 'Exit-WithCode'
            $content | Should -Match 'EXIT_SUCCESS'
            $content | Should -Match 'EXIT_VALIDATION_FAILURE'
            $content | Should -Match 'EXIT_RUNTIME_ERROR'
        }
    }

    Context 'List action' {
        It 'Exits successfully when no backups exist in an isolated repository root' {
            $emptyRepo = New-TestTempDirectory -Prefix 'ManageBackupsEmpty'
            $result = Invoke-BackupTestScript -ScriptPath $script:ManageBackupsScript -ArgumentList @('-Action', 'List', '-RepoRoot', $emptyRepo)
            $result.ExitCode | Should -Be 0
        }

        It 'Lists backups created under the requested repository root' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsList'
            $source = Join-Path $repo 'listed.txt'
            Set-Content -LiteralPath $source -Value 'listed' -NoNewline
            New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'cli-list' -SkipPrune | Out-Null

            $result = Invoke-BackupTestScript -ScriptPath $script:ManageBackupsScript -ArgumentList @('-Action', 'List', '-RepoRoot', $repo, '-Category', 'cli-list')
            $result.ExitCode | Should -Be 0
        }
    }

    Context 'Restore action' {
        It 'Returns validation failure when restore arguments are incomplete' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsRestoreInvalid'
            $result = Invoke-BackupTestScript -ScriptPath $script:ManageBackupsScript -ArgumentList @('-Action', 'Restore', '-RepoRoot', $repo)
            $result.ExitCode | Should -Be 1
        }

        It 'Restores the latest backup for a source file' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsRestore'
            $source = Join-Path $repo 'restore-me.txt'
            Set-Content -LiteralPath $source -Value 'original' -NoNewline
            New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'cli-restore' -SkipPrune | Out-Null
            Set-Content -LiteralPath $source -Value 'modified' -NoNewline

            $result = Invoke-BackupTestScript -ScriptPath $script:ManageBackupsScript -ArgumentList @(
                '-Action', 'Restore',
                '-RepoRoot', $repo,
                '-Category', 'cli-restore',
                '-SourcePath', $source,
                '-Latest',
                '-Force'
            )

            $result.ExitCode | Should -Be 0
            Get-Content -LiteralPath $source -Raw | Should -Be 'original'
        }

        It 'Returns a runtime error when restore fails' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsRestoreFail'
            $source = Join-Path $repo 'missing-restore.txt'
            Set-Content -LiteralPath $source -Value 'live' -NoNewline

            $result = Invoke-BackupTestScript -ScriptPath $script:ManageBackupsScript -ArgumentList @(
                '-Action', 'Restore',
                '-RepoRoot', $repo,
                '-Category', 'cli-restore-fail',
                '-SourcePath', $source,
                '-Latest',
                '-Force'
            )

            $result.ExitCode | Should -Be 3
        }

        It 'Restores from an explicit backup path' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsRestorePath'
            $source = Join-Path $repo 'explicit.txt'
            Set-Content -LiteralPath $source -Value 'explicit-original' -NoNewline
            $backup = New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'cli-restore-path' -SkipPrune
            Set-Content -LiteralPath $source -Value 'explicit-modified' -NoNewline

            $result = Invoke-BackupTestScript -ScriptPath $script:ManageBackupsScript -ArgumentList @(
                '-Action', 'Restore',
                '-RepoRoot', $repo,
                '-BackupPath', $backup.BackupPath,
                '-Force'
            )

            $result.ExitCode | Should -Be 0
            Get-Content -LiteralPath $source -Raw | Should -Be 'explicit-original'
        }
    }

    Context 'Prune action' {
        It 'Returns validation failure when prune retention options are missing' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsPruneInvalid'
            $result = Invoke-BackupTestScript -ScriptPath $script:ManageBackupsScript -ArgumentList @('-Action', 'Prune', '-RepoRoot', $repo, '-KeepCount', '0')
            $result.ExitCode | Should -Be 1
        }

        It 'Prunes old backups and exits successfully' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsPrune'
            $source = Join-Path $repo 'prune-me.txt'

            1..3 | ForEach-Object {
                Set-Content -LiteralPath $source -Value "v$_" -NoNewline
                New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'cli-prune' -SkipPrune | Out-Null
                Start-Sleep -Milliseconds 20
            }

            $result = Invoke-BackupTestScript -ScriptPath $script:ManageBackupsScript -ArgumentList @(
                '-Action', 'Prune',
                '-RepoRoot', $repo,
                '-Category', 'cli-prune',
                '-SourcePath', $source,
                '-KeepCount', '1'
            )

            $result.ExitCode | Should -Be 0
            @(Get-FileBackups -RepoRoot $repo -Category 'cli-prune' -SourcePath $source).Count | Should -Be 1
        }

        It 'Prunes backups older than MaxAgeDays' {
            $repo = New-TestTempDirectory -Prefix 'ManageBackupsPruneAge'
            $source = Join-Path $repo 'stale.txt'
            Set-Content -LiteralPath $source -Value 'stale' -NoNewline
            $backup = New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'cli-prune-age' -SkipPrune

            $staleMetadata = @{
                SourcePath = $source
                Category   = 'cli-prune-age'
                CreatedAt  = (Get-Date).AddDays(-30).ToUniversalTime().ToString('o')
                BackupPath = $backup.BackupPath
            }
            $staleMetadata | ConvertTo-Json | Set-Content -LiteralPath "$($backup.BackupPath).meta.json" -Encoding UTF8

            $result = Invoke-BackupTestScript -ScriptPath $script:ManageBackupsScript -ArgumentList @(
                '-Action', 'Prune',
                '-RepoRoot', $repo,
                '-Category', 'cli-prune-age',
                '-SourcePath', $source,
                '-MaxAgeDays', '7'
            )

            $result.ExitCode | Should -Be 0
            @(Get-FileBackups -RepoRoot $repo -Category 'cli-prune-age' -SourcePath $source).Count | Should -Be 0
        }
    }
}
