# ===============================================
# MATLAB .mat format conversion utilities
# MATLAB .mat ↔ JSON, CSV
# ===============================================

<#
.SYNOPSIS
    Initializes MATLAB .mat format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for MATLAB .mat file format.
    MATLAB .mat files store variables and data structures.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Python with scipy package to be installed.
#>
function Initialize-FileConversion-ScientificMatlab {
    # Ensure Python module is imported (use repo root from bootstrap if available)
    if (-not (Get-Command Get-PythonPath -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Variable -Name 'RepoRoot' -Scope Script -ErrorAction SilentlyContinue) {
            $script:RepoRoot
        }
        elseif (Get-Variable -Name 'BootstrapRoot' -Scope Script -ErrorAction SilentlyContinue) {
            Split-Path -Parent $script:BootstrapRoot
        }
        else {
            Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
        }
        $pythonModulePath = Join-Path $repoRoot 'scripts' 'lib' 'runtime' 'Python.psm1'
        if ($pythonModulePath -and -not [string]::IsNullOrWhiteSpace($pythonModulePath) -and (Test-Path -LiteralPath $pythonModulePath)) {
            Import-Module $pythonModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
        }
    }
    # MATLAB .mat to JSON
    Set-Item -Path Function:Global:_ConvertFrom-MatlabToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.mat$', '.json' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with scipy package to use MATLAB .mat conversions."
            }
            $pythonScript = @"
import json
import sys
import numpy as np
from scipy.io import loadmat

def convert_to_serializable(obj):
    """Convert numpy arrays and types to JSON-serializable types."""
    if isinstance(obj, np.ndarray):
        return obj.tolist()
    elif isinstance(obj, (np.integer, np.int8, np.int16, np.int32, np.int64)):
        return int(obj)
    elif isinstance(obj, (np.floating, np.float16, np.float32, np.float64)):
        return float(obj)
    elif isinstance(obj, np.bool_):
        return bool(obj)
    elif isinstance(obj, np.str_):
        return str(obj)
    elif isinstance(obj, dict):
        return {key: convert_to_serializable(value) for key, value in obj.items()}
    elif isinstance(obj, (list, tuple)):
        return [convert_to_serializable(item) for item in obj]
    elif isinstance(obj, np.void):
        # Structured array
        return {key: convert_to_serializable(obj[key]) for key in obj.dtype.names}
    else:
        return str(obj)

try:
    mat_data = loadmat(sys.argv[1])
    
    # Remove MATLAB metadata keys (keys starting with '__')
    result = {}
    for key, value in mat_data.items():
        if not key.startswith('__'):
            result[key] = convert_to_serializable(value)
    
    with open(sys.argv[2], 'w') as f:
        json.dump(result, f, indent=2, default=str)
except ImportError:
    print('Error: scipy package is not installed. Install it with: uv pip install scipy', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "matlab-decode-$(Get-Random).py"
            Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
            try {
                $result = & $pythonCmd $tempScript $InputPath $OutputPath 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Python script failed: $result"
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert MATLAB .mat to JSON: $_"
            throw
        }
    } -Force

    # JSON to MATLAB .mat
    Set-Item -Path Function:Global:_ConvertTo-MatlabFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.mat' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with scipy package to use MATLAB .mat conversions."
            }
            $pythonScript = @"
import json
import sys
import numpy as np
from scipy.io import savemat

try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
    
    # Convert lists to numpy arrays where appropriate
    def convert_to_numpy(obj):
        if isinstance(obj, dict):
            return {key: convert_to_numpy(value) for key, value in obj.items()}
        elif isinstance(obj, list):
            # Check if list contains numbers (convert to array)
            if len(obj) > 0 and isinstance(obj[0], (int, float)):
                return np.array(obj)
            elif len(obj) > 0 and isinstance(obj[0], list):
                # 2D array
                return np.array(obj)
            else:
                return [convert_to_numpy(item) for item in obj]
        elif isinstance(obj, (int, float)):
            return obj
        else:
            return obj
    
    mat_data = convert_to_numpy(data)
    savemat(sys.argv[2], mat_data)
except ImportError:
    print('Error: scipy package is not installed. Install it with: uv pip install scipy', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "matlab-encode-$(Get-Random).py"
            Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
            try {
                $result = & $pythonCmd $tempScript $InputPath $OutputPath 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Python script failed: $result"
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert JSON to MATLAB .mat: $_"
            throw
        }
    } -Force

    # MATLAB .mat to CSV
    Set-Item -Path Function:Global:_ConvertFrom-MatlabToCsv -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$VariableName)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.mat$', '.csv' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with scipy package to use MATLAB .mat conversions."
            }
            $pythonScript = @"
import sys
import csv
import numpy as np
from scipy.io import loadmat

try:
    mat_data = loadmat(sys.argv[1])
    
    # Get variable name from command line or use first non-metadata variable
    var_name = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else None
    
    if var_name and var_name in mat_data:
        data = mat_data[var_name]
    else:
        # Find first non-metadata variable
        data = None
        for key, value in mat_data.items():
            if not key.startswith('__'):
                data = value
                var_name = key
                break
    
    if data is None:
        raise ValueError("No data found in MATLAB file")
    
    # Convert to 2D array if needed
    if isinstance(data, np.ndarray):
        if data.ndim == 1:
            data = data.reshape(-1, 1)
        elif data.ndim > 2:
            data = data.flatten().reshape(-1, 1)
    
    # Write to CSV
    with open(sys.argv[2], 'w', newline='') as f:
        writer = csv.writer(f)
        # Write header
        if data.shape[1] == 1:
            writer.writerow([var_name])
        else:
            writer.writerow([f'{var_name}_col{i}' for i in range(data.shape[1])])
        # Write data
        for row in data:
            writer.writerow(row.tolist())
except ImportError:
    print('Error: scipy package is not installed. Install it with: uv pip install scipy', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "matlab-to-csv-$(Get-Random).py"
            Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
            try {
                $args = @($InputPath, $OutputPath)
                if ($VariableName) {
                    $args += $VariableName
                }
                $result = & $pythonCmd $tempScript $args 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Python script failed: $result"
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert MATLAB .mat to CSV: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert MATLAB .mat to JSON
<#
.SYNOPSIS
    Converts MATLAB .mat file to JSON format.
.DESCRIPTION
    Converts a MATLAB .mat file to JSON format.
    MATLAB .mat files store variables and data structures.
    Requires Python with scipy package to be installed.
.PARAMETER InputPath
    The path to the MATLAB .mat file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-MatlabToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-MatlabToJson @PSBoundParameters
}
Set-Alias -Name matlab-to-json -Value ConvertFrom-MatlabToJson -ErrorAction SilentlyContinue
Set-Alias -Name mat-to-json -Value ConvertFrom-MatlabToJson -ErrorAction SilentlyContinue

# Convert JSON to MATLAB .mat
<#
.SYNOPSIS
    Converts JSON file to MATLAB .mat format.
.DESCRIPTION
    Converts a JSON file to MATLAB .mat format.
    Requires Python with scipy package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output MATLAB .mat file. If not specified, uses input path with .mat extension.
#>
function ConvertTo-MatlabFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-MatlabFromJson @PSBoundParameters
}
Set-Alias -Name json-to-matlab -Value ConvertTo-MatlabFromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-mat -Value ConvertTo-MatlabFromJson -ErrorAction SilentlyContinue

# Convert MATLAB .mat to CSV
<#
.SYNOPSIS
    Converts MATLAB .mat file to CSV format.
.DESCRIPTION
    Converts a MATLAB .mat file to CSV format.
    Extracts a variable from the .mat file and writes it to CSV.
    Requires Python with scipy package to be installed.
.PARAMETER InputPath
    The path to the MATLAB .mat file.
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
.PARAMETER VariableName
    Optional. Name of the variable to extract. If not specified, uses the first non-metadata variable.
#>
function ConvertFrom-MatlabToCsv {
    param([string]$InputPath, [string]$OutputPath, [string]$VariableName)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-MatlabToCsv @PSBoundParameters
}
Set-Alias -Name matlab-to-csv -Value ConvertFrom-MatlabToCsv -ErrorAction SilentlyContinue
Set-Alias -Name mat-to-csv -Value ConvertFrom-MatlabToCsv -ErrorAction SilentlyContinue

