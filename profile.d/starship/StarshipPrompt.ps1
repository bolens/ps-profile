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

    # These variables exist when called from the prompt scriptblock; provide safe defaults for direct calls/tests
    if (-not (Test-Path Variable:\lastCommandSucceeded)) {
        $lastCommandSucceeded = $?
    }
    if (-not (Test-Path Variable:\lastExitCode)) {
        $lastExitCodeVar = Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
        $lastExitCode = if ($lastExitCodeVar) { $lastExitCodeVar.Value } else { 0 }
    }
    $executionContext = $ExecutionContext
    
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
        $starshipCommandVar = Get-Variable -Name StarshipCommand -Scope Global -ErrorAction SilentlyContinue
        $starshipExecutable = if ($starshipCommandVar) { $starshipCommandVar.Value } else { $null }
        $useStarship = $starshipExecutable -and -not [string]::IsNullOrWhiteSpace($starshipExecutable) -and (Test-Path -LiteralPath $starshipExecutable)
        if (-not $useStarship) {
            $global:LASTEXITCODE = $lastExitCode
            return "PS $($executionContext.SessionState.Path.CurrentLocation.Path)> "
        }
        
        $arguments = Get-StarshipPromptArguments -LastCommandSucceeded $lastCommandSucceeded -LastExitCode $lastExitCode
        $promptText = & $starshipExecutable @arguments 2>$null
        
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

