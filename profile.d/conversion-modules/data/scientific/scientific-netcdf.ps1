# ===============================================
# NetCDF format conversion utilities
# JSON ↔ NetCDF
# ===============================================

<#
.SYNOPSIS
    Initializes NetCDF format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for NetCDF (Network Common Data Form).
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Python with netCDF4 package to be installed.
#>
function Initialize-FileConversion-ScientificNetCdf {
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
        $pythonModulePath = Join-Path $repoRoot 'scripts' 'lib' 'Python.psm1'
        if (Test-Path $pythonModulePath) {
            Import-Module $pythonModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
        }
    }
    # JSON to NetCDF
    Set-Item -Path Function:Global:_ConvertTo-NetCdfFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.nc' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with netCDF4 package to use NetCDF conversions."
            }
            $pythonScript = @"
import json
from netCDF4 import Dataset
import sys
import numpy as np

try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
    
    with Dataset(sys.argv[2], 'w', format='NETCDF4') as nc:
        def store_data(name, obj, parent):
            if isinstance(obj, dict):
                group = parent.createGroup(name)
                for key, value in obj.items():
                    store_data(key, value, group)
            elif isinstance(obj, list):
                if len(obj) > 0 and isinstance(obj[0], (int, float)):
                    var = parent.createVariable(name, 'f8', ('len',))
                    var[:] = np.array(obj)
                else:
                    group = parent.createGroup(name)
                    for i, item in enumerate(obj):
                        store_data(str(i), item, group)
            elif isinstance(obj, (int, float)):
                var = parent.createVariable(name, type(obj).__name__, ())
                var.assignValue(obj)
            elif isinstance(obj, str):
                var = parent.createVariable(name, 'S1', ('len',))
                var[:] = np.array(list(obj.encode('utf-8')))
        
        if isinstance(data, dict):
            for key, value in data.items():
                store_data(key, value, nc)
        else:
            store_data('data', data, nc)
except ImportError:
    print('Error: netCDF4 package is not installed. Install it with: uv pip install netCDF4', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "netcdf-encode-$(Get-Random).py"
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
            Write-Error "Failed to convert JSON to NetCDF: $_"
        }
    } -Force

    # NetCDF to JSON
    Set-Item -Path Function:Global:_ConvertFrom-NetCdfToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.nc$', '.json' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with netCDF4 package to use NetCDF conversions."
            }
            $pythonScript = @"
import json
from netCDF4 import Dataset
import sys
import numpy as np

def extract_data(name, obj):
    from netCDF4 import Dataset
    if isinstance(obj, Dataset):
        result = {}
        for key in obj.groups.keys():
            result[key] = extract_data(key, obj.groups[key])
        for key in obj.variables.keys():
            var = obj.variables[key]
            data = var[:]
            if isinstance(data, np.ndarray):
                if data.dtype.names:
                    result[key] = {name: data[name].tolist() for name in data.dtype.names}
                else:
                    result[key] = data.tolist()
            elif isinstance(data, (np.integer, np.floating)):
                result[key] = data.item()
            elif isinstance(data, bytes):
                result[key] = data.decode('utf-8')
            else:
                result[key] = str(data)
        return result
    return None

try:
    with Dataset(sys.argv[1], 'r') as nc:
        result = extract_data('root', nc)
        with open(sys.argv[2], 'w') as out:
            json.dump(result, out, indent=2, default=str)
except ImportError:
    print('Error: netCDF4 package is not installed. Install it with: uv pip install netCDF4', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "netcdf-decode-$(Get-Random).py"
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
            Write-Error "Failed to convert NetCDF to JSON: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert JSON to NetCDF
<#
.SYNOPSIS
    Converts JSON file to NetCDF format.
.DESCRIPTION
    Converts a JSON file to NetCDF (Network Common Data Form) format.
    Requires Python with netCDF4 package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output NetCDF file. If not specified, uses input path with .nc extension.
#>
function ConvertTo-NetCdfFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-NetCdfFromJson @PSBoundParameters
}
Set-Alias -Name json-to-netcdf -Value ConvertTo-NetCdfFromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-nc -Value ConvertTo-NetCdfFromJson -ErrorAction SilentlyContinue

# Convert NetCDF to JSON
<#
.SYNOPSIS
    Converts NetCDF file to JSON format.
.DESCRIPTION
    Converts a NetCDF (Network Common Data Form) file back to JSON format.
    Requires Python with netCDF4 package to be installed.
.PARAMETER InputPath
    The path to the NetCDF file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-NetCdfToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-NetCdfToJson @PSBoundParameters
}
Set-Alias -Name netcdf-to-json -Value ConvertFrom-NetCdfToJson -ErrorAction SilentlyContinue
Set-Alias -Name nc-to-json -Value ConvertFrom-NetCdfToJson -ErrorAction SilentlyContinue
