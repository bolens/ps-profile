<#
scripts/lib/NodeJs.psm1

.SYNOPSIS
    Node.js execution utilities with pnpm support.

.DESCRIPTION
    Provides functions for executing Node.js scripts with proper NODE_PATH
    configuration to support packages installed via both npm and pnpm.
    Handles automatic detection of pnpm global installations and configures
    Node.js module resolution accordingly.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

<#
.SYNOPSIS
    Gets the pnpm global node_modules path if available.
.DESCRIPTION
    Attempts to locate pnpm's global node_modules directory to support
    packages installed via pnpm. Returns the path if found, otherwise $null.
.OUTPUTS
    System.String
    The path to pnpm's global node_modules directory, or $null if not found.
#>
function Get-PnpmGlobalPath {
    $pnpmGlobalPath = $null
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        try {
            $pnpmRootOutput = & pnpm root -g 2>&1
            $exitCode = $LASTEXITCODE
            
            # Only process output if command succeeded
            if ($exitCode -eq 0 -and $pnpmRootOutput) {
                $pnpmRoot = $pnpmRootOutput | Where-Object { 
                    $_ -and 
                    -not [string]::IsNullOrWhiteSpace($_) -and
                    -not ($_ -match 'error|not found|WARN|ERR') 
                } | Select-Object -First 1
                
                if ($pnpmRoot) {
                    $pnpmGlobalPath = $pnpmRoot.ToString().Trim()
                    # Validate that the path exists
                    if ($pnpmGlobalPath -and (Test-Path $pnpmGlobalPath)) {
                        return $pnpmGlobalPath
                    }
                }
            }
        }
        catch {
            # Fall through to try common location
            Write-Verbose "pnpm root -g command failed: $($_.Exception.Message)"
        }
    }
    
    # If pnpm global path not found, try common location
    if (-not $pnpmGlobalPath) {
        $commonPnpmPath = "$env:LOCALAPPDATA\pnpm\global\5\node_modules"
        if (Test-Path $commonPnpmPath) {
            $pnpmGlobalPath = $commonPnpmPath
        }
    }
    
    return $pnpmGlobalPath
}

<#
.SYNOPSIS
    Executes a Node.js script with proper NODE_PATH configuration.
.DESCRIPTION
    Executes a Node.js script, automatically setting NODE_PATH to include
    pnpm's global node_modules directory if available. This ensures packages
    installed via pnpm can be found by Node.js.
.PARAMETER ScriptPath
    The path to the Node.js script to execute.
.PARAMETER Arguments
    Arguments to pass to the Node.js script.
.EXAMPLE
    Invoke-NodeScript -ScriptPath "script.js" -Arguments "arg1", "arg2"
    Executes the Node.js script with the specified arguments.
.OUTPUTS
    System.String
    The output from the Node.js script.
#>
function Invoke-NodeScript {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )
    
    # Validate script path exists
    if (-not (Test-Path $ScriptPath)) {
        throw "Node.js script not found: $ScriptPath"
    }
    
    # Check if node command is available
    $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
    if (-not $nodeCommand) {
        $errorMessage = "Node.js is not available. Please install Node.js to use this function."
        $errorMessage += "`nSuggestion: Install Node.js from https://nodejs.org/ or use a package manager (scoop, choco, winget)"
        throw $errorMessage
    }
    
    # Validate node executable is actually usable
    try {
        $nodeVersion = & node --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Node.js command exists but failed to execute (exit code: $LASTEXITCODE)"
        }
    }
    catch {
        throw "Node.js command found at '$($nodeCommand.Source)' but is not executable: $($_.Exception.Message)"
    }
    
    $pnpmGlobalPath = Get-PnpmGlobalPath
    $originalNodePath = $env:NODE_PATH
    
    try {
        # Set NODE_PATH to include pnpm global if available
        if ($pnpmGlobalPath) {
            try {
                if ($env:NODE_PATH) {
                    $env:NODE_PATH = "$pnpmGlobalPath;$env:NODE_PATH"
                }
                else {
                    $env:NODE_PATH = $pnpmGlobalPath
                }
            }
            catch {
                Write-Warning "Failed to set NODE_PATH: $($_.Exception.Message). Continuing without pnpm global path."
            }
        }
        
        # Execute node script
        # Capture both stdout and stderr, but check exit code to determine if output is valid
        try {
            $output = & node $ScriptPath @Arguments 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                return $output
            }
            
            # Build error message
            if (-not $output) {
                throw "Node.js script failed with exit code ${exitCode}: Unknown error (no output from script)"
            }
            
            # Filter out common non-error messages
            $filteredOutput = $output | Where-Object { 
                $_ -notmatch '^npm (WARN|info)' -and 
                $_ -notmatch '^yarn (WARN|info)' 
            }
            $errorMessage = if ($filteredOutput) {
                $filteredOutput -join "`n"
            }
            else {
                $output -join "`n"
            }
            
            $fullErrorMessage = "Node.js script failed with exit code $exitCode"
            if ($errorMessage) {
                $fullErrorMessage += ": $errorMessage"
            }
            throw $fullErrorMessage
        }
        catch {
            $errorContext = "Failed to execute Node.js script '$ScriptPath'"
            if ($Arguments -and $Arguments.Count -gt 0) {
                $errorContext += " with arguments: $($Arguments -join ' ')"
            }
            Write-Error "$errorContext`: $($_.Exception.Message)"
            throw
        }
    }
    finally {
        # Restore original NODE_PATH
        try {
            if ($originalNodePath) {
                $env:NODE_PATH = $originalNodePath
            }
            elseif ($pnpmGlobalPath) {
                Remove-Item Env:\NODE_PATH -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Warning "Failed to restore NODE_PATH: $($_.Exception.Message)"
        }
    }
}

<#
.SYNOPSIS
    Sets up NODE_PATH environment variable for Node.js execution.
.DESCRIPTION
    Configures NODE_PATH to include pnpm's global node_modules directory
    if available. Returns a script block that restores the original NODE_PATH
    when disposed. Use this for manual node execution when you need to manage
    the environment yourself.
.EXAMPLE
    $restore = Set-NodePathForPnpm
    try {
        & node script.js
    }
    finally {
        & $restore
    }
.OUTPUTS
    ScriptBlock
    A script block that restores the original NODE_PATH when invoked.
#>
function Set-NodePathForPnpm {
    $pnpmGlobalPath = Get-PnpmGlobalPath
    $originalNodePath = $env:NODE_PATH
    
    if ($pnpmGlobalPath) {
        if ($env:NODE_PATH) {
            $env:NODE_PATH = "$pnpmGlobalPath;$env:NODE_PATH"
        }
        else {
            $env:NODE_PATH = $pnpmGlobalPath
        }
    }
    
    # Return restore script block
    {
        if ($originalNodePath) {
            $env:NODE_PATH = $originalNodePath
        }
        elseif ($pnpmGlobalPath) {
            Remove-Item Env:\NODE_PATH -ErrorAction SilentlyContinue
        }
    }.GetNewClosure()
}

