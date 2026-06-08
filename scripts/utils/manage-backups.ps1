<#
.SYNOPSIS
    Lists, restores, and prunes repository file backups.

.DESCRIPTION
    Operates on backups created by scripts via FileBackup.psm1 under the gitignored
    .backups directory at the repository root.

.PARAMETER Action
    Action to perform: List, Restore, or Prune.

.PARAMETER Category
    Backup category (for example task-parity or git-hooks).

.PARAMETER SourcePath
    Source file path used when the backup was created.

.PARAMETER BackupPath
    Explicit backup file path for restore.

.PARAMETER Latest
    Restore the newest backup for the given category and source path.

.PARAMETER KeepCount
    Number of newest backups to retain per source file when pruning.

.PARAMETER MaxAgeDays
    Remove backups older than this many days when pruning.

.PARAMETER Force
    Overwrite the destination file when restoring.

.PARAMETER RepoRoot
    Repository root directory. Auto-detected from the script location when omitted.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/manage-backups.ps1 -Action List -Category task-parity

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/manage-backups.ps1 -Action Restore -Category git-hooks -SourcePath .git/hooks/pre-commit -Latest

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/manage-backups.ps1 -Action Prune -Category task-parity -KeepCount 5
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('List', 'Restore', 'Prune')]
    [string]$Action,

    [string]$Category,

    [string]$SourcePath,

    [string]$BackupPath,

    [int]$KeepCount = 10,

    [int]$MaxAgeDays = 0,

    [switch]$Latest,

    [switch]$Force,

    [string]$RepoRoot
)

$moduleImportPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'FileBackup' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

if (-not $RepoRoot) {
    $RepoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}

switch ($Action) {
    'List' {
        $backups = @(Get-FileBackups -RepoRoot $RepoRoot -Category $Category -SourcePath $SourcePath)
        if ($backups.Count -eq 0) {
            Write-Host 'No backups found.' -ForegroundColor Yellow
            Exit-WithCode -ExitCode $EXIT_SUCCESS
        }

        $backups | Format-Table Category, SourcePath, CreatedAt, BackupPath -AutoSize
        Exit-WithCode -ExitCode $EXIT_SUCCESS
    }

    'Restore' {
        if (-not $BackupPath -and (-not $Latest -or -not $SourcePath -or -not $Category)) {
            Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message 'Restore requires -BackupPath or -Latest with -Category and -SourcePath.'
        }

        try {
            $restoredPath = Restore-FileBackup -RepoRoot $RepoRoot -BackupPath $BackupPath -Category $Category -SourcePath $SourcePath -Latest:$Latest -Force:$Force
            Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Restored backup to $restoredPath"
        }
        catch {
            Exit-WithCode -ExitCode $EXIT_RUNTIME_ERROR -Message $_.Exception.Message
        }
    }

    'Prune' {
        if ($KeepCount -le 0 -and $MaxAgeDays -le 0) {
            Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message 'Prune requires -KeepCount and/or -MaxAgeDays greater than zero.'
        }

        try {
            $removed = Remove-OldFileBackups -RepoRoot $RepoRoot -Category $Category -SourcePath $SourcePath -KeepCount $KeepCount -MaxAgeDays $MaxAgeDays
            Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Removed $removed backup(s)"
        }
        catch {
            Exit-WithCode -ExitCode $EXIT_RUNTIME_ERROR -Message $_.Exception.Message
        }
    }
}
