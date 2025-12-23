# ===============================================
# HDF5 format conversion utilities
# JSON ↔ HDF5
# ===============================================

<#
.SYNOPSIS
    Initializes HDF5 format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for HDF5 (Hierarchical Data Format version 5).
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Python with h5py package to be installed.
#>
function Initialize-FileConversion-ScientificHdf5 {
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
    # JSON to HDF5
    Set-Item -Path Function:Global:_ConvertTo-Hdf5FromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.h5' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with h5py package to use HDF5 conversions."
            }
            $pythonScript = @"
import json
import h5py
import sys
import numpy as np

try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
    
    with h5py.File(sys.argv[2], 'w') as f:
        def store_data(name, obj, parent):
            if isinstance(obj, dict):
                group = parent.create_group(name)
                for key, value in obj.items():
                    store_data(key, value, group)
            elif isinstance(obj, list):
                if len(obj) > 0 and isinstance(obj[0], (int, float)):
                    parent.create_dataset(name, data=np.array(obj))
                else:
                    group = parent.create_group(name)
                    for i, item in enumerate(obj):
                        store_data(str(i), item, group)
            elif isinstance(obj, (int, float)):
                parent.create_dataset(name, data=obj)
            elif isinstance(obj, str):
                parent.create_dataset(name, data=obj)
            else:
                parent.create_dataset(name, data=str(obj))
        
        if isinstance(data, dict):
            for key, value in data.items():
                store_data(key, value, f)
        else:
            store_data('data', data, f)
except ImportError:
    print('Error: h5py package is not installed. Install it with: uv pip install h5py', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "hdf5-encode-$(Get-Random).py"
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
            Write-Error "Failed to convert JSON to HDF5: $_"
        }
    } -Force

    # HDF5 to JSON
    Set-Item -Path Function:Global:_ConvertFrom-Hdf5ToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.h5$', '.json' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with h5py package to use HDF5 conversions."
            }
            $pythonScript = @"
import json
import h5py
import sys
import numpy as np

def extract_data(name, obj):
    if isinstance(obj, h5py.Group):
        result = {}
        for key in obj.keys():
            result[key] = extract_data(key, obj[key])
        return result
    elif isinstance(obj, h5py.Dataset):
        data = obj[()]
        if isinstance(data, np.ndarray):
            if data.dtype.names:
                return {name: data[name].tolist() for name in data.dtype.names}
            else:
                return data.tolist()
        elif isinstance(data, (np.integer, np.floating)):
            return data.item()
        elif isinstance(data, bytes):
            return data.decode('utf-8')
        else:
            return str(data)
    return None

try:
    with h5py.File(sys.argv[1], 'r') as f:
        result = extract_data('root', f)
        with open(sys.argv[2], 'w') as out:
            json.dump(result, out, indent=2, default=str)
except ImportError:
    print('Error: h5py package is not installed. Install it with: uv pip install h5py', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "hdf5-decode-$(Get-Random).py"
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
            Write-Error "Failed to convert HDF5 to JSON: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert JSON to HDF5
<#
.SYNOPSIS
    Converts JSON file to HDF5 format.
.DESCRIPTION
    Converts a JSON file to HDF5 (Hierarchical Data Format version 5) format.
    Requires Python with h5py package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output HDF5 file. If not specified, uses input path with .h5 extension.
#>
function ConvertTo-Hdf5FromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-Hdf5FromJson @PSBoundParameters
}
Set-Alias -Name json-to-hdf5 -Value ConvertTo-Hdf5FromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-h5 -Value ConvertTo-Hdf5FromJson -ErrorAction SilentlyContinue

# Convert HDF5 to JSON
<#
.SYNOPSIS
    Converts HDF5 file to JSON format.
.DESCRIPTION
    Converts an HDF5 (Hierarchical Data Format version 5) file back to JSON format.
    Requires Python with h5py package to be installed.
.PARAMETER InputPath
    The path to the HDF5 file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-Hdf5ToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Hdf5ToJson @PSBoundParameters
}
Set-Alias -Name hdf5-to-json -Value ConvertFrom-Hdf5ToJson -ErrorAction SilentlyContinue
Set-Alias -Name h5-to-json -Value ConvertFrom-Hdf5ToJson -ErrorAction SilentlyContinue
