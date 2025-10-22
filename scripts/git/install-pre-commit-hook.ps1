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
# pre-commit hook to validate PowerShell profile
pwsh -NoProfile -File "scripts/checks/validate-profile.ps1"
if ($LASTEXITCODE -ne 0) { Write-Host 'Pre-commit: validation failed' ; exit 1 }
exit 0
'@

Set-Content -LiteralPath $hookPath -Value $script -NoNewline -Force
# Make executable on supported systems (Git for Windows respects the hook file, Unix needs +x)
try { icacls $hookPath /grant Everyone:RX *>&1 | Out-Null } catch { }
Write-Output "Installed pre-commit hook at $hookPath"
