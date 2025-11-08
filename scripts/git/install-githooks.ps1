<#
scripts/git/install-githooks.ps1

.SYNOPSIS
    Installs git hooks by copying PowerShell hook scripts into .git/hooks.

.DESCRIPTION
    Copy PowerShell hook scripts from scripts/git/hooks into .git/hooks as lightweight
    wrappers that invoke pwsh. Intended for Windows developers using PowerShell.
    Creates wrapper scripts that ensure hooks are executed with pwsh.

.PARAMETER GitDir
    The git directory path. Defaults to '.git'.

.EXAMPLE
    pwsh -NoProfile -File scripts\git\install-githooks.ps1

    Installs git hooks in the default .git directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\git\install-githooks.ps1 -GitDir '.git-custom'

    Installs git hooks in a custom git directory.
#>

param(
    [string]$GitDir = '.git'
)

# Import shared utilities
$scriptsDir = Split-Path -Parent $PSScriptRoot
$commonModulePath = Join-Path $scriptsDir 'utils' 'Common.psm1'
if (-not (Test-Path $commonModulePath)) {
    throw "Common module not found at: $commonModulePath. PSScriptRoot: $PSScriptRoot"
}
$commonModulePath = (Resolve-Path $commonModulePath).Path
Import-Module $commonModulePath -ErrorAction Stop

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$gitHooksDir = Join-Path $repoRoot $GitDir
if (-not (Test-Path $gitHooksDir)) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Git hooks directory '$gitHooksDir' not found. Run this from the repo root."
}

$srcHooks = Join-Path $repoRoot 'scripts' 'git' 'hooks'
if (-not (Test-Path $srcHooks)) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Source hooks directory not found: $srcHooks"
}

$hookFiles = Get-ChildItem -Path $srcHooks -Filter '*.ps1' -File
foreach ($hf in $hookFiles) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($hf.Name)
    $target = Join-Path $gitHooksDir $name


    # Create a small wrapper script that executes pwsh pointing at the repo script
    $hookScriptPath = (Join-Path $repoRoot "scripts\git\hooks\$($hf.Name)")
    $wrapperContent = "#!/usr/bin/env pwsh`n`$scriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Definition`n& pwsh -NoProfile -File `"$hookScriptPath`" @args`nexit `$LASTEXITCODE`n"

    Write-ScriptMessage -Message "Installing hook: $name -> $target"
    Set-Content -LiteralPath $target -Value $wrapperContent -Encoding UTF8

    # Try to make the wrapper executable on Unix-like systems if chmod exists
    try {
        if (Test-CommandAvailable -CommandName 'chmod') {
            & chmod +x $target
            Write-ScriptMessage -Message "Set executable bit on $target"
        }
        else {
            # On Windows, try to grant read+execute to the current user (best-effort)
            try { icacls $target /grant "$($env:USERNAME):RX" > $null 2>&1 } catch { }
        }
    }
    catch {
        # Non-fatal
    }
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Git hooks installed. Ensure .git/hooks/* are executable if using a Unix-like environment."
