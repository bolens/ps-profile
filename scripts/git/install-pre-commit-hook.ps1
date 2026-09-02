<#
scripts/git/install-pre-commit-hook.ps1

.SYNOPSIS
    Installs the pre-commit git hook.

.DESCRIPTION
    Installs a pre-commit git hook that runs formatting and validation checks before commits.
    Backs up any existing hook with a timestamp. The hook runs scripts/git/pre-commit.ps1
    which formats code first, then runs validate-profile.ps1 to ensure code quality.

.PARAMETER RepoRoot
    The root directory of the git repository. Defaults to the current directory.

.PARAMETER Restore
    Restores the most recent pre-commit hook backup from .backups/git-hooks.

.PARAMETER Prune
    Prunes old pre-commit hook backups, keeping the newest backups per -KeepCount.

.PARAMETER KeepCount
    Number of hook backups to retain when pruning. Defaults to 10.

.PARAMETER Force
    Overwrite the existing hook when restoring.

.PARAMETER PassThru
    Returns an exit result instead of terminating the current process.

.EXAMPLE
    pwsh -NoProfile -File scripts\git\install-pre-commit-hook.ps1

    Installs the pre-commit hook in the current repository.

.EXAMPLE
    pwsh -NoProfile -File scripts/git/install-pre-commit-hook.ps1 -RepoRoot /path/to/repo

    Installs the pre-commit hook in the specified repository.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$RepoRoot = $null,

    [switch]$Restore,

    [switch]$Prune,

    [int]$KeepCount = 10,

    [switch]$Force,

    [scriptblock]$PlatformTestAction = { Test-IsWindows },

    [scriptblock]$CommandTestAction = {
        param($CommandName)
        Test-CommandAvailable -CommandName $CommandName
    },

    [scriptblock]$PowerShellExecutableAction = { Get-PowerShellExecutable },

    [switch]$PassThru
)

# Import ModuleImport first (bootstrap)
$scriptsDir = Split-Path -Parent $PSScriptRoot
$moduleImportPath = Join-Path $scriptsDir 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PowerShellDetection' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Platform' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Command' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'FileBackup' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

function Complete-HookInstallation {
    param(
        [Parameter(Mandatory)]
        [int]$ExitCode,

        [string]$Message,

        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    if ($PassThru) {
        [PSCustomObject]@{
            ExitCode    = $ExitCode
            Message     = $Message
            ErrorRecord = $ErrorRecord
        }
        return
    }

    Exit-WithCode -ExitCode $ExitCode -Message $Message -ErrorRecord $ErrorRecord
}

# Get repository root if not specified
if (-not $RepoRoot) {
    try {
        $RepoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    }
    catch {
        Complete-HookInstallation -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
        return
    }
}

$hooksDir = (& git -C $RepoRoot rev-parse --git-path hooks).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($hooksDir)) {
    Complete-HookInstallation -ExitCode $EXIT_SETUP_ERROR -Message 'Unable to resolve the Git hooks directory.'
    return
}
$hookPath = Join-Path $hooksDir 'pre-commit'

if ($Restore) {
    try {
        $restoredPath = Restore-FileBackup -RepoRoot $RepoRoot -Category 'git-hooks' -SourcePath $hookPath -Latest -Force:$Force
        Complete-HookInstallation -ExitCode $EXIT_SUCCESS -Message "Restored pre-commit hook from backup to $restoredPath"
        return
    }
    catch {
        Complete-HookInstallation -ExitCode $EXIT_RUNTIME_ERROR -Message $_.Exception.Message
        return
    }
}

if ($Prune) {
    try {
        $removed = Remove-OldFileBackups -RepoRoot $RepoRoot -Category 'git-hooks' -SourcePath $hookPath -KeepCount $KeepCount
        Complete-HookInstallation -ExitCode $EXIT_SUCCESS -Message "Pruned $removed pre-commit hook backup(s)"
        return
    }
    catch {
        Complete-HookInstallation -ExitCode $EXIT_RUNTIME_ERROR -Message $_.Exception.Message
        return
    }
}

if ($hookPath -and -not [string]::IsNullOrWhiteSpace($hookPath) -and (Test-Path -LiteralPath $hookPath)) {
    $backup = New-FileBackup -SourcePath $hookPath -RepoRoot $RepoRoot -Category 'git-hooks' -KeepCount $KeepCount
    Write-ScriptMessage -Message "Backing up existing hook to $($backup.BackupPath)"
}

$psExe = & $PowerShellExecutableAction
$preCommitScript = Join-Path $RepoRoot 'scripts' 'git' 'pre-commit.ps1'
$psExeLiteral = $psExe -replace "'", "''"
$preCommitLiteral = $preCommitScript -replace "'", "''"
if (& $PlatformTestAction) {
    $script = @"
#!/usr/bin/env pwsh
# pre-commit hook to format and validate PowerShell profile
& '$psExeLiteral' -NoProfile -File '$preCommitLiteral'
if (`$LASTEXITCODE -ne 0) {
    Write-Host 'Pre-commit: checks failed'
    exit 1
}
exit 0
"@
}
else {
    $script = @"
#!/bin/sh
# pre-commit hook to format and validate PowerShell profile
'$psExeLiteral' -NoProfile -File '$preCommitLiteral'
status=`$?
if [ `$status -ne 0 ]; then
  echo 'Pre-commit: checks failed'
  exit 1
fi
exit 0
"@
}

Set-Content -LiteralPath $hookPath -Value $script -NoNewline -Force
# Make executable on supported systems (Git for Windows respects the hook file, Unix needs +x)
try {
    if (& $PlatformTestAction) {
        # On Windows, try to grant read+execute permissions using icacls (best-effort)
        if (& $CommandTestAction -CommandName 'icacls') {
            icacls $hookPath /grant Everyone:RX *>&1 | Out-Null
        }
    }
    else {
        # On Unix-like systems, use chmod to set executable bit
        if (& $CommandTestAction -CommandName 'chmod') {
            & chmod +x $hookPath
        }
    }
}
catch {
    # Non-fatal - permissions may not be critical on all systems
}

Complete-HookInstallation -ExitCode $EXIT_SUCCESS -Message "Installed pre-commit hook at $hookPath"
