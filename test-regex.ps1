# Test regex patterns for command parsing
$filePath = 'profile.d\scoop.ps1'
$content = Get-Content $filePath -Raw

Write-Host "Testing regex patterns on: $filePath" -ForegroundColor Cyan
Write-Host "Content length: $($content.Length) characters" -ForegroundColor Gray
Write-Host ""

# Test function pattern
$functionPattern = "Set-AgentModeFunction\s+-Name\s+['""]([A-Za-z0-9_\-]+)['""]"
$functionMatches = [regex]::Matches($content, $functionPattern)
Write-Host "Function pattern: $functionPattern" -ForegroundColor Yellow
Write-Host "Found $($functionMatches.Count) function matches:" -ForegroundColor $(if ($functionMatches.Count -gt 0) { 'Green' } else { 'Red' })
foreach ($match in $functionMatches) {
    Write-Host "  - $($match.Groups[1].Value)" -ForegroundColor Green
}

Write-Host ""

# Test alias pattern
$aliasPattern = "Set-AgentModeAlias\s+-Name\s+['""]([A-Za-z0-9_\-]+)['""]"
$aliasMatches = [regex]::Matches($content, $aliasPattern)
Write-Host "Alias pattern: $aliasPattern" -ForegroundColor Yellow
Write-Host "Found $($aliasMatches.Count) alias matches:" -ForegroundColor $(if ($aliasMatches.Count -gt 0) { 'Green' } else { 'Red' })
foreach ($match in $aliasMatches) {
    Write-Host "  - $($match.Groups[1].Value)" -ForegroundColor Green
}

Write-Host ""

# Show sample lines with Set-AgentModeFunction
Write-Host "Sample lines containing 'Set-AgentModeFunction':" -ForegroundColor Cyan
$sampleLines = $content -split "`n" | Select-String -Pattern "Set-AgentModeFunction" | Select-Object -First 5
foreach ($line in $sampleLines) {
    Write-Host "  $line" -ForegroundColor Gray
}
