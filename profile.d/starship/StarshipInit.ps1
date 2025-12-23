# ===============================================
# StarshipInit.ps1
# Starship initialization script execution
# ===============================================

<#
.SYNOPSIS
    Executes Starship's initialization script and verifies it worked.
.DESCRIPTION
    Runs `starship init powershell --print-full-init` to get the initialization script,
    writes it to a temp file, executes it, and verifies that a valid prompt function was created.
.PARAMETER StarshipCommandPath
    The path to the starship executable.
.OUTPUTS
    System.Management.Automation.FunctionInfo
    The created prompt function.
#>
function Invoke-StarshipInitScript {
    param([string]$StarshipCommandPath)
    
    $tempInitScript = [System.IO.Path]::GetTempFileName() + '.ps1'
    try {
        # Get initialization script from starship
        $initOutput = & $StarshipCommandPath init powershell --print-full-init 2>&1
        if ($LASTEXITCODE -ne 0 -or -not $initOutput) {
            throw "Failed to get starship init script (exit code: $LASTEXITCODE)"
        }
        
        # Filter out error messages and empty lines from starship output
        $cleanOutput = $initOutput | Where-Object {
            $_ -notmatch '\[ERROR\]' -and
            $_ -notmatch 'Under a' -and
            $_.Trim() -ne ''
        }
        
        if (-not $cleanOutput) {
            throw "Starship init script output is empty or contains only errors"
        }
        
        # Write to temp file and execute
        $cleanOutput | Out-File -FilePath $tempInitScript -Encoding UTF8 -ErrorAction Stop
        
        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "Executing starship init script..." -ForegroundColor Yellow
        }
        
        . $tempInitScript
        
        # Verify prompt function was created
        $promptFunc = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
        if (-not $promptFunc) {
            throw "Starship init script did not create prompt function"
        }
        
        # Verify it's actually a Starship prompt
        $promptScript = $promptFunc.ScriptBlock.ToString()
        if ($promptScript -notmatch 'starship|Invoke-Native') {
            throw "Starship init script did not create a valid prompt function"
        }
        
        return $promptFunc
    }
    finally {
        # Clean up temp file
        if ($tempInitScript -and -not [string]::IsNullOrWhiteSpace($tempInitScript) -and (Test-Path -LiteralPath $tempInitScript)) {
            Remove-Item $tempInitScript -Force -ErrorAction SilentlyContinue
        }
    }
}

