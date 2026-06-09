<#
tests/unit/utility-backup-workflow.tests.ps1

.SYNOPSIS
    End-to-end workflow tests for FileBackup.psm1 list, restore, and prune operations.
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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'file' 'FileBackup.psm1') -DisableNameChecking -ErrorAction Stop
    $ConfirmPreference = 'None'
}

Describe 'Repository backup workflow' {
    It 'Creates, lists, restores, and prunes backups through FileBackup module functions' {
        $repo = New-TestTempDirectory -Prefix 'BackupWorkflow'
        $source = Join-Path $repo 'workflow.txt'
        Set-Content -LiteralPath $source -Value 'workflow-v1' -NoNewline
        New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'workflow' -SkipPrune | Out-Null
        Set-Content -LiteralPath $source -Value 'workflow-v2' -NoNewline
        New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'workflow' -SkipPrune | Out-Null
        Set-Content -LiteralPath $source -Value 'workflow-live' -NoNewline

        $listed = @(Get-FileBackups -RepoRoot $repo -Category 'workflow' -SourcePath $source)
        $listed.Count | Should -Be 2
        $listed[0].SourcePath | Should -Match 'workflow\.txt'

        Restore-FileBackup -RepoRoot $repo -Category 'workflow' -SourcePath $source -Latest -Force | Out-Null
        Get-Content -LiteralPath $source -Raw | Should -Be 'workflow-v2'

        $removed = Remove-OldFileBackups -RepoRoot $repo -Category 'workflow' -KeepCount 1
        $removed | Should -BeGreaterOrEqual 1
        @(Get-FileBackups -RepoRoot $repo -Category 'workflow' -SourcePath $source).Count | Should -Be 1
    }

    It 'Keeps backups under .backups and outside the tracked repository tree' {
        $repo = New-TestTempDirectory -Prefix 'BackupWorkflowPath'
        $source = Join-Path $repo 'tracked.txt'
        Set-Content -LiteralPath $source -Value 'tracked' -NoNewline
        $backup = New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'workflow-path' -SkipPrune

        $backup.BackupPath | Should -Match ([regex]::Escape((Join-Path $repo '.backups' 'workflow-path')))
        Test-Path -LiteralPath (Join-Path $repo '.backups') | Should -Be $true
        Test-Path -LiteralPath $source | Should -Be $true
        Get-ChildItem -LiteralPath $repo -File | ForEach-Object { $_.Name | Should -Not -Match '\.backup\.' }
    }

    It 'Prunes all backups in a category when SourcePath is omitted' {
        $repo = New-TestTempDirectory -Prefix 'BackupWorkflowCategoryPrune'
        $first = Join-Path $repo 'first.txt'
        $second = Join-Path $repo 'second.txt'

        1..2 | ForEach-Object {
            Set-Content -LiteralPath $first -Value "first-$_" -NoNewline
            New-FileBackup -SourcePath $first -RepoRoot $repo -Category 'workflow-prune-all' -SkipPrune | Out-Null
            Start-Sleep -Milliseconds 20
        }
        Set-Content -LiteralPath $second -Value 'second-v1' -NoNewline
        New-FileBackup -SourcePath $second -RepoRoot $repo -Category 'workflow-prune-all' -SkipPrune | Out-Null

        Remove-OldFileBackups -RepoRoot $repo -Category 'workflow-prune-all' -KeepCount 1 | Out-Null

        @(Get-FileBackups -RepoRoot $repo -Category 'workflow-prune-all' -SourcePath $first).Count | Should -Be 1
        @(Get-FileBackups -RepoRoot $repo -Category 'workflow-prune-all' -SourcePath $second).Count | Should -Be 1
    }
}
