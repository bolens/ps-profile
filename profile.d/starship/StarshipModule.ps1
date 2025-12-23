# ===============================================
# StarshipModule.ps1
# Starship module management
# ===============================================

<#
.SYNOPSIS
    Ensures Starship module stays loaded to prevent prompt from breaking.
.DESCRIPTION
    Stores a reference to the Starship module globally to prevent it from being garbage collected.
    This helps maintain prompt functionality even if the module would otherwise be unloaded.
#>
function Initialize-StarshipModule {
    $module = Get-Module starship -ErrorAction SilentlyContinue
    if ($module) {
        $global:StarshipModule = $module
        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "Starship module loaded and stored globally" -ForegroundColor Green
        }
    }
    else {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "WARNING: Starship module not found after init" -ForegroundColor Yellow
        }
    }
}

