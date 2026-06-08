<#
tests/unit/utility-check-task-parity-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for check-task-parity.ps1 task runner parity checker.
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
    $script:TaskParityScript = Join-Path $script:TestRepoRoot 'scripts/utils/task-parity/check-task-parity.ps1'
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'file' 'FileBackup.psm1') -DisableNameChecking -ErrorAction Stop
    $ConfirmPreference = 'None'
}

Describe 'check-task-parity.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Generate and TargetFile parameters' {
            $content = Get-Content -LiteralPath $script:TaskParityScript -Raw
            $content | Should -Match '\.PARAMETER Generate'
            $content | Should -Match 'TargetFile'
        }

        It 'Compares Taskfile Makefile package.json justfile and tasks.json' {
            $content = Get-Content -LiteralPath $script:TaskParityScript -Raw
            $content | Should -Match 'Taskfile\.yml'
            $content | Should -Match 'Makefile'
            $content | Should -Match 'package\.json'
        }
    }

    Context 'Parity analysis' {
        It 'Reports tasks missing across runner files' {
            $content = Get-Content -LiteralPath $script:TaskParityScript -Raw
            $content | Should -Match 'missing in others'
            $content | Should -Match 'Command differences'
        }

        It 'Imports TaskParityUtilities module helpers' {
            $content = Get-Content -LiteralPath $script:TaskParityScript -Raw
            $content | Should -Match 'TaskParityUtilities'
        }
    }

    Context 'Backup integration' {
        It 'Documents restore, prune, and FileBackup parameters' {
            $content = Get-Content -LiteralPath $script:TaskParityScript -Raw
            $content | Should -Match '\.PARAMETER Restore'
            $content | Should -Match '\.PARAMETER Prune'
            $content | Should -Match 'FileBackup'
            $content | Should -Match 'task-parity'
        }

        It 'Uses New-FileBackup instead of writing backups beside task files' {
            $content = Get-Content -LiteralPath $script:TaskParityScript -Raw
            $content | Should -Match 'New-FileBackup'
            $content | Should -Not -Match '\$filePath\.backup\.'
        }

        It 'Passes KeepCount through to New-FileBackup during generation' {
            $content = Get-Content -LiteralPath $script:TaskParityScript -Raw
            $content | Should -Match 'New-FileBackup -SourcePath \$filePath -RepoRoot \$RepoRoot -Category ''task-parity'' -KeepCount \$KeepCount'
        }

        It 'Exits with a runtime error when restore operations fail' {
            $content = Get-Content -LiteralPath $script:TaskParityScript -Raw
            $content | Should -Match 'restoreErrors'
            $content | Should -Match 'EXIT_RUNTIME_ERROR'
        }

        It 'Restores the latest task-parity backup for a selected task file' {
            $repo = New-TestTempDirectory -Prefix 'TaskParityRestore'
            $taskFile = Join-Path $repo 'Taskfile.yml'
            Set-Content -LiteralPath $taskFile -Value 'version: "3"' -NoNewline
            New-FileBackup -SourcePath $taskFile -RepoRoot $repo -Category 'task-parity' -SkipPrune | Out-Null
            Set-Content -LiteralPath $taskFile -Value 'version: "9"' -NoNewline

            $result = Invoke-BackupTestScript -ScriptPath $script:TaskParityScript -ArgumentList @(
                '-Restore', '-TargetFile', 'taskfile', '-RepoRoot', $repo, '-Force'
            )
            $result.ExitCode | Should -Be 0
            Get-Content -LiteralPath $taskFile -Raw | Should -Be 'version: "3"'
        }

        It 'Prunes older task-parity backups for a selected task file' {
            $repo = New-TestTempDirectory -Prefix 'TaskParityPrune'
            $taskFile = Join-Path $repo 'Makefile'

            1..3 | ForEach-Object {
                Set-Content -LiteralPath $taskFile -Value "target-$_" -NoNewline
                New-FileBackup -SourcePath $taskFile -RepoRoot $repo -Category 'task-parity' -SkipPrune | Out-Null
                Start-Sleep -Milliseconds 20
            }

            $result = Invoke-BackupTestScript -ScriptPath $script:TaskParityScript -ArgumentList @(
                '-Prune', '-TargetFile', 'makefile', '-RepoRoot', $repo, '-KeepCount', '1'
            )
            $result.ExitCode | Should -Be 0

            @(Get-FileBackups -RepoRoot $repo -Category 'task-parity' -SourcePath $taskFile).Count | Should -Be 1
        }

        It 'Returns a runtime error when restoring without stored backups' {
            $repo = New-TestTempDirectory -Prefix 'TaskParityRestoreMissing'
            $taskFile = Join-Path $repo 'Taskfile.yml'
            Set-Content -LiteralPath $taskFile -Value 'live-content' -NoNewline

            $result = Invoke-BackupTestScript -ScriptPath $script:TaskParityScript -ArgumentList @(
                '-Restore',
                '-TargetFile', 'taskfile',
                '-RepoRoot', $repo,
                '-Force'
            )
            $result.ExitCode | Should -Be 3
        }

        It 'Restores latest backups for all task files when TargetFile is all' {
            $repo = New-TestTempDirectory -Prefix 'TaskParityRestoreAll'
            $taskFiles = @{
                Taskfile = Join-Path $repo 'Taskfile.yml'
                Makefile = Join-Path $repo 'Makefile'
                Package  = Join-Path $repo 'package.json'
                Justfile = Join-Path $repo 'justfile'
                Tasks    = Join-Path $repo '.vscode' 'tasks.json'
            }

            $null = New-Item -ItemType Directory -Path (Join-Path $repo '.vscode') -Force
            foreach ($entry in $taskFiles.GetEnumerator()) {
                Set-Content -LiteralPath $entry.Value -Value "$($entry.Key)-original" -NoNewline
                New-FileBackup -SourcePath $entry.Value -RepoRoot $repo -Category 'task-parity' -SkipPrune | Out-Null
                Set-Content -LiteralPath $entry.Value -Value "$($entry.Key)-changed" -NoNewline
            }

            $result = Invoke-BackupTestScript -ScriptPath $script:TaskParityScript -ArgumentList @(
                '-Restore', '-TargetFile', 'all', '-RepoRoot', $repo, '-Force'
            )
            $result.ExitCode | Should -Be 0
            foreach ($entry in $taskFiles.GetEnumerator()) {
                Get-Content -LiteralPath $entry.Value -Raw | Should -Be "$($entry.Key)-original"
            }
        }
    }
}
