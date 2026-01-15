<#
.SYNOPSIS
    Diagnoses profile loading performance issues.

.DESCRIPTION
    Measures profile load time and identifies slow fragments.
    Provides recommendations for optimization.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/diagnose-profile-performance.ps1
#>

# Import shared utilities
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'scripts' 'lib' 'ModuleImport.psm1'
if (Test-Path $moduleImportPath) {
    Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop
    
    Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
    Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
    Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
    
    try {
        $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    }
    catch {
        $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    }
}
else {
    # Fallback if modules not available
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

Write-Host "`n🔍 Profile Performance Diagnostics" -ForegroundColor Cyan
Write-Host "====================================`n" -ForegroundColor Cyan

# Method 1: Quick test with debug mode
Write-Host "Method 1: Testing with performance profiling..." -ForegroundColor Yellow
$profilePath = Join-Path $repoRoot 'Microsoft.PowerShell_profile.ps1'

$testScript = @"
`$env:PS_PROFILE_DEBUG = '3'
`$sw = [System.Diagnostics.Stopwatch]::StartNew()
. '$profilePath'
`$sw.Stop()
Write-Output "Total load time: `$(`$sw.Elapsed.TotalSeconds) seconds"
if (`$global:PSProfileFragmentTimes) {
    Write-Output "`nSlowest fragments:"
    `$global:PSProfileFragmentTimes | Sort-Object Duration -Descending | Select-Object -First 10 | Format-Table -AutoSize
}
"@

$tempScript = [System.IO.Path]::GetTempFileName() + '.ps1'
$testScript | Out-File -FilePath $tempScript -Encoding UTF8

$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    if ($debugLevel -ge 1) {
        Write-Verbose "[diagnose-profile-performance] Starting profile performance diagnosis"
    }
}

try {
    $diagnosisStartTime = [DateTime]::Now
    $result = pwsh -NoProfile -File $tempScript 2>&1
    Write-Host $result
    
    $diagnosisDuration = ([DateTime]::Now - $diagnosisStartTime).TotalMilliseconds
    if ($debugLevel -ge 2) {
        Write-Verbose "[diagnose-profile-performance] Diagnosis completed in ${diagnosisDuration}ms"
    }
}
catch {
    if ($debugLevel -ge 1) {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'diagnose-profile-performance' -Context @{
                script_path = $tempScript
            }
        }
        else {
            Write-Error "Failed to run profile performance diagnosis: $($_.Exception.Message)"
        }
    }
    if ($debugLevel -ge 2) {
        Write-Verbose "[diagnose-profile-performance] Diagnosis error: $($_.Exception.Message)"
    }
    if ($debugLevel -ge 3) {
        Write-Host "  [diagnose-profile-performance] Error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}
finally {
    try {
        Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
        if ($debugLevel -ge 3) {
            Write-Host "  [diagnose-profile-performance] Cleaned up temporary script: $tempScript" -ForegroundColor DarkGray
        }
    }
    catch {
        if ($debugLevel -ge 1) {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to clean up temporary script" -OperationName 'diagnose-profile-performance.cleanup' -Context @{
                    script_path = $tempScript
                    error       = $_.Exception.Message
                } -Code 'CLEANUP_FAILED'
            }
            else {
                Write-Warning "Failed to remove temporary script: $($_.Exception.Message)"
            }
        }
    }
}

Write-Host "`n💡 Optimization Recommendations:" -ForegroundColor Green
Write-Host @"
1. If prompt is slow (98+ seconds):
   - You're likely in a large git repository
   - Starship/oh-my-posh is calling git commands
   - Solution: Disable git in prompt or use minimal prompt

2. To disable git in Starship prompt:
   Add to your starship.toml:
   [git_branch]
   disabled = true
   
   Or set environment variable:
   `$env:STARSHIP_CONFIG = 'path/to/minimal-starship.toml'

3. To use minimal prompt temporarily:
   Set in your profile or .profile-fragments.json:
   {
     "disabled": ["23-starship", "06-oh-my-posh"]
   }

4. To enable batch loading (may help):
   Set environment variable:
   `$env:PS_PROFILE_BATCH_LOAD = '1'
   
   Or in .profile-fragments.json:
   {
     "performance": {
       "batchLoad": true
     }
   }

5. To disable specific slow fragments:
   Edit .profile-fragments.json:
   {
     "disabled": ["70-profile-updates", "73-performance-insights"]
   }
"@ -ForegroundColor White

Write-Host "`n📊 For detailed benchmark:" -ForegroundColor Cyan
Write-Host "   pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1" -ForegroundColor White

Exit-WithCode -ExitCode [ExitCode]::Success
