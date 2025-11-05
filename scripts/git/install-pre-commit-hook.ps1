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

.EXAMPLE
    pwsh -NoProfile -File scripts\git\install-pre-commit-hook.ps1

    Installs the pre-commit hook in the current repository.

.EXAMPLE
    pwsh -NoProfile -File scripts\git\install-pre-commit-hook.ps1 -RepoRoot C:\MyRepo

    Installs the pre-commit hook in the specified repository.
#>

param(
    [string]$RepoRoot = (Get-Location).Path
)

$hookPath = Join-Path $RepoRoot '.git\hooks\pre-commit'
if (-not (Test-Path -Path (Join-Path $RepoRoot '.git') -PathType Container -ErrorAction SilentlyContinue)) {
    Write-Error 'No .git directory found. Run this from the repository root.'
    exit 2
}

if (Test-Path $hookPath) {
    $bak = $hookPath + '.' + (Get-Date -Format 'yyyyMMddHHmmss') + '.bak'
    Write-Output "Backing up existing hook to $bak"
    Copy-Item $hookPath $bak -Force
}

$script = @'
#!/usr/bin/env pwsh
# pre-commit hook to format and validate PowerShell profile
pwsh -NoProfile -File "scripts/git/pre-commit.ps1"
if ($LASTEXITCODE -ne 0) { Write-Host 'Pre-commit: checks failed' ; exit 1 }
exit 0
'@

Set-Content -LiteralPath $hookPath -Value $script -NoNewline -Force
# Make executable on supported systems (Git for Windows respects the hook file, Unix needs +x)
try { icacls $hookPath /grant Everyone:RX *>&1 | Out-Null } catch { }
Write-Output "Installed pre-commit hook at $hookPath"
