# Idempotency checker for profile.d fragments
$profileD = 'c:\Users\bolen\Documents\PowerShell\profile.d'

Write-Output "Building temporary idempotency runner..."
$files = Get-ChildItem -Path $profileD -Filter '*.ps1' | Sort-Object Name | ForEach-Object { $_.FullName }
if ($files.Count -eq 0) { Write-Error "No fragments found in $profileD"; exit 2 }

$temp = [IO.Path]::Combine($env:TEMP, [IO.Path]::GetRandomFileName() + '.ps1')

$content = @()
$content += "# Auto-generated idempotency runner"
$content += "`$ErrorActionPreference = 'Stop'"
$content += "Write-Output 'Idempotency runner starting: dot-sourcing all fragments in order (pass 1)...'"
foreach ($f in $files) { $content += ". '$f'" }
$content += "Write-Output 'Pass 1 complete'"
$content += "Write-Output 'Pass 2 starting: dot-sourcing all fragments in order (pass 2)...'"
foreach ($f in $files) { $content += ". '$f'" }
$content += "Write-Output 'Pass 2 complete'"

[System.IO.File]::WriteAllLines($temp, $content)

Write-Output "Running idempotency runner: $temp"
$out = pwsh -NoProfile -File $temp 2>&1
$code = $LASTEXITCODE

Remove-Item -LiteralPath $temp -ErrorAction SilentlyContinue

if ($code -ne 0) {
    Write-Output $out
    Write-Error "Idempotency runner failed (exit code $code)"
    exit $code
}

Write-Output "Idempotency: all profile.d fragments loaded twice without errors"
exit 0
