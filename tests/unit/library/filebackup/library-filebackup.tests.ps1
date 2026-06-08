<#
tests/unit/library-filebackup.tests.ps1

.SYNOPSIS
    Unit tests for FileBackup module backup, restore, and prune operations.
#>

Describe 'FileBackup Module Functions' {
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

        $script:TestRepoRoot = New-TestTempDirectory -Prefix 'FileBackupRepo'
        $script:Category = 'test-category'
        $script:SourceFile = Join-Path $script:TestRepoRoot 'sample.txt'
        Set-Content -LiteralPath $script:SourceFile -Value 'version-1' -Encoding UTF8 -NoNewline
        $ConfirmPreference = 'None'
    }

    AfterAll {
        if ($script:TestRepoRoot -and (Test-Path $script:TestRepoRoot)) {
            Remove-Item -Path $script:TestRepoRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'New-FileBackup' {
        It 'Stores backups under .backups/<category>' {
            $backup = New-FileBackup -SourcePath $script:SourceFile -RepoRoot $script:TestRepoRoot -Category $script:Category -SkipPrune

            $backup.BackupPath | Should -Match '\.backups[\\/]test-category[\\/]'
            Test-Path -LiteralPath $backup.BackupPath | Should -Be $true
            Test-Path -LiteralPath "$($backup.BackupPath).meta.json" | Should -Be $true
        }
    }

    Context 'Restore-FileBackup' {
        It 'Restores the latest backup to the original source path' {
            Set-Content -LiteralPath $script:SourceFile -Value 'version-2' -Encoding UTF8 -NoNewline
            $backup = New-FileBackup -SourcePath $script:SourceFile -RepoRoot $script:TestRepoRoot -Category $script:Category -SkipPrune

            Set-Content -LiteralPath $script:SourceFile -Value 'version-3' -Encoding UTF8 -NoNewline
            $restoredPath = Restore-FileBackup -RepoRoot $script:TestRepoRoot -BackupPath $backup.BackupPath -Force

            $restoredPath | Should -Be $script:SourceFile
            Get-Content -LiteralPath $script:SourceFile -Raw | Should -Be 'version-2'
        }
    }

    Context 'Remove-OldFileBackups' {
        It 'Keeps only the newest backups per source file' {
            $pruneRepo = New-TestTempDirectory -Prefix 'FileBackupPrune'
            $pruneSource = Join-Path $pruneRepo 'prune-sample.txt'

            1..3 | ForEach-Object {
                Set-Content -LiteralPath $pruneSource -Value "version-$_" -Encoding UTF8 -NoNewline
                New-FileBackup -SourcePath $pruneSource -RepoRoot $pruneRepo -Category $script:Category -SkipPrune | Out-Null
                Start-Sleep -Milliseconds 20
            }

            $removed = Remove-OldFileBackups -RepoRoot $pruneRepo -Category $script:Category -SourcePath $pruneSource -KeepCount 1
            $remaining = @(Get-FileBackups -RepoRoot $pruneRepo -Category $script:Category -SourcePath $pruneSource)
            $removed | Should -BeGreaterOrEqual 1
            $remaining.Count | Should -Be 1
        }
    }
}
