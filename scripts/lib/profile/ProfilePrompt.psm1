# ===============================================
# ProfilePrompt.psm1
# Prompt system initialization
# ===============================================

<#
.SYNOPSIS
    Initializes the prompt system (Starship or fallback).
.DESCRIPTION
    Initializes prompt system after all fragments load to ensure prompt configuration functions are available.
    Supports Starship prompt with performance insights integration.
#>
function Initialize-ProfilePrompt {
    [CmdletBinding()]
    param()

    try {
        if ($env:PS_PROFILE_DEBUG) { Write-Host "Checking for Initialize-Starship function..." -ForegroundColor Yellow }
        if (Get-Command Initialize-Starship -ErrorAction SilentlyContinue) {
            if ($env:PS_PROFILE_DEBUG) { Write-Host "Initialize-Starship function found, calling it..." -ForegroundColor Green }
            Initialize-Starship
            if ($env:PS_PROFILE_DEBUG) { Write-Host "Initialize-Starship completed" -ForegroundColor Green }

            # Verify prompt function was created successfully
            if (Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue) {
                if ($env:PS_PROFILE_DEBUG) { Write-Host "Prompt function verified and active" -ForegroundColor Green }
                
                # Re-wrap prompt with performance insights if available
                # This ensures performance timing works with Starship prompt
                if (Get-Command Update-PerformanceInsightsPrompt -ErrorAction SilentlyContinue) {
                    try {
                        Update-PerformanceInsightsPrompt
                        if ($env:PS_PROFILE_DEBUG) { Write-Host "Performance insights prompt wrapper updated" -ForegroundColor Cyan }
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) { Write-Host "Failed to update performance insights prompt: $($_.Exception.Message)" -ForegroundColor Yellow }
                    }
                }
            }
            else {
                if ($env:PS_PROFILE_DEBUG) { Write-Host "WARNING: Prompt function not found after initialization!" -ForegroundColor Red }
            }
        }
        else {
            if ($env:PS_PROFILE_DEBUG) { Write-Host "Initialize-Starship function not found" -ForegroundColor Red }
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) { Write-Host "Initialize-Starship failed: $($_.Exception.Message)" -ForegroundColor Red }
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Prompt initialization" -Category 'Profile'
        }
        else {
            Write-Warning "Failed to initialize prompt: $($_.Exception.Message)"
        }
    }
}

Export-ModuleMember -Function 'Initialize-ProfilePrompt'
