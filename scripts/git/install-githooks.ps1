<#
scripts/install-githooks.ps1

Copy PowerShell hook scripts from scripts/hooks into .git/hooks as lightweight
wrappers that invoke pwsh. Intended for Windows developers using PowerShell.

Usage: pwsh -NoProfile -File scripts\install-githooks.ps1
#>

param(
    [string]$GitDir = '.git'
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Split-Path -Parent $scriptDir
$gitHooksDir = Join-Path $repoRoot $GitDir
if (-not (Test-Path $gitHooksDir)) {
    Write-Error "Git hooks directory '$gitHooksDir' not found. Run this from the repo root."
    exit 2
}

$srcHooks = Join-Path $repoRoot 'scripts\hooks'
if (-not (Test-Path $srcHooks)) { Write-Error "Source hooks directory not found: $srcHooks"; exit 2 }

$hookFiles = Get-ChildItem -Path $srcHooks -Filter '*.ps1' -File
foreach ($hf in $hookFiles) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($hf.Name)
    $target = Join-Path $gitHooksDir $name


    # Create a small wrapper script that executes pwsh pointing at the repo script
    $hookScriptPath = (Join-Path $repoRoot "scripts\hooks\$($hf.Name)")
    $wrapperContent = "#!/usr/bin/env pwsh`n`$scriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Definition`n& pwsh -NoProfile -File `"$hookScriptPath`" @args`nexit `$LASTEXITCODE`n"

    Write-Output "Installing hook: $name -> $target"
    Set-Content -LiteralPath $target -Value $wrapperContent -Encoding UTF8

    # Try to make the wrapper executable on Unix-like systems if chmod exists
    try {
        if (Get-Command chmod -ErrorAction SilentlyContinue) {
            & chmod +x $target
            Write-Output "Set executable bit on $target"
        } else {
            # On Windows, try to grant read+execute to the current user (best-effort)
            try { icacls $target /grant "$($env:USERNAME):RX" > $null 2>&1 } catch { }
        }
    } catch {
        # Non-fatal
    }
}

Write-Output "Git hooks installed. Ensure .git/hooks/* are executable if using a Unix-like environment."
exit 0
