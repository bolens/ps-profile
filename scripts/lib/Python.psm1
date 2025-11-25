# ===============================================
# Python helper utilities for conversion modules
# ===============================================

<#
.SYNOPSIS
    Gets the Python interpreter path, checking for virtual environment first.
.DESCRIPTION
    Attempts to locate a Python interpreter, checking for a .venv directory
    in the repository root first, then falling back to system Python.
    Returns the path to the Python interpreter if found, otherwise $null.
.PARAMETER RepoRoot
    Optional repository root path. If not provided, attempts to detect it.
.OUTPUTS
    System.String
    The path to the Python interpreter, or $null if not found.
#>
function Get-PythonPath {
    param(
        [string]$RepoRoot
    )

    # Try to get repo root if not provided
    if (-not $RepoRoot) {
        if (Get-Variable -Name 'RepoRoot' -Scope Script -ErrorAction SilentlyContinue) {
            $RepoRoot = $script:RepoRoot
        }
        elseif (Get-Variable -Name 'BootstrapRoot' -Scope Script -ErrorAction SilentlyContinue) {
            $RepoRoot = Split-Path -Parent $script:BootstrapRoot
        }
        else {
            # Try to detect from current location
            $current = Get-Location
            while ($current -and $current.Path -ne $current.Drive.Root) {
                if (Test-Path (Join-Path $current.Path '.git')) {
                    $RepoRoot = $current.Path
                    break
                }
                $current = Split-Path -Parent $current.Path
            }
        }
    }

    # Check for virtual environment in repo root
    if ($RepoRoot) {
        $venvPath = Join-Path $RepoRoot '.venv'
        if (Test-Path $venvPath) {
            # Try Windows path first
            $venvPythonPath = Join-Path $venvPath 'Scripts' 'python.exe'
            if (Test-Path $venvPythonPath) {
                return $venvPythonPath
            }
            # Try Unix-style path
            $venvPythonPath = Join-Path $venvPath 'bin' 'python'
            if (Test-Path $venvPythonPath) {
                return $venvPythonPath
            }
        }
    }

    # Fall back to system Python
    if (Get-Command python -ErrorAction SilentlyContinue) {
        return 'python'
    }
    elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
        return 'python3'
    }

    return $null
}

<#
.SYNOPSIS
    Executes a Python script with proper environment configuration.
.DESCRIPTION
    Executes a Python script, automatically using the virtual environment
    Python if available in the repository root. This ensures packages
    installed in the virtual environment can be found.
.PARAMETER ScriptPath
    The path to the Python script to execute.
.PARAMETER Arguments
    Arguments to pass to the Python script.
.PARAMETER RepoRoot
    Optional repository root path for virtual environment detection.
.EXAMPLE
    Invoke-PythonScript -ScriptPath "script.py" -Arguments "arg1", "arg2"
    Executes the Python script with the specified arguments.
.OUTPUTS
    System.String
    The output from the Python script.
#>
function Invoke-PythonScript {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments,

        [string]$RepoRoot
    )

    # Validate script path exists
    if (-not (Test-Path $ScriptPath -ErrorAction SilentlyContinue)) {
        throw "Python script not found: $ScriptPath"
    }
    
    # Validate script is readable
    try {
        $scriptItem = Get-Item $ScriptPath -ErrorAction Stop
        if (-not $scriptItem) {
            throw "Unable to access script file"
        }
    }
    catch {
        throw "Cannot access Python script '$ScriptPath': $($_.Exception.Message)"
    }
    
    $pythonPath = Get-PythonPath -RepoRoot $RepoRoot
    if (-not $pythonPath) {
        $errorMessage = "Python is not available. Install Python to use Python-based conversions."
        $errorMessage += "`nSuggestion: Install Python from https://www.python.org/ or use a package manager (scoop, choco, winget)"
        throw $errorMessage
    }
    
    # Validate Python executable is actually usable
    try {
        $pythonVersion = & $pythonPath --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Python command exists but failed to execute (exit code: $LASTEXITCODE)"
        }
    }
    catch {
        throw "Python command found at '$pythonPath' but is not executable: $($_.Exception.Message)"
    }

    # Execute Python script
    # Capture both stdout and stderr, but check exit code to determine if output is valid
    try {
        $output = & $pythonPath $ScriptPath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            return $output
        }
        
        # Build error message
        if (-not $output) {
            throw "Python script failed with exit code ${exitCode}: Unknown error (no output from script)"
        }
        
        # Filter out common non-error messages
        $filteredOutput = $output | Where-Object { 
            $_ -notmatch '^WARNING:' -and 
            $_ -notmatch '^INFO:' 
        }
        $errorMessage = if ($filteredOutput) {
            $filteredOutput -join "`n"
        }
        else {
            $output -join "`n"
        }
        
        $fullErrorMessage = "Python script failed with exit code ${exitCode}"
        if ($errorMessage) {
            $fullErrorMessage += ": $errorMessage"
        }
        throw $fullErrorMessage
        
        # On success, return the output (stdout)
        return $output
    }
    catch {
        $errorContext = "Failed to execute Python script '$ScriptPath'"
        if ($Arguments -and $Arguments.Count -gt 0) {
            $errorContext += " with arguments: $($Arguments -join ' ')"
        }
        Write-Error "$errorContext`: $($_.Exception.Message)"
        throw
    }
}

