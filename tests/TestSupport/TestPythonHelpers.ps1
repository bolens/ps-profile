# ===============================================
# TestPythonHelpers.ps1
# Python package availability testing utilities
# ===============================================

<#
.SYNOPSIS
    Checks if a Python package is available for use.
.DESCRIPTION
    Tests whether a specified Python package can be imported.
    Handles both system Python and UV-managed Python installations.
    Checks for packages installed via uv pip, pip, or in virtual environments.
.PARAMETER PackageName
    The name of the Python package to check (e.g., 'ion-python', 'pyodbc').
.PARAMETER UseUV
    If true, prefers UV for package checking. Default is to try UV first, then fall back to system Python.
.EXAMPLE
    Test-PythonPackageAvailable -PackageName 'ion-python'
    Checks if the ion-python package is available.
.OUTPUTS
    System.Boolean
    Returns $true if the package is available, $false otherwise.
.NOTES
    This function is used by test files to determine if Python packages are installed
    before running tests that depend on them. It automatically detects UV and system Python.
#>
function Test-PythonPackageAvailable {
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,
        
        [switch]$UseUV
    )
    
    # Try UV first if available (preferred method)
    if ($UseUV -or (Get-Command uv -ErrorAction SilentlyContinue)) {
        try {
            # Use uv pip list or uv pip show to check for package
            $uvCheck = & uv pip show $PackageName 2>&1
            if ($LASTEXITCODE -eq 0 -and $uvCheck) {
                return $true
            }
        }
        catch {
            # Fall through to try system Python
        }
    }
    
    # Try system Python (via Get-PythonPath if available)
    $pythonCmd = $null
    if (Get-Command Get-PythonPath -ErrorAction SilentlyContinue) {
        try {
            $pythonCmd = Get-PythonPath
        }
        catch {
            # Fall through to direct command check
        }
    }
    
    # Fall back to direct command check
    if (-not $pythonCmd) {
        if (Get-Command python -ErrorAction SilentlyContinue) {
            $pythonCmd = 'python'
        }
        elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
            $pythonCmd = 'python3'
        }
    }
    
    if (-not $pythonCmd) {
        return $false
    }
    
    # Check if package is available using Python's importlib
    $checkScript = "import sys; import importlib.util; spec = importlib.util.find_spec('$PackageName'); sys.exit(0 if spec else 1)"
    $tempCheck = Join-Path $env:TEMP "python-check-$(Get-Random).py"
    Set-Content -Path $tempCheck -Value $checkScript -Encoding UTF8
    try {
        & $pythonCmd $tempCheck 2>&1 | Out-Null
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        return $false
    }
    finally {
        Remove-Item -Path $tempCheck -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Gets installation recommendation for a missing Python package.
.DESCRIPTION
    Returns installation instructions for a Python package, similar to how npm packages
    provide installation recommendations. Supports both uv pip and standard pip.
.PARAMETER PackageName
    The name of the Python package (e.g., 'pandas', 'polars').
.PARAMETER UseUV
    If true, prefers UV for installation recommendations. Default is to detect UV availability.
.EXAMPLE
    Get-PythonPackageInstallRecommendation -PackageName 'pandas'
    Returns installation command for pandas.
.OUTPUTS
    System.String
    Installation command recommendation.
#>
function Get-PythonPackageInstallRecommendation {
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,
        
        [switch]$UseUV
    )
    
    # Check if UV is available
    $hasUV = (Get-Command uv -ErrorAction SilentlyContinue) -ne $null
    
    if ($UseUV -or $hasUV) {
        return "uv pip install $PackageName"
    }
    else {
        return "pip install $PackageName"
    }
}

