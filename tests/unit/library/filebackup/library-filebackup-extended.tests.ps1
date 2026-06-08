<#
tests/unit/library-filebackup-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FileBackup module listing, latest restore, and validation.
#>

Describe 'FileBackup Module extended scenarios' {
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
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'file' 'FileBackup.psm1') -DisableNameChecking -ErrorAction Stop

        $script:TestRepoRoot = New-TestTempDirectory -Prefix 'FileBackupExtended'
        $script:Category = 'extended-category'
        $script:SourceFile = Join-Path $script:TestRepoRoot 'config.txt'
        Set-Content -LiteralPath $script:SourceFile -Value 'alpha' -Encoding UTF8 -NoNewline
        $ConfirmPreference = 'None'
    }

    AfterAll {
        if ($script:TestRepoRoot -and (Test-Path $script:TestRepoRoot)) {
            Remove-Item -Path $script:TestRepoRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Get-FileBackups' {
        It 'Returns backups sorted newest first and filters by category and source path' {
            $repo = New-TestTempDirectory -Prefix 'FileBackupList'
            $source = Join-Path $repo 'list.txt'
            Set-Content -LiteralPath $source -Value 'one' -NoNewline
            $first = New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'list-cat' -SkipPrune
            Start-Sleep -Milliseconds 20
            Set-Content -LiteralPath $source -Value 'two' -NoNewline
            $second = New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'list-cat' -SkipPrune

            $filtered = Get-FileBackups -RepoRoot $repo -Category 'list-cat' -SourcePath $source
            $all = Get-FileBackups -RepoRoot $repo

            $filtered.Count | Should -Be 2
            $filtered[0].BackupPath | Should -Be $second.BackupPath
            $all.Count | Should -BeGreaterOrEqual 2
        }
    }

    Context 'Restore-FileBackup latest and validation' {
        It 'Restores the latest backup when -Latest is specified' {
            $repo = New-TestTempDirectory -Prefix 'FileBackupLatest'
            $source = Join-Path $repo 'latest.txt'
            Set-Content -LiteralPath $source -Value 'old' -NoNewline
            New-FileBackup -SourcePath $source -RepoRoot $repo -Category $script:Category -SkipPrune | Out-Null
            Start-Sleep -Milliseconds 20
            Set-Content -LiteralPath $source -Value 'newest' -NoNewline
            New-FileBackup -SourcePath $source -RepoRoot $repo -Category $script:Category -SkipPrune | Out-Null

            Set-Content -LiteralPath $source -Value 'changed' -NoNewline
            Restore-FileBackup -RepoRoot $repo -Category $script:Category -SourcePath $source -Latest -Force | Out-Null

            Get-Content -LiteralPath $source -Raw | Should -Be 'newest'
        }

        It 'Requires -Force when the destination already exists' {
            $repo = New-TestTempDirectory -Prefix 'FileBackupForce'
            $source = Join-Path $repo 'force.txt'
            Set-Content -LiteralPath $source -Value 'backup-me' -NoNewline
            $backup = New-FileBackup -SourcePath $source -RepoRoot $repo -Category $script:Category -SkipPrune

            { Restore-FileBackup -RepoRoot $repo -BackupPath $backup.BackupPath } | Should -Throw '*Use -Force to overwrite*'
        }
    }

    Context 'New-FileBackup validation and auto-prune' {
        It 'Throws when the source file does not exist' {
            $missing = Join-Path $script:TestRepoRoot 'missing.txt'
            { New-FileBackup -SourcePath $missing -RepoRoot $script:TestRepoRoot -Category $script:Category } | Should -Throw '*Source file not found*'
        }

        It 'Auto-prunes older backups when KeepCount is reached' {
            $repo = New-TestTempDirectory -Prefix 'FileBackupAutoPrune'
            $source = Join-Path $repo 'auto.txt'

            1..3 | ForEach-Object {
                Set-Content -LiteralPath $source -Value "v$_" -NoNewline
                New-FileBackup -SourcePath $source -RepoRoot $repo -Category $script:Category -KeepCount 2 | Out-Null
                Start-Sleep -Milliseconds 20
            }

            $remaining = Get-FileBackups -RepoRoot $repo -Category $script:Category -SourcePath $source
            $remaining.Count | Should -Be 2
        }
    }

    Context 'Remove-OldFileBackups by age' {
        It 'Removes backups older than MaxAgeDays' {
            $repo = New-TestTempDirectory -Prefix 'FileBackupAge'
            $source = Join-Path $repo 'age.txt'
            Set-Content -LiteralPath $source -Value 'stale' -NoNewline
            $backup = New-FileBackup -SourcePath $source -RepoRoot $repo -Category $script:Category -SkipPrune

            $staleMetadata = @{
                SourcePath = $source
                Category   = $script:Category
                CreatedAt  = (Get-Date).AddDays(-30).ToUniversalTime().ToString('o')
                BackupPath = $backup.BackupPath
            }
            $staleMetadata | ConvertTo-Json | Set-Content -LiteralPath "$($backup.BackupPath).meta.json" -Encoding UTF8

            $removed = Remove-OldFileBackups -RepoRoot $repo -Category $script:Category -SourcePath $source -MaxAgeDays 7
            $remaining = @(Get-FileBackups -RepoRoot $repo -Category $script:Category -SourcePath $source)

            $removed | Should -Be 1
            $remaining.Count | Should -Be 0
        }
    }

    Context 'Get-RepoBackupRoot' {
        It 'Creates the .backups directory when -Create is specified' {
            $repo = New-TestTempDirectory -Prefix 'FileBackupRoot'
            $backupRoot = Get-RepoBackupRoot -RepoRoot $repo -Create

            $backupRoot | Should -Be (Join-Path $repo '.backups')
            Test-Path -LiteralPath $backupRoot | Should -Be $true
        }
    }

    Context 'Get-RepoBackupCategoryPath' {
        It 'Creates category directories under .backups when -Create is specified' {
            $repo = New-TestTempDirectory -Prefix 'FileBackupCategory'
            $categoryPath = Get-RepoBackupCategoryPath -RepoRoot $repo -Category 'nested-cat' -Create

            $categoryPath | Should -Be (Join-Path $repo '.backups' 'nested-cat')
            Test-Path -LiteralPath $categoryPath | Should -Be $true
        }
    }

    Context 'Backup integrity and resilience' {
        It 'Copies the full source file contents into the backup file' {
            $repo = New-TestTempDirectory -Prefix 'FileBackupIntegrity'
            $source = Join-Path $repo 'binary-like.txt'
            $payload = 'line1`nline2\tabs'
            Set-Content -LiteralPath $source -Value $payload -NoNewline
            $backup = New-FileBackup -SourcePath $source -RepoRoot $repo -Category $script:Category -SkipPrune

            Get-Content -LiteralPath $backup.BackupPath -Raw | Should -Be $payload
        }

        It 'Skips invalid metadata files when listing backups' {
            $repo = New-TestTempDirectory -Prefix 'FileBackupInvalidMeta'
            $categoryPath = Get-RepoBackupCategoryPath -RepoRoot $repo -Category $script:Category -Create
            $invalidMeta = Join-Path $categoryPath 'broken.backup.20260101010101010.meta.json'
            Set-Content -LiteralPath $invalidMeta -Value '{ not valid json' -Encoding UTF8

            @(Get-FileBackups -RepoRoot $repo -Category $script:Category).Count | Should -Be 0
        }

        It 'Creates missing destination parent directories during restore' {
            $repo = New-TestTempDirectory -Prefix 'FileBackupRestoreParents'
            $source = Join-Path $repo 'nested' 'deep' 'source.txt'
            $null = New-Item -ItemType Directory -Path (Split-Path -Parent $source) -Force
            Set-Content -LiteralPath $source -Value 'deep-content' -NoNewline
            $backup = New-FileBackup -SourcePath $source -RepoRoot $repo -Category $script:Category -SkipPrune

            Remove-Item -LiteralPath (Split-Path -Parent $source) -Recurse -Force
            Restore-FileBackup -RepoRoot $repo -BackupPath $backup.BackupPath -Force | Out-Null

            Test-Path -LiteralPath $source | Should -Be $true
            Get-Content -LiteralPath $source -Raw | Should -Be 'deep-content'
        }
    }

    Context 'Backup metadata and empty results' {
        It 'Stores resolved source paths in metadata for restore' {
            $repo = New-TestTempDirectory -Prefix 'FileBackupMeta'
            $source = Join-Path $repo 'meta.txt'
            Set-Content -LiteralPath $source -Value 'meta' -NoNewline
            $backup = New-FileBackup -SourcePath $source -RepoRoot $repo -Category $script:Category -SkipPrune

            $metadata = Get-Content -LiteralPath "$($backup.BackupPath).meta.json" -Raw | ConvertFrom-Json
            $metadata.SourcePath | Should -Be (Resolve-Path -LiteralPath $source).Path
            $metadata.Category | Should -Be $script:Category
            $metadata.BackupPath | Should -Be $backup.BackupPath
        }

        It 'Returns an empty list when no backups exist' {
            $repo = New-TestTempDirectory -Prefix 'FileBackupEmpty'
            $results = @(Get-FileBackups -RepoRoot $repo)
            $results.Count | Should -Be 0
        }
    }

    Context 'Restore and prune validation' {
        It 'Throws when restoring latest backup without any stored backups' {
            $repo = New-TestTempDirectory -Prefix 'FileBackupNoLatest'
            $source = Join-Path $repo 'missing-backup.txt'
            Set-Content -LiteralPath $source -Value 'live' -NoNewline

            {
                Restore-FileBackup -RepoRoot $repo -Category $script:Category -SourcePath $source -Latest -Force
            } | Should -Throw '*No backups found*'
        }

        It 'Throws when the explicit backup path does not exist' {
            $repo = New-TestTempDirectory -Prefix 'FileBackupMissingPath'
            $missingBackup = Join-Path $repo '.backups' $script:Category 'missing.backup.txt'

            {
                Restore-FileBackup -RepoRoot $repo -BackupPath $missingBackup -Force
            } | Should -Throw '*Backup file not found*'
        }

        It 'Throws when prune retention options are not provided' {
            $repo = New-TestTempDirectory -Prefix 'FileBackupPruneInvalid'

            {
                Remove-OldFileBackups -RepoRoot $repo -Category $script:Category
            } | Should -Throw '*KeepCount and/or -MaxAgeDays*'
        }
    }
}
