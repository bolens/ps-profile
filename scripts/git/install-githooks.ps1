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

.PARAMETER DryRun
    If specified, shows what hooks would be installed without actually installing them.

.EXAMPLE
    pwsh -NoProfile -File scripts\git\install-githooks.ps1

    Installs git hooks in the default .git directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\git\install-githooks.ps1 -GitDir '.git-custom'

    Installs git hooks in a custom git directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\git\install-githooks.ps1 -DryRun

    Shows what hooks would be installed without actually installing them.
#>

param(
    [string]$GitDir = '.git',

    [switch]$DryRun
)

# Import ModuleImport first (bootstrap)
$scriptsDir = Split-Path -Parent $PSScriptRoot
$moduleImportPath = Join-Path $scriptsDir 'lib' 'ModuleImport.psm1'
if ($moduleImportPath -and -not [string]::IsNullOrWhiteSpace($moduleImportPath) -and -not (Test-Path -LiteralPath $moduleImportPath)) {
    throw "ModuleImport module not found at: $moduleImportPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PowerShellDetection' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Platform' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Command' -ScriptPath $PSScriptRoot -DisableNameChecking

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

$gitHooksDir = Join-Path $repoRoot $GitDir
if ($gitHooksDir -and -not [string]::IsNullOrWhiteSpace($gitHooksDir) -and -not (Test-Path -LiteralPath $gitHooksDir)) {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Git hooks directory '$gitHooksDir' not found. Run this from the repo root."
}

$srcHooks = Join-Path $repoRoot 'scripts' 'git' 'hooks'
if ($srcHooks -and -not [string]::IsNullOrWhiteSpace($srcHooks) -and -not (Test-Path -LiteralPath $srcHooks)) {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Source hooks directory not found: $srcHooks"
}

$hookFiles = Get-ChildItem -Path $srcHooks -Filter '*.ps1' -File

if ($DryRun) {
    Write-ScriptMessage -Message "DRY RUN MODE: Would install $($hookFiles.Count) hook(s)..." -ForegroundColor Yellow
}

foreach ($hf in $hookFiles) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($hf.Name)
    $target = Join-Path $gitHooksDir $name

    # Create a small wrapper script that executes PowerShell pointing at the repo script
    # Use Get-PowerShellExecutable for cross-platform compatibility
    $psExe = Get-PowerShellExecutable
    $hookScriptPath = Join-Path $repoRoot (Join-Path 'scripts' (Join-Path 'git' (Join-Path 'hooks' $hf.Name)))
    $wrapperContent = "#!/usr/bin/env $psExe`n`$scriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Definition`n& $psExe -NoProfile -File `"$hookScriptPath`" @args`nexit `$LASTEXITCODE`n"

    if ($DryRun) {
        Write-ScriptMessage -Message "[DRY RUN] Would install hook: $name -> $target" -ForegroundColor Yellow
    }
    else {
        Write-ScriptMessage -Message "Installing hook: $name -> $target"
        Set-Content -LiteralPath $target -Value $wrapperContent -Encoding UTF8

        # Try to make the wrapper executable on supported systems
        try {
            if (Test-IsWindows) {
                # On Windows, try to grant read+execute permissions using icacls (best-effort)
                if (Test-CommandAvailable -CommandName 'icacls') {
                    try { 
                        icacls $target /grant "$($env:USERNAME):RX" > $null 2>&1 
                    } 
                    catch { 
                        # Non-fatal - permissions may not be critical
                    }
                }
            }
            else {
                # On Unix-like systems, use chmod to set executable bit
                if (Test-CommandAvailable -CommandName 'chmod') {
                    & chmod +x $target
                    Write-ScriptMessage -Message "Set executable bit on $target"
                }
            }
        }
        catch {
            # Non-fatal - permissions may not be critical on all systems
        }
    }
}

if ($DryRun) {
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "DRY RUN: Would install $($hookFiles.Count) hook(s). Run without -DryRun to apply changes."
}
else {
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "Git hooks installed. Ensure .git/hooks/* are executable if using a Unix-like environment."
}
