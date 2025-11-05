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

# Idempotency checker for profile.d fragments
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
$profileD = Join-Path $repoRoot 'profile.d'

Write-Output "Building temporary idempotency runner..."
$files = Get-ChildItem -Path $profileD -Filter '*.ps1' | Sort-Object Name | ForEach-Object { $_.FullName }
if ($files.Count -eq 0) { Write-Error "No fragments found in $profileD"; exit 2 }

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
$psExe = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }

Write-Output "Running idempotency runner: $temp"
$out = & $psExe -NoProfile -File $temp 2>&1
$code = $LASTEXITCODE

Remove-Item -LiteralPath $temp -ErrorAction SilentlyContinue

if ($code -ne 0) {
    Write-Output $out
    Write-Error "Idempotency runner failed (exit code $code)"
    exit $code
}

Write-Output "Idempotency: all profile.d fragments loaded twice without errors"
exit 0
