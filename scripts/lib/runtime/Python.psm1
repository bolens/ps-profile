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

    # Use Validation module if available
    $useValidation = Get-Command Test-ValidPath -ErrorAction SilentlyContinue

    # First, check common Python-related environment variables (highest priority)
    $pythonEnvVars = @('PYTHON_HOME', 'PYTHON_ROOT', 'PYTHON', 'VIRTUAL_ENV', 'CONDA_PREFIX')
    foreach ($envVar in $pythonEnvVars) {
        $envVarName = "env:$envVar"
        $envValue = if (Test-Path -Path "Variable:$envVarName" -ErrorAction SilentlyContinue) {
            (Get-Item -Path "Variable:$envVarName" -ErrorAction SilentlyContinue).Value
        }
        else {
            $null
        }
        
        if ($envValue -and -not [string]::IsNullOrWhiteSpace($envValue)) {
            # For VIRTUAL_ENV and CONDA_PREFIX, these point to the environment root
            if ($envVar -eq 'VIRTUAL_ENV' -or $envVar -eq 'CONDA_PREFIX') {
                # Check for Python executable in the environment
                $pythonExe = if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                    Join-Path $envValue 'Scripts' 'python.exe'
                }
                else {
                    Join-Path $envValue 'bin' 'python'
                }
                $pythonExists = if ($useValidation) {
                    Test-ValidPath -Path $pythonExe -PathType File
                }
                else {
                    $pythonExe -and -not [string]::IsNullOrWhiteSpace($pythonExe) -and (Test-Path -LiteralPath $pythonExe)
                }
                if ($pythonExists) {
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                        Write-Host "  [python.get-path] Found Python via $envVar env var: $pythonExe" -ForegroundColor DarkGray
                    }
                    return $pythonExe
                }
            }
            # For PYTHON_HOME, PYTHON_ROOT, PYTHON - these might point directly to Python or its directory
            elseif ($envVar -eq 'PYTHON') {
                # PYTHON might be a direct path to Python executable
                $pythonExists = if ($useValidation) {
                    Test-ValidPath -Path $envValue -PathType File
                }
                else {
                    $envValue -and -not [string]::IsNullOrWhiteSpace($envValue) -and (Test-Path -LiteralPath $envValue)
                }
                if ($pythonExists) {
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                        Write-Host "  [python.get-path] Found Python via PYTHON env var: $envValue" -ForegroundColor DarkGray
                    }
                    return $envValue
                }
            }
            else {
                # PYTHON_HOME or PYTHON_ROOT - check for python.exe or python in bin/Scripts
                $pythonExe = if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                    Join-Path $envValue 'python.exe'
                }
                else {
                    Join-Path $envValue 'python'
                }
                $pythonExists = if ($useValidation) {
                    Test-ValidPath -Path $pythonExe -PathType File
                }
                else {
                    $pythonExe -and -not [string]::IsNullOrWhiteSpace($pythonExe) -and (Test-Path -LiteralPath $pythonExe)
                }
                if ($pythonExists) {
                    return $pythonExe
                }
                # Try bin/python or Scripts/python.exe
                $pythonExe = if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                    Join-Path $envValue 'Scripts' 'python.exe'
                }
                else {
                    Join-Path $envValue 'bin' 'python'
                }
                $pythonExists = if ($useValidation) {
                    Test-ValidPath -Path $pythonExe -PathType File
                }
                else {
                    $pythonExe -and -not [string]::IsNullOrWhiteSpace($pythonExe) -and (Test-Path -LiteralPath $pythonExe)
                }
                if ($pythonExists) {
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                        Write-Host "  [python.get-path] Found Python via $envVar env var: $pythonExe" -ForegroundColor DarkGray
                    }
                    return $pythonExe
                }
            }
        }
    }
    
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        Write-Host "  [python.get-path] No Python found via environment variables, checking virtual environment and system Python" -ForegroundColor DarkGray
    }

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
        $venvExists = if ($useValidation) {
            Test-ValidPath -Path $venvPath -PathType Directory
        }
        else {
            $venvPath -and -not [string]::IsNullOrWhiteSpace($venvPath) -and (Test-Path -LiteralPath $venvPath)
        }
        
        if ($venvExists) {
            # Try Windows path first
            $venvPythonPath = Join-Path $venvPath 'Scripts' 'python.exe'
            $pythonExists = if ($useValidation) {
                Test-ValidPath -Path $venvPythonPath -PathType File
            }
            else {
                $venvPythonPath -and -not [string]::IsNullOrWhiteSpace($venvPythonPath) -and (Test-Path -LiteralPath $venvPythonPath)
            }
            if ($pythonExists) {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                    Write-Host "  [python.get-path] Found Python in virtual environment: $venvPythonPath" -ForegroundColor DarkGray
                }
                return $venvPythonPath
            }
            # Try Unix-style path
            $venvPythonPath = Join-Path $venvPath 'bin' 'python'
            $pythonExists = if ($useValidation) {
                Test-ValidPath -Path $venvPythonPath -PathType File
            }
            else {
                $venvPythonPath -and -not [string]::IsNullOrWhiteSpace($venvPythonPath) -and (Test-Path -LiteralPath $venvPythonPath)
            }
            if ($pythonExists) {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                    Write-Host "  [python.get-path] Found Python in virtual environment: $venvPythonPath" -ForegroundColor DarkGray
                }
                return $venvPythonPath
            }
        }
    }

    # Fall back to system Python, respecting PS_PYTHON_RUNTIME preference
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
        Write-Host "  [python.get-path] Virtual environment not found, checking system Python (PS_PYTHON_RUNTIME: $($env:PS_PYTHON_RUNTIME ?? 'auto'))" -ForegroundColor DarkGray
    }
    $pythonRuntime = if ($env:PS_PYTHON_RUNTIME) {
        $env:PS_PYTHON_RUNTIME.ToLower()
    }
    else {
        'auto'
    }
    
    # Check preferred runtime first if specified
    if ($pythonRuntime -ne 'auto') {
        if ($pythonRuntime -eq 'python' -and (Get-Command python -ErrorAction SilentlyContinue)) {
            return 'python'
        }
        elseif ($pythonRuntime -eq 'python3' -and (Get-Command python3 -ErrorAction SilentlyContinue)) {
            return 'python3'
        }
        elseif ($pythonRuntime -eq 'py' -and (Get-Command py -ErrorAction SilentlyContinue)) {
            return 'py'
        }
    }
    
    # Auto-detect: prefer python3, then python, then py
    if (Get-Command python3 -ErrorAction SilentlyContinue) {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Host "  [python.get-path] Found system Python: python3" -ForegroundColor DarkGray
        }
        return 'python3'
    }
    elseif (Get-Command python -ErrorAction SilentlyContinue) {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[python.get-path] Found system Python: python"
        }
        return 'python'
    }
    elseif (Get-Command py -ErrorAction SilentlyContinue) {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Host "  [python.get-path] Found system Python: py" -ForegroundColor DarkGray
        }
        return 'py'
    }
    
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        if ($debugLevel -ge 1) {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Python not found in environment variables, virtual environment, or system PATH" -OperationName 'python.get-path' -Context @{
                    RepoRoot      = $RepoRoot
                    PythonRuntime = $env:PS_PYTHON_RUNTIME
                }
            }
            else {
                Write-Warning "[python.get-path] Python not found in environment variables, virtual environment, or system PATH"
            }
        }
        # Level 3: Log detailed Python detection information
        if ($debugLevel -ge 3) {
            Write-Host "  [python.get-path] Python detection details - RepoRoot: $RepoRoot, PythonRuntime: $($env:PS_PYTHON_RUNTIME ?? 'auto'), CheckedEnvVars: $($pythonEnvVars -join ', ')" -ForegroundColor DarkGray
        }
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
    # Use Validation module if available
    if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
        if (-not (Test-ValidPath -Path $ScriptPath -PathType File)) {
            throw "Python script not found: $ScriptPath"
        }
    }
    else {
        # Fallback to manual validation
        if (-not ($ScriptPath -and -not [string]::IsNullOrWhiteSpace($ScriptPath) -and (Test-Path -LiteralPath $ScriptPath -ErrorAction SilentlyContinue))) {
            throw "Python script not found: $ScriptPath"
        }
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
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                    [System.Exception]::new($errorMessage),
                    'PythonNotAvailable',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $null
                )) -OperationName 'python.invoke-script' -Context @{
                script_path = $ScriptPath
            }
        }
        else {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                                [System.Exception]::new($errorMessage),
                                'PythonPathNotFound',
                                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                                $null
                            )) -OperationName 'python.invoke-script' -Context @{
                            ScriptPath = $ScriptPath
                            RepoRoot   = $RepoRoot
                        }
                    }
                    else {
                        Write-Error "[python.invoke-script] $errorMessage" -ErrorAction Continue
                    }
                }
                # Level 3: Log detailed error information
                if ($debugLevel -ge 3) {
                    Write-Host "  [python.invoke-script] Python path error details - ScriptPath: $ScriptPath, RepoRoot: $RepoRoot, ErrorMessage: $errorMessage" -ForegroundColor DarkGray
                }
            }
        }
        throw $errorMessage
    }
    
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Host "  [python.invoke-script] Using Python: $pythonPath" -ForegroundColor DarkGray
        }
    
    # Validate Python executable is actually usable
    try {
        $pythonVersion = & $pythonPath --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            $errorMsg = "Python command exists but failed to execute (exit code: $LASTEXITCODE)"
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message $errorMsg -OperationName 'python.invoke-script' -Context @{
                            PythonPath    = $pythonPath
                            ExitCode      = $LASTEXITCODE
                            PythonVersion = $pythonVersion
                        }
                    }
                    else {
                        Write-Warning "[python.invoke-script] $errorMsg"
                    }
                }
                # Level 3: Log detailed error information
                if ($debugLevel -ge 3) {
                    Write-Host "  [python.invoke-script] Python version check error details - PythonPath: $pythonPath, ExitCode: $LASTEXITCODE, PythonVersion: $pythonVersion" -ForegroundColor DarkGray
                }
            }
            throw $errorMsg
        }
        
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Verbose "[python.invoke-script] Python version: $pythonVersion"
        }
    }
    catch {
        $errorMsg = "Python command found at '$pythonPath' but is not executable: $($_.Exception.Message)"
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            if ($debugLevel -ge 1) {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message $errorMsg -OperationName 'python.invoke-script' -Context @{
                        PythonPath = $pythonPath
                        Error      = $_.Exception.Message
                    }
                }
                else {
                    Write-Warning "[python.invoke-script] $errorMsg"
                }
            }
            # Level 3: Log detailed error information
            if ($debugLevel -ge 3) {
                Write-Host "  [python.invoke-script] Python executable error details - PythonPath: $pythonPath, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
            }
        }
        throw $errorMsg
    }

    # Execute Python script
    # Capture both stdout and stderr, but check exit code to determine if output is valid
    try {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            $argsStr = if ($Arguments -and $Arguments.Count -gt 0) { " with arguments: $($Arguments -join ' ')" } else { '' }
            Write-Verbose "[python.invoke-script] Executing Python script: $ScriptPath$argsStr"
        }
        
        $output = & $pythonPath $ScriptPath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 2) {
                    Write-Host "  [python.invoke-script] Python script executed successfully (exit code: $exitCode)" -ForegroundColor DarkGray
                }
                # Level 3: Log detailed success information
                if ($debugLevel -ge 3) {
                    $outputLength = if ($output) { $output.Count } else { 0 }
                    Write-Host "  [python.invoke-script] Script execution success details - ScriptPath: $ScriptPath, PythonPath: $pythonPath, ExitCode: $exitCode, OutputLength: $outputLength" -ForegroundColor DarkGray
                }
            }
            return $output
        }
        
        # Build error message
        if (-not $output) {
            $errorMsg = "Python script failed with exit code ${exitCode}: Unknown error (no output from script)"
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message $errorMsg -OperationName 'python.invoke-script' -Context @{
                            ScriptPath = $ScriptPath
                            PythonPath = $pythonPath
                            ExitCode   = $exitCode
                            HasOutput  = $false
                        }
                    }
                    else {
                        Write-Warning "[python.invoke-script] $errorMsg"
                    }
                }
                # Level 3: Log detailed error information
                if ($debugLevel -ge 3) {
                    Write-Host "  [python.invoke-script] Script execution error details - ScriptPath: $ScriptPath, PythonPath: $pythonPath, ExitCode: $exitCode, Output: null" -ForegroundColor DarkGray
                }
            }
            throw $errorMsg
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
        
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            if ($debugLevel -ge 1) {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message $fullErrorMessage -OperationName 'python.invoke-script' -Context @{
                        ScriptPath   = $ScriptPath
                        PythonPath   = $pythonPath
                        ExitCode     = $exitCode
                        ErrorMessage = $errorMessage
                        HasOutput    = $true
                    }
                }
                else {
                    Write-Warning "[python.invoke-script] $fullErrorMessage"
                }
            }
            # Level 3: Log detailed error information
            if ($debugLevel -ge 3) {
                Write-Host "  [python.invoke-script] Script execution error details - ScriptPath: $ScriptPath, PythonPath: $pythonPath, ExitCode: $exitCode, ErrorMessage: $errorMessage, OutputLength: $($output.Count)" -ForegroundColor DarkGray
            }
        }
        
        throw $fullErrorMessage
    }
    catch {
        $errorContext = "Failed to execute Python script '$ScriptPath'"
        if ($Arguments -and $Arguments.Count -gt 0) {
            $errorContext += " with arguments: $($Arguments -join ' ')"
        }
        
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'python.invoke-script' -Context @{
                script_path   = $ScriptPath
                python_path   = $pythonPath
                arguments     = $Arguments
                error_context = $errorContext
            }
        }
        else {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                Write-Error "[python.invoke-script] $errorContext`: $($_.Exception.Message)" -ErrorAction Continue
            }
        }
        throw
    }
}

<#
.SYNOPSIS
    Gets the preferred data frame library (pandas or polars) based on availability and user preference.
.DESCRIPTION
    Determines which data frame library to use based on:
    1. User preference via $env:PS_DATA_FRAME_LIB ('pandas', 'polars', or 'auto')
    2. Library availability (checks if packages are installed)
    3. Defaults to 'pandas' if both are available and no preference is set
    
    Returns a hashtable with library information including:
    - Library: 'pandas' or 'polars'
    - Available: $true if the library is available
    - BothAvailable: $true if both libraries are available
.PARAMETER PythonCmd
    Optional Python command path. If not provided, uses Get-PythonPath.
.EXAMPLE
    $libInfo = Get-DataFrameLibraryPreference
    if ($libInfo.Available) {
        Write-Host "Using $($libInfo.Library)"
    }
.OUTPUTS
    System.Collections.Hashtable
    Hashtable with Library, Available, and BothAvailable keys.
#>
function Get-DataFrameLibraryPreference {
    param(
        [string]$PythonCmd
    )
    
    # Get Python command if not provided
    if (-not $PythonCmd) {
        $PythonCmd = Get-PythonPath
        if (-not $PythonCmd) {
            return @{
                Library       = 'pandas'
                Available     = $false
                BothAvailable = $false
            }
        }
    }
    
    # Check user preference
    $preference = if ($env:PS_DATA_FRAME_LIB) {
        $env:PS_DATA_FRAME_LIB.ToLower()
    }
    else {
        'auto'
    }
    
    # Check availability of both libraries
    $pandasAvailable = $false
    $polarsAvailable = $false
    
    # Check pandas
    $checkPandas = "import sys; import importlib.util; spec = importlib.util.find_spec('pandas'); sys.exit(0 if spec else 1)"
    $tempCheck = Join-Path $env:TEMP "python-check-pandas-$(Get-Random).py"
    Set-Content -Path $tempCheck -Value $checkPandas -Encoding UTF8
    try {
        & $PythonCmd $tempCheck 2>&1 | Out-Null
        $pandasAvailable = ($LASTEXITCODE -eq 0)
    }
    catch {
        $pandasAvailable = $false
    }
    finally {
        Remove-Item -Path $tempCheck -ErrorAction SilentlyContinue
    }
    
    # Check polars
    $checkPolars = "import sys; import importlib.util; spec = importlib.util.find_spec('polars'); sys.exit(0 if spec else 1)"
    $tempCheck = Join-Path $env:TEMP "python-check-polars-$(Get-Random).py"
    Set-Content -Path $tempCheck -Value $checkPolars -Encoding UTF8
    try {
        & $PythonCmd $tempCheck 2>&1 | Out-Null
        $polarsAvailable = ($LASTEXITCODE -eq 0)
    }
    catch {
        $polarsAvailable = $false
    }
    finally {
        Remove-Item -Path $tempCheck -ErrorAction SilentlyContinue
    }
    
    $bothAvailable = $pandasAvailable -and $polarsAvailable
    
    # Determine library based on preference
    $selectedLibrary = switch ($preference) {
        'pandas' {
            if ($pandasAvailable) { 'pandas' } else { 'polars' }
        }
        'polars' {
            if ($polarsAvailable) { 'polars' } else { 'pandas' }
        }
        default {
            # 'auto' or invalid preference
            if ($pandasAvailable) { 'pandas' } elseif ($polarsAvailable) { 'polars' } else { 'pandas' }
        }
    }
    
    # Ensure selected library is available
    $isAvailable = if ($selectedLibrary -eq 'pandas') { $pandasAvailable } else { $polarsAvailable }
    
    # If selected library is not available but the other is, use the available one
    if (-not $isAvailable) {
        if ($pandasAvailable) {
            $selectedLibrary = 'pandas'
            $isAvailable = $true
        }
        elseif ($polarsAvailable) {
            $selectedLibrary = 'polars'
            $isAvailable = $true
        }
    }
    
    return @{
        Library         = $selectedLibrary
        Available       = $isAvailable
        BothAvailable   = $bothAvailable
        PandasAvailable = $pandasAvailable
        PolarsAvailable = $polarsAvailable
    }
}

<#
.SYNOPSIS
    Gets the preferred Python package manager based on availability and user preference.
.DESCRIPTION
    Determines which Python package manager to use based on:
    1. User preference via $env:PS_PYTHON_PACKAGE_MANAGER ('uv', 'pip', 'conda', 'poetry', 'pipenv', or 'auto')
    2. Manager availability (checks if commands are installed)
    3. Defaults to 'uv' if available, then 'pip', then others
    
    Returns a hashtable with manager information including:
    - Manager: 'uv', 'pip', 'conda', 'poetry', 'pipenv', or $null
    - Available: $true if the manager is available
    - InstallCommand: Command template for installing packages (e.g., 'uv pip install {package}')
    - GlobalFlag: Flag for global installation (e.g., '--system', '--user', '--global')
    - LocalFlag: Flag for local installation (e.g., '--user', '')
.PARAMETER PythonCmd
    Optional Python command path. If not provided, uses Get-PythonPath.
.EXAMPLE
    $pmInfo = Get-PythonPackageManagerPreference
    if ($pmInfo.Available) {
        $installCmd = $pmInfo.InstallCommand -f 'pandas'
        Write-Host "Install with: $installCmd"
    }
.OUTPUTS
    System.Collections.Hashtable
    Hashtable with Manager, Available, InstallCommand, GlobalFlag, and LocalFlag keys.
#>
function Get-PythonPackageManagerPreference {
    param(
        [string]$PythonCmd
    )
    
    # Check user preference
    $preference = if ($env:PS_PYTHON_PACKAGE_MANAGER) {
        $env:PS_PYTHON_PACKAGE_MANAGER.ToLower()
    }
    else {
        'auto'
    }
    
    # Check availability of package managers
    $managers = @{
        'uv'     = @{
            Command        = 'uv'
            CheckCommand   = { Get-Command uv -ErrorAction SilentlyContinue }
            InstallCommand = 'uv pip install {package}'
            GlobalFlag     = '--system'
            LocalFlag      = '--user'
            Available      = $false
        }
        'pip'    = @{
            Command        = 'pip'
            CheckCommand   = { Get-Command pip -ErrorAction SilentlyContinue }
            InstallCommand = 'pip install {package}'
            GlobalFlag     = ''
            LocalFlag      = '--user'
            Available      = $false
        }
        'conda'  = @{
            Command        = 'conda'
            CheckCommand   = { Get-Command conda -ErrorAction SilentlyContinue }
            InstallCommand = 'conda install {package}'
            GlobalFlag     = ''
            LocalFlag      = ''
            Available      = $false
        }
        'poetry' = @{
            Command        = 'poetry'
            CheckCommand   = { Get-Command poetry -ErrorAction SilentlyContinue }
            InstallCommand = 'poetry add {package}'
            GlobalFlag     = ''
            LocalFlag      = ''
            Available      = $false
        }
        'pipenv' = @{
            Command        = 'pipenv'
            CheckCommand   = { Get-Command pipenv -ErrorAction SilentlyContinue }
            InstallCommand = 'pipenv install {package}'
            GlobalFlag     = ''
            LocalFlag      = ''
            Available      = $false
        }
    }
    
    # Check availability
    foreach ($key in $managers.Keys) {
        try {
            $managers[$key].Available = (& $managers[$key].CheckCommand) -ne $null
        }
        catch {
            $managers[$key].Available = $false
        }
    }
    
    # Determine manager based on preference
    $selectedManager = switch ($preference) {
        'uv' {
            if ($managers['uv'].Available) { 'uv' } elseif ($managers['pip'].Available) { 'pip' } else { $null }
        }
        'pip' {
            if ($managers['pip'].Available) { 'pip' } elseif ($managers['uv'].Available) { 'uv' } else { $null }
        }
        'conda' {
            if ($managers['conda'].Available) { 'conda' } elseif ($managers['uv'].Available) { 'uv' } elseif ($managers['pip'].Available) { 'pip' } else { $null }
        }
        'poetry' {
            if ($managers['poetry'].Available) { 'poetry' } elseif ($managers['uv'].Available) { 'uv' } elseif ($managers['pip'].Available) { 'pip' } else { $null }
        }
        'pipenv' {
            if ($managers['pipenv'].Available) { 'pipenv' } elseif ($managers['uv'].Available) { 'uv' } elseif ($managers['pip'].Available) { 'pip' } else { $null }
        }
        default {
            # 'auto' or invalid preference - prefer uv, then pip, then others
            if ($managers['uv'].Available) { 'uv' }
            elseif ($managers['pip'].Available) { 'pip' }
            elseif ($managers['conda'].Available) { 'conda' }
            elseif ($managers['poetry'].Available) { 'poetry' }
            elseif ($managers['pipenv'].Available) { 'pipenv' }
            else { $null }
        }
    }
    
    if (-not $selectedManager) {
        return @{
            Manager        = $null
            Available      = $false
            InstallCommand = 'pip install {package}'
            GlobalFlag     = ''
            LocalFlag      = '--user'
            AllManagers    = $managers
        }
    }
    
    $managerInfo = $managers[$selectedManager]
    
    return @{
        Manager        = $selectedManager
        Available      = $true
        InstallCommand = $managerInfo.InstallCommand
        GlobalFlag     = $managerInfo.GlobalFlag
        LocalFlag      = $managerInfo.LocalFlag
        AllManagers    = $managers
    }
}

<#
.SYNOPSIS
    Gets installation command for a Python package using the preferred package manager.
.DESCRIPTION
    Returns the installation command for a Python package using the preferred package manager.
    Supports global and local installation modes.
.PARAMETER PackageName
    The name of the package to install.
.PARAMETER Global
    If true, install globally. If false, install locally.
.PARAMETER PythonCmd
    Optional Python command path.
.EXAMPLE
    $cmd = Get-PythonPackageInstallCommand -PackageName 'pandas' -Global
    Write-Host "Run: $cmd"
.OUTPUTS
    System.String
    The installation command string.
#>
function Get-PythonPackageInstallCommand {
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,
        
        [switch]$Global,
        
        [string]$PythonCmd
    )
    
    $pmInfo = Get-PythonPackageManagerPreference -PythonCmd $PythonCmd
    
    if (-not $pmInfo.Available) {
        # Fallback to pip if no manager available
        $flag = if ($Global) { '' } else { '--user' }
        return "pip install $flag $PackageName".Trim()
    }
    
    $installCmd = $pmInfo.InstallCommand -f $PackageName
    $flag = if ($Global) { $pmInfo.GlobalFlag } else { $pmInfo.LocalFlag }
    
    if ($flag) {
        return "$installCmd $flag".Trim()
    }
    
    return $installCmd
}

<#
.SYNOPSIS
    Gets the preferred Parquet library (pyarrow or fastparquet) based on availability and user preference.
.DESCRIPTION
    Determines which Parquet library to use based on:
    1. User preference via $env:PS_PARQUET_LIB ('pyarrow', 'fastparquet', or 'auto')
    2. Library availability (checks if packages are installed)
    3. Defaults to 'pyarrow' if both are available and no preference is set
    
    Returns a hashtable with library information including:
    - Library: 'pyarrow' or 'fastparquet'
    - Available: $true if the library is available
    - BothAvailable: $true if both libraries are available
.PARAMETER PythonCmd
    Optional Python command path. If not provided, uses Get-PythonPath.
.EXAMPLE
    $libInfo = Get-ParquetLibraryPreference
    if ($libInfo.Available) {
        Write-Host "Using $($libInfo.Library)"
    }
.OUTPUTS
    System.Collections.Hashtable
    Hashtable with Library, Available, and BothAvailable keys.
#>
function Get-ParquetLibraryPreference {
    param(
        [string]$PythonCmd
    )
    
    # Get Python command if not provided
    if (-not $PythonCmd) {
        $PythonCmd = Get-PythonPath
        if (-not $PythonCmd) {
            return @{
                Library       = 'pyarrow'
                Available     = $false
                BothAvailable = $false
            }
        }
    }
    
    # Check user preference
    $preference = if ($env:PS_PARQUET_LIB) {
        $env:PS_PARQUET_LIB.ToLower()
    }
    else {
        'auto'
    }
    
    # Check availability of both libraries
    $pyarrowAvailable = $false
    $fastparquetAvailable = $false
    
    # Check pyarrow
    $checkPyarrow = "import sys; import importlib.util; spec = importlib.util.find_spec('pyarrow'); sys.exit(0 if spec else 1)"
    $tempCheck = Join-Path $env:TEMP "python-check-pyarrow-$(Get-Random).py"
    Set-Content -Path $tempCheck -Value $checkPyarrow -Encoding UTF8
    try {
        & $PythonCmd $tempCheck 2>&1 | Out-Null
        $pyarrowAvailable = ($LASTEXITCODE -eq 0)
    }
    catch {
        $pyarrowAvailable = $false
    }
    finally {
        Remove-Item -Path $tempCheck -ErrorAction SilentlyContinue
    }
    
    # Check fastparquet
    $checkFastparquet = "import sys; import importlib.util; spec = importlib.util.find_spec('fastparquet'); sys.exit(0 if spec else 1)"
    $tempCheck = Join-Path $env:TEMP "python-check-fastparquet-$(Get-Random).py"
    Set-Content -Path $tempCheck -Value $checkFastparquet -Encoding UTF8
    try {
        & $PythonCmd $tempCheck 2>&1 | Out-Null
        $fastparquetAvailable = ($LASTEXITCODE -eq 0)
    }
    catch {
        $fastparquetAvailable = $false
    }
    finally {
        Remove-Item -Path $tempCheck -ErrorAction SilentlyContinue
    }
    
    $bothAvailable = $pyarrowAvailable -and $fastparquetAvailable
    
    # Determine library based on preference
    $selectedLibrary = switch ($preference) {
        'pyarrow' {
            if ($pyarrowAvailable) { 'pyarrow' } else { 'fastparquet' }
        }
        'fastparquet' {
            if ($fastparquetAvailable) { 'fastparquet' } else { 'pyarrow' }
        }
        default {
            # 'auto' or invalid preference
            if ($pyarrowAvailable) { 'pyarrow' } elseif ($fastparquetAvailable) { 'fastparquet' } else { 'pyarrow' }
        }
    }
    
    # Ensure selected library is available
    $isAvailable = if ($selectedLibrary -eq 'pyarrow') { $pyarrowAvailable } else { $fastparquetAvailable }
    
    # If selected library is not available but the other is, use the available one
    if (-not $isAvailable) {
        if ($pyarrowAvailable) {
            $selectedLibrary = 'pyarrow'
            $isAvailable = $true
        }
        elseif ($fastparquetAvailable) {
            $selectedLibrary = 'fastparquet'
            $isAvailable = $true
        }
    }
    
    return @{
        Library              = $selectedLibrary
        Available            = $isAvailable
        BothAvailable        = $bothAvailable
        PyarrowAvailable     = $pyarrowAvailable
        FastparquetAvailable = $fastparquetAvailable
    }
}

<#
.SYNOPSIS
    Gets the preferred scientific data library (netCDF4/h5py or xarray) based on availability and user preference.
.DESCRIPTION
    Determines which scientific data library to use based on:
    1. User preference via $env:PS_SCIENTIFIC_LIB ('netcdf4', 'h5py', 'xarray', or 'auto')
    2. Library availability (checks if packages are installed)
    3. Defaults to 'xarray' if available (as it wraps netCDF4/h5py), then netCDF4/h5py
    
    Returns a hashtable with library information including:
    - Library: 'xarray', 'netcdf4', or 'h5py'
    - Available: $true if the library is available
    - XarrayAvailable: $true if xarray is available
    - Netcdf4Available: $true if netCDF4 is available
    - H5pyAvailable: $true if h5py is available
.PARAMETER PythonCmd
    Optional Python command path. If not provided, uses Get-PythonPath.
.EXAMPLE
    $libInfo = Get-ScientificLibraryPreference
    if ($libInfo.Available) {
        Write-Host "Using $($libInfo.Library)"
    }
.OUTPUTS
    System.Collections.Hashtable
    Hashtable with Library, Available, and availability flags.
#>
function Get-ScientificLibraryPreference {
    param(
        [string]$PythonCmd
    )
    
    # Get Python command if not provided
    if (-not $PythonCmd) {
        $PythonCmd = Get-PythonPath
        if (-not $PythonCmd) {
            return @{
                Library          = 'netcdf4'
                Available        = $false
                XarrayAvailable  = $false
                Netcdf4Available = $false
                H5pyAvailable    = $false
            }
        }
    }
    
    # Check user preference
    $preference = if ($env:PS_SCIENTIFIC_LIB) {
        $env:PS_SCIENTIFIC_LIB.ToLower()
    }
    else {
        'auto'
    }
    
    # Check availability of libraries
    $xarrayAvailable = $false
    $netcdf4Available = $false
    $h5pyAvailable = $false
    
    # Check xarray
    $checkXarray = "import sys; import importlib.util; spec = importlib.util.find_spec('xarray'); sys.exit(0 if spec else 1)"
    $tempCheck = Join-Path $env:TEMP "python-check-xarray-$(Get-Random).py"
    Set-Content -Path $tempCheck -Value $checkXarray -Encoding UTF8
    try {
        & $PythonCmd $tempCheck 2>&1 | Out-Null
        $xarrayAvailable = ($LASTEXITCODE -eq 0)
    }
    catch {
        $xarrayAvailable = $false
    }
    finally {
        Remove-Item -Path $tempCheck -ErrorAction SilentlyContinue
    }
    
    # Check netCDF4
    $checkNetcdf4 = "import sys; import importlib.util; spec = importlib.util.find_spec('netCDF4'); sys.exit(0 if spec else 1)"
    $tempCheck = Join-Path $env:TEMP "python-check-netcdf4-$(Get-Random).py"
    Set-Content -Path $tempCheck -Value $checkNetcdf4 -Encoding UTF8
    try {
        & $PythonCmd $tempCheck 2>&1 | Out-Null
        $netcdf4Available = ($LASTEXITCODE -eq 0)
    }
    catch {
        $netcdf4Available = $false
    }
    finally {
        Remove-Item -Path $tempCheck -ErrorAction SilentlyContinue
    }
    
    # Check h5py
    $checkH5py = "import sys; import importlib.util; spec = importlib.util.find_spec('h5py'); sys.exit(0 if spec else 1)"
    $tempCheck = Join-Path $env:TEMP "python-check-h5py-$(Get-Random).py"
    Set-Content -Path $tempCheck -Value $checkH5py -Encoding UTF8
    try {
        & $PythonCmd $tempCheck 2>&1 | Out-Null
        $h5pyAvailable = ($LASTEXITCODE -eq 0)
    }
    catch {
        $h5pyAvailable = $false
    }
    finally {
        Remove-Item -Path $tempCheck -ErrorAction SilentlyContinue
    }
    
    # Determine library based on preference
    $selectedLibrary = switch ($preference) {
        'xarray' {
            if ($xarrayAvailable) { 'xarray' } elseif ($netcdf4Available) { 'netcdf4' } elseif ($h5pyAvailable) { 'h5py' } else { 'netcdf4' }
        }
        'netcdf4' {
            if ($netcdf4Available) { 'netcdf4' } elseif ($xarrayAvailable) { 'xarray' } elseif ($h5pyAvailable) { 'h5py' } else { 'netcdf4' }
        }
        'h5py' {
            if ($h5pyAvailable) { 'h5py' } elseif ($xarrayAvailable) { 'xarray' } elseif ($netcdf4Available) { 'netcdf4' } else { 'h5py' }
        }
        default {
            # 'auto' - prefer xarray (wraps others), then netCDF4, then h5py
            if ($xarrayAvailable) { 'xarray' }
            elseif ($netcdf4Available) { 'netcdf4' }
            elseif ($h5pyAvailable) { 'h5py' }
            else { 'netcdf4' }
        }
    }
    
    # Ensure selected library is available
    $isAvailable = switch ($selectedLibrary) {
        'xarray' { $xarrayAvailable }
        'netcdf4' { $netcdf4Available }
        'h5py' { $h5pyAvailable }
        default { $false }
    }
    
    # If selected library is not available, try alternatives
    if (-not $isAvailable) {
        if ($xarrayAvailable) {
            $selectedLibrary = 'xarray'
            $isAvailable = $true
        }
        elseif ($netcdf4Available) {
            $selectedLibrary = 'netcdf4'
            $isAvailable = $true
        }
        elseif ($h5pyAvailable) {
            $selectedLibrary = 'h5py'
            $isAvailable = $true
        }
    }
    
    return @{
        Library          = $selectedLibrary
        Available        = $isAvailable
        XarrayAvailable  = $xarrayAvailable
        Netcdf4Available = $netcdf4Available
        H5pyAvailable    = $h5pyAvailable
    }
}

<#
.SYNOPSIS
    Gets installation recommendation message for missing Python packages.
.DESCRIPTION
    Returns a formatted installation recommendation message for one or more Python packages.
    Uses the preferred package manager and formats the message appropriately.
.PARAMETER PackageNames
    One or more package names to include in the recommendation.
.PARAMETER Global
    If true, recommend global installation. If false, recommend local installation.
.PARAMETER PythonCmd
    Optional Python command path.
.EXAMPLE
    $msg = Get-PythonPackageInstallRecommendation -PackageNames 'pandas', 'polars'
    Write-Host $msg
.OUTPUTS
    System.String
    The installation recommendation message.
#>
function Get-PythonPackageInstallRecommendation {
    param(
        [Parameter(Mandatory)]
        [string[]]$PackageNames,
        
        [switch]$Global,
        
        [string]$PythonCmd
    )
    
    $pmInfo = Get-PythonPackageManagerPreference -PythonCmd $PythonCmd
    
    if (-not $pmInfo.Available) {
        $flag = if ($Global) { '' } else { '--user' }
        $packages = $PackageNames -join ' '
        return "pip install $flag $packages".Trim()
    }
    
    $packages = $PackageNames -join ' '
    $installCmd = $pmInfo.InstallCommand -f $packages
    $flag = if ($Global) { $pmInfo.GlobalFlag } else { $pmInfo.LocalFlag }
    
    if ($flag) {
        return "$installCmd $flag".Trim()
    }
    
    return $installCmd
}

