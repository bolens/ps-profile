# ===============================================
# Check Profile Loading Log
# ===============================================
# This script reads the profile loading log file to see where execution stopped

$logFile = Join-Path $env:TEMP "powershell-profile-load.log"

Write-Host "=== Profile Loading Log ===" -ForegroundColor Cyan
Write-Host "Log file: $logFile" -ForegroundColor Yellow
Write-Host ""

if (Test-Path -LiteralPath $logFile) {
    $logContent = Get-Content -LiteralPath $logFile -ErrorAction SilentlyContinue
    if ($logContent) {
        Write-Host "Last 50 log entries:" -ForegroundColor Green
        Write-Host ""
        $logContent | Select-Object -Last 50 | ForEach-Object {
            Write-Host $_ -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "Total log entries: $($logContent.Count)" -ForegroundColor Yellow
        
        # Show the last entry
        $lastEntry = $logContent | Select-Object -Last 1
        Write-Host ""
        Write-Host "Last entry: $lastEntry" -ForegroundColor Cyan
    }
    else {
        Write-Host "Log file exists but is empty" -ForegroundColor Yellow
    }
}
else {
    Write-Host "Log file not found - profile may not have started executing" -ForegroundColor Red
    Write-Host ""
    Write-Host "This could mean:" -ForegroundColor Yellow
    Write-Host "  1. The profile file has a syntax error preventing execution" -ForegroundColor Gray
    Write-Host "  2. PowerShell is not loading the profile at all" -ForegroundColor Gray
    Write-Host "  3. The profile path is incorrect" -ForegroundColor Gray
}

Write-Host ""
Write-Host "To clear the log and start fresh:" -ForegroundColor Yellow
Write-Host "  Remove-Item '$logFile' -ErrorAction SilentlyContinue" -ForegroundColor White
