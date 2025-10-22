param([string]$Path)
if (-not $Path) { Write-Error 'Usage: print_with_lines.ps1 <path>'; exit 1 }
$i=1
Get-Content -Path $Path | ForEach-Object { '{0,4}: {1}' -f $i, $_; $i++ }