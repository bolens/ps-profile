<#
tests/unit/utility-check-task-parity-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for check-task-parity.ps1 task runner parity checker.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

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

        It 'Restores the latest task-parity backup for a selected task file' {
            $repo = New-TestTempDirectory -Prefix 'TaskParityRestore'
            $taskFile = Join-Path $repo 'Taskfile.yml'
            Set-Content -LiteralPath $taskFile -Value 'version: "3"' -NoNewline
            New-FileBackup -SourcePath $taskFile -RepoRoot $repo -Category 'task-parity' -SkipPrune | Out-Null
            Set-Content -LiteralPath $taskFile -Value 'version: "9"' -NoNewline

            & pwsh -NoProfile -File $script:TaskParityScript -Restore -TargetFile 'taskfile' -RepoRoot $repo -Force 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
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

            & pwsh -NoProfile -File $script:TaskParityScript -Prune -TargetFile 'makefile' -RepoRoot $repo -KeepCount 1 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0

            $remaining = @(Get-FileBackups -RepoRoot $repo -Category 'task-parity' -SourcePath $taskFile)
            $remaining.Count | Should -Be 1
        }
    }
}
