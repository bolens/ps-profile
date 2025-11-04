# Scans profile.d for functions and prints ones defined in multiple files
$root = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$profileDir = Join-Path $root 'profile.d'
if (-not (Test-Path $profileDir)) { Write-Error "profile.d not found at $profileDir"; exit 2 }
$files = Get-ChildItem -Path $profileDir -Filter '*.ps1' -File
$found = @()
$regex = [regex]"function\s+([A-Za-z0-9_-]+)\s*\{"
foreach ($f in $files) {
    $content = Get-Content -Raw -Path $f.FullName
    foreach ($m in $regex.Matches($content)) {
        $found += [PSCustomObject]@{ File = $f.FullName; Name = $m.Groups[1].Value }
    }
}
$groups = $found | Group-Object Name | Where-Object { $_.Count -gt 1 }
if ($groups.Count -eq 0) { Write-Output 'No duplicate function definitions found in profile.d'; exit 0 }
foreach ($g in $groups) {
    Write-Output "Function: $($g.Name)"
    $g.Group | ForEach-Object { Write-Output "  - $($_.File)" }
    Write-Output ''
}
