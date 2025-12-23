# ===============================================
# FITS format conversion utilities
# FITS ↔ JSON, CSV
# ===============================================

<#
.SYNOPSIS
    Initializes FITS format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for FITS (Flexible Image Transport System) format.
    FITS is commonly used in astronomy for storing images and data tables.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Python with astropy package to be installed.
#>
function Initialize-FileConversion-ScientificFits {
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
    # FITS to JSON
    Set-Item -Path Function:Global:_ConvertFrom-FitsToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(fits|fit)$', '.json' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with astropy package to use FITS conversions."
            }
            $pythonScript = @"
import json
import sys
from astropy.io import fits

try:
    with fits.open(sys.argv[1]) as hdul:
        result = {
            'header': {},
            'data': []
        }
        
        # Extract header information
        if len(hdul) > 0:
            header = hdul[0].header
            result['header'] = dict(header)
        
        # Extract data from all HDUs
        for i, hdu in enumerate(hdul):
            if hdu.data is not None:
                if hasattr(hdu.data, 'tolist'):
                    data_item = {
                        'hdu_index': i,
                        'data': hdu.data.tolist()
                    }
                    if hasattr(hdu.data, 'shape'):
                        data_item['shape'] = hdu.data.shape
                    result['data'].append(data_item)
                elif hasattr(hdu, 'data'):
                    # For table HDUs
                    if hasattr(hdu.data, 'columns'):
                        table_data = []
                        for row in hdu.data:
                            row_dict = {}
                            for col in hdu.data.columns.names:
                                val = row[col]
                                if hasattr(val, 'tolist'):
                                    row_dict[col] = val.tolist()
                                else:
                                    row_dict[col] = str(val)
                            table_data.append(row_dict)
                        result['data'].append({
                            'hdu_index': i,
                            'type': 'table',
                            'columns': list(hdu.data.columns.names),
                            'rows': table_data
                        })
        
        with open(sys.argv[2], 'w') as f:
            json.dump(result, f, indent=2, default=str)
except ImportError:
    print('Error: astropy package is not installed. Install it with: uv pip install astropy', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "fits-decode-$(Get-Random).py"
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
            Write-Error "Failed to convert FITS to JSON: $_"
            throw
        }
    } -Force

    # JSON to FITS
    Set-Item -Path Function:Global:_ConvertTo-FitsFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.fits' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with astropy package to use FITS conversions."
            }
            $pythonScript = @"
import json
import sys
import numpy as np
from astropy.io import fits

try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
    
    hdul = fits.HDUList()
    
    # Create primary HDU with header
    if 'header' in data and data['header']:
        primary_hdu = fits.PrimaryHDU()
        for key, value in data['header'].items():
            if len(str(key)) <= 8 and len(str(value)) <= 70:
                primary_hdu.header[key] = value
        hdul.append(primary_hdu)
    else:
        hdul.append(fits.PrimaryHDU())
    
    # Add data HDUs
    if 'data' in data and isinstance(data['data'], list):
        for data_item in data['data']:
            if 'data' in data_item:
                array_data = np.array(data_item['data'])
                hdu = fits.ImageHDU(data=array_data)
                hdul.append(hdu)
            elif 'type' in data_item and data_item['type'] == 'table' and 'rows' in data_item:
                # Create table HDU
                rows = data_item['rows']
                if rows:
                    cols = data_item.get('columns', list(rows[0].keys()) if rows else [])
                    col_defs = []
                    for col in cols:
                        # Infer data type from first row
                        if rows:
                            first_val = rows[0].get(col, 0)
                            if isinstance(first_val, (int, float)):
                                col_defs.append(fits.Column(name=col, format='D', array=[r.get(col, 0) for r in rows]))
                            else:
                                col_defs.append(fits.Column(name=col, format='A', array=[str(r.get(col, '')) for r in rows]))
                    if col_defs:
                        table_hdu = fits.BinTableHDU.from_columns(col_defs)
                        hdul.append(table_hdu)
    
    hdul.writeto(sys.argv[2], overwrite=True)
except ImportError:
    print('Error: astropy package is not installed. Install it with: uv pip install astropy', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "fits-encode-$(Get-Random).py"
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
            Write-Error "Failed to convert JSON to FITS: $_"
            throw
        }
    } -Force

    # FITS to CSV
    Set-Item -Path Function:Global:_ConvertFrom-FitsToCsv -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(fits|fit)$', '.csv' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with astropy package to use FITS conversions."
            }
            $pythonScript = @"
import sys
import csv
from astropy.io import fits

try:
    with fits.open(sys.argv[1]) as hdul:
        # Find first table HDU
        table_hdu = None
        for hdu in hdul:
            if isinstance(hdu, fits.BinTableHDU) or isinstance(hdu, fits.TableHDU):
                table_hdu = hdu
                break
        
        if table_hdu is None:
            # If no table found, try to convert image data
            if len(hdul) > 0 and hdul[0].data is not None:
                data = hdul[0].data
                if hasattr(data, 'flatten'):
                    # Flatten 2D array to CSV
                    flat_data = data.flatten()
                    with open(sys.argv[2], 'w', newline='') as f:
                        writer = csv.writer(f)
                        writer.writerow(['value'])
                        for val in flat_data:
                            writer.writerow([val])
                else:
                    raise ValueError("No table data found in FITS file")
            else:
                raise ValueError("No data found in FITS file")
        else:
            # Write table to CSV
            with open(sys.argv[2], 'w', newline='') as f:
                writer = csv.writer(f)
                # Write header
                writer.writerow(table_hdu.data.columns.names)
                # Write rows
                for row in table_hdu.data:
                    writer.writerow([row[col] for col in table_hdu.data.columns.names])
except ImportError:
    print('Error: astropy package is not installed. Install it with: uv pip install astropy', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "fits-to-csv-$(Get-Random).py"
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
            Write-Error "Failed to convert FITS to CSV: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert FITS to JSON
<#
.SYNOPSIS
    Converts FITS file to JSON format.
.DESCRIPTION
    Converts a FITS (Flexible Image Transport System) file to JSON format.
    FITS is commonly used in astronomy for storing images and data tables.
    Requires Python with astropy package to be installed.
.PARAMETER InputPath
    The path to the FITS file (.fits or .fit extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-FitsToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-FitsToJson @PSBoundParameters
}
Set-Alias -Name fits-to-json -Value ConvertFrom-FitsToJson -ErrorAction SilentlyContinue
Set-Alias -Name fit-to-json -Value ConvertFrom-FitsToJson -ErrorAction SilentlyContinue

# Convert JSON to FITS
<#
.SYNOPSIS
    Converts JSON file to FITS format.
.DESCRIPTION
    Converts a JSON file to FITS (Flexible Image Transport System) format.
    Requires Python with astropy package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output FITS file. If not specified, uses input path with .fits extension.
#>
function ConvertTo-FitsFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-FitsFromJson @PSBoundParameters
}
Set-Alias -Name json-to-fits -Value ConvertTo-FitsFromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-fit -Value ConvertTo-FitsFromJson -ErrorAction SilentlyContinue

# Convert FITS to CSV
<#
.SYNOPSIS
    Converts FITS file to CSV format.
.DESCRIPTION
    Converts a FITS (Flexible Image Transport System) file to CSV format.
    Extracts table data from FITS HDUs and writes to CSV.
    Requires Python with astropy package to be installed.
.PARAMETER InputPath
    The path to the FITS file (.fits or .fit extension).
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
#>
function ConvertFrom-FitsToCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-FitsToCsv @PSBoundParameters
}
Set-Alias -Name fits-to-csv -Value ConvertFrom-FitsToCsv -ErrorAction SilentlyContinue
Set-Alias -Name fit-to-csv -Value ConvertFrom-FitsToCsv -ErrorAction SilentlyContinue

