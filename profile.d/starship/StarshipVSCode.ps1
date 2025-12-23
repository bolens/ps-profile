# ===============================================
# StarshipVSCode.ps1
# VS Code integration for Starship prompt
# ===============================================

<#
.SYNOPSIS
    Updates VS Code's prompt state if VS Code is active.
.DESCRIPTION
    Updates the VS Code global state with the current prompt function to ensure
    VS Code's integrated terminal properly tracks the prompt.
#>
function Update-VSCodePrompt {
    if ($null -ne $Global:__VSCodeState -and $null -ne $Global:__VSCodeState.OriginalPrompt) {
        $Global:__VSCodeState.OriginalPrompt = $function:prompt
        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "Updated VS Code OriginalPrompt with starship" -ForegroundColor Green
        }
    }
}

