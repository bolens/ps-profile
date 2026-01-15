# Test profile loading with debug enabled
$env:PS_PROFILE_DEBUG = '3'
Write-Host "Testing profile loading with PS_PROFILE_DEBUG=$env:PS_PROFILE_DEBUG" -ForegroundColor Cyan
Write-Host "Profile path: $PROFILE" -ForegroundColor Yellow
Write-Host "---" -ForegroundColor Gray
Write-Host ""

try {
    . $PROFILE
    Write-Host ""
    Write-Host "---" -ForegroundColor Gray
    Write-Host "Profile loading completed (no exceptions)" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "---" -ForegroundColor Gray
    Write-Host "Profile loading failed with exception:" -ForegroundColor Red
    Write-Host "  Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    if ($_.ScriptStackTrace) {
        Write-Host "  Stack Trace:" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
    }
}
