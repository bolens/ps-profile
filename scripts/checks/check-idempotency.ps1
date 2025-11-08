<#
scripts/checks/check-idempotency.ps1

.SYNOPSIS
    Checks that profile.d fragments can be dot-sourced multiple times without errors.

.DESCRIPTION
    Idempotency checker for profile.d fragments. Creates a temporary script that
    dot-sources all profile.d fragments twice in sequence to verify they can be
    loaded multiple times without errors. This ensures fragments are idempotent
    and safe to reload.

.EXAMPLE
    pwsh -NoProfile -File scripts\checks\check-idempotency.ps1

    Checks that all profile.d fragments can be loaded twice without errors.
#>

# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'utils' 'Common.psm1'
Import-Module $commonModulePath -ErrorAction Stop

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $profileD = Join-Path $repoRoot 'profile.d'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Write-ScriptMessage -Message "Building temporary idempotency runner..."
$files = Get-ChildItem -Path $profileD -Filter '*.ps1' | Sort-Object Name | ForEach-Object { $_.FullName }
if ($files.Count -eq 0) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "No fragments found in $profileD"
}

$temp = [IO.Path]::Combine($env:TEMP, [IO.Path]::GetRandomFileName() + '.ps1')

# Use List for better performance than array concatenation
$content = [System.Collections.Generic.List[string]]::new()
$content.Add("# Auto-generated idempotency runner")
$content.Add("`$ErrorActionPreference = 'Stop'")
$content.Add("Write-Output 'Idempotency runner starting: dot-sourcing all fragments in order (pass 1)...'")
foreach ($f in $files) { $content.Add(". '$f'") }
$content.Add("Write-Output 'Pass 1 complete'")
$content.Add("Write-Output 'Pass 2 starting: dot-sourcing all fragments in order (pass 2)...'")
foreach ($f in $files) { $content.Add(". '$f'") }
$content.Add("Write-Output 'Pass 2 complete'")

[System.IO.File]::WriteAllLines($temp, $content)

# Determine which PowerShell executable to use
$psExe = Get-PowerShellExecutable

Write-ScriptMessage -Message "Running idempotency runner: $temp"
$out = & $psExe -NoProfile -File $temp 2>&1
$code = $LASTEXITCODE

Remove-Item -LiteralPath $temp -ErrorAction SilentlyContinue

if ($code -ne 0) {
    Write-ScriptMessage -Message $out
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Idempotency runner failed (exit code $code)"
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Idempotency: all profile.d fragments loaded twice without errors"
