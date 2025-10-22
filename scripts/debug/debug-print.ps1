$i = 1
Get-Content -LiteralPath '.\generate-fragment-readmes.ps1' | ForEach-Object { Write-Output ("{0:D3}: {1}" -f $i, $_); $i++ }