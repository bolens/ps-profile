# ===============================================
# TestBackup.ps1
# Shared helpers for FileBackup module and backup CLI scripts
# ===============================================

<#
.SYNOPSIS
    Runs a backup-related script in a child process with real exit codes.
.DESCRIPTION
    Clears PS_PROFILE_TEST_MODE for the child invocation so Exit-WithCode uses
    process exit codes instead of throwing in test mode.
#>
function Invoke-BackupTestScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [string[]]$ArgumentList = @()
    )

    return Invoke-TestScriptFile -ScriptPath $ScriptPath `
        -ArgumentList $ArgumentList `
        -EnvironmentVariables @{ PS_PROFILE_TEST_MODE = '' }
}

<#
.SYNOPSIS
    Creates a minimal git repository fixture for pre-commit hook tests.
#>
function New-TestGitRepositoryWithHook {
    [CmdletBinding()]
    param(
        [string]$HookContent = '# existing hook',

        [switch]$IncludeExistingHook
    )

    $repo = New-TestTempDirectory -Prefix 'BackupGitRepo'
    $hooksDir = Join-Path $repo '.git' 'hooks'
    $scriptsGitDir = Join-Path $repo 'scripts' 'git'

    $null = New-Item -ItemType Directory -Path $hooksDir -Force
    $null = New-Item -ItemType Directory -Path $scriptsGitDir -Force

    $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts' 'git' 'pre-commit.ps1') `
        -Destination (Join-Path $scriptsGitDir 'pre-commit.ps1') -Force

    $hookPath = Join-Path $hooksDir 'pre-commit'
    if ($IncludeExistingHook -or $PSBoundParameters.ContainsKey('HookContent')) {
        Set-Content -LiteralPath $hookPath -Value $HookContent -NoNewline
    }

    return [pscustomobject]@{
        RepoRoot = $repo
        HookPath = $hookPath
    }
}
