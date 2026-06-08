<#
tests/unit/utility-backup-workflow.tests.ps1

.SYNOPSIS
    End-to-end workflow tests across FileBackup.psm1 and manage-backups.ps1.
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

Describe 'Repository backup workflow' {
    It 'Creates, lists, restores, and prunes backups through the shared stack' {
        $repo = New-TestTempDirectory -Prefix 'BackupWorkflow'
        $source = Join-Path $repo 'workflow.txt'
        Set-Content -LiteralPath $source -Value 'workflow-v1' -NoNewline
        New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'workflow' -SkipPrune | Out-Null
        Set-Content -LiteralPath $source -Value 'workflow-v2' -NoNewline
        New-FileBackup -SourcePath $source -RepoRoot $repo -Category 'workflow' -SkipPrune | Out-Null
        Set-Content -LiteralPath $source -Value 'workflow-live' -NoNewline

        $listResult = Invoke-BackupTestScript -ScriptPath $script:ManageBackupsScript -ArgumentList @(
            '-Action', 'List',
            '-RepoRoot', $repo,
            '-Category', 'workflow',
            '-SourcePath', $source
        )
        $listResult.ExitCode | Should -Be 0
        $listResult.Output | Should -Match 'workflow'

        $restoreResult = Invoke-BackupTestScript -ScriptPath $script:ManageBackupsScript -ArgumentList @(
            '-Action', 'Restore',
            '-RepoRoot', $repo,
            '-Category', 'workflow',
            '-SourcePath', $source,
            '-Latest',
            '-Force'
        )
        $restoreResult.ExitCode | Should -Be 0
        $restoreResult.Output | Should -Match 'Restored backup to'
        Get-Content -LiteralPath $source -Raw | Should -Be 'workflow-v2'

        $pruneResult = Invoke-BackupTestScript -ScriptPath $script:ManageBackupsScript -ArgumentList @(
            '-Action', 'Prune',
            '-RepoRoot', $repo,
            '-Category', 'workflow',
            '-KeepCount', '1'
        )
        $pruneResult.ExitCode | Should -Be 0
        $pruneResult.Output | Should -Match 'Removed'
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
}
