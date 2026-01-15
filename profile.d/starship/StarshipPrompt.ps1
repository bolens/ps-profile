# ===============================================
# StarshipPrompt.ps1
# Starship prompt function creation
# ===============================================

<#
.SYNOPSIS
    Creates a global prompt function that directly calls starship executable.
.DESCRIPTION
    Creates a prompt function that calls starship directly (bypassing module scope issues).
    This ensures the prompt continues working even if the Starship module is unloaded.
.PARAMETER StarshipCommandPath
    The path to the starship executable.
#>
function New-StarshipPromptFunction {
    param([string]$StarshipCommandPath)
    
    if ($env:PS_PROFILE_DEBUG) {
        Write-Host "New-StarshipPromptFunction: Creating prompt function..." -ForegroundColor Cyan
    }
    
    # Verify helper function is available
    if (-not (Get-Command Get-StarshipPromptArguments -ErrorAction SilentlyContinue)) {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Warning "Get-StarshipPromptArguments not available - using simplified prompt function"
        }
        
        # Fallback prompt when helper is not available
        $global:LASTEXITCODE = $lastExitCode
        return "PS $($executionContext.SessionState.Path.CurrentLocation.Path)> "
    }
    
    # Build arguments and call starship executable directly
    try {
        if (-not $global:StarshipCommand -or -not ($global:StarshipCommand -and -not [string]::IsNullOrWhiteSpace($global:StarshipCommand) -and (Test-Path -LiteralPath $global:StarshipCommand))) {
            $global:LASTEXITCODE = $lastExitCode
            return "PS $($executionContext.SessionState.Path.CurrentLocation.Path)> "
        }
        
        $arguments = Get-StarshipPromptArguments -LastCommandSucceeded $lastCommandSucceeded -LastExitCode $lastExitCode
        $promptText = & $global:StarshipCommand @arguments 2>$null
        
        if ($promptText -and $promptText.Trim()) {
            # Configure PSReadLine for multi-line prompts (Starship may output multiple lines)
            try {
                $lineCount = ($promptText.Split("`n").Length - 1)
                Set-PSReadLineOption -ExtraPromptLineCount $lineCount -ErrorAction SilentlyContinue
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "Failed to set PSReadLine extra prompt line count: $($_.Exception.Message)"
                }
            }
            
            $global:LASTEXITCODE = $lastExitCode
            return $promptText
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Verbose "Failed to generate Starship prompt: $($_.Exception.Message)"
        }
    }
    
    # Fallback prompt
    $global:LASTEXITCODE = $lastExitCode
    return "PS $($executionContext.SessionState.Path.CurrentLocation.Path)> "
}

