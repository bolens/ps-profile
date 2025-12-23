# ===============================================
# Apache ORC format conversion utilities
# ORC ↔ JSON, CSV, Parquet
# ========================================

<#
.SYNOPSIS
    Initializes Apache ORC format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Apache ORC (Optimized Row Columnar) format.
    ORC is a columnar storage format optimized for reading, writing, and processing data.
    Supports bidirectional conversions between ORC and JSON, CSV, and Parquet formats.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Python with pyarrow package to be installed.
#>
function Initialize-FileConversion-BinaryProtocolOrc {
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

    # ORC to JSON
    Set-Item -Path Function:Global:_ConvertFrom-OrcToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.orc$', '.json' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pyarrow package to use ORC conversions."
            }
            $pythonScript = @"
import json
import sys
try:
    import pyarrow.orc as orc
    import pyarrow as pa
except ImportError:
    print('Error: pyarrow package is not installed. Install it with: uv pip install pyarrow', file=sys.stderr)
    sys.exit(1)

try:
    # Read ORC file
    orc_file = orc.ORCFile(sys.argv[1])
    table = orc_file.read()
    
    # Convert to JSON
    # Convert PyArrow table to list of dictionaries
    data = []
    column_names = table.column_names
    for i in range(table.num_rows):
        row = {}
        for j, col_name in enumerate(column_names):
            row[col_name] = table.column(j)[i].as_py()
        data.append(row)
    
    with open(sys.argv[2], 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, default=str, ensure_ascii=False)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "orc-to-json-$(Get-Random).py"
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
            Write-Error "Failed to convert ORC to JSON: $_"
            throw
        }
    } -Force

    # JSON to ORC
    Set-Item -Path Function:Global:_ConvertTo-OrcFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.orc' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pyarrow package to use ORC conversions."
            }
            $pythonScript = @"
import json
import sys
try:
    import pyarrow.orc as orc
    import pyarrow as pa
except ImportError:
    print('Error: pyarrow package is not installed. Install it with: uv pip install pyarrow', file=sys.stderr)
    sys.exit(1)

try:
    # Read JSON file
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    if not data:
        raise ValueError("JSON file is empty")
    
    # Convert to PyArrow table
    if isinstance(data, list) and len(data) > 0:
        # List of dictionaries
        arrays = []
        column_names = list(data[0].keys())
        for col_name in column_names:
            col_data = [row.get(col_name) for row in data]
            arrays.append(col_data)
        table = pa.Table.from_arrays(arrays, names=column_names)
    else:
        raise ValueError("JSON must contain a list of objects")
    
    # Write ORC file
    orc.write_table(table, sys.argv[2])
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "json-to-orc-$(Get-Random).py"
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
            Write-Error "Failed to convert JSON to ORC: $_"
            throw
        }
    } -Force

    # ORC to CSV
    Set-Item -Path Function:Global:_ConvertFrom-OrcToCsv -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.orc$', '.csv' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pyarrow package to use ORC conversions."
            }
            $pythonScript = @"
import csv
import sys
try:
    import pyarrow.orc as orc
    import pyarrow as pa
except ImportError:
    print('Error: pyarrow package is not installed. Install it with: uv pip install pyarrow', file=sys.stderr)
    sys.exit(1)

try:
    # Read ORC file
    orc_file = orc.ORCFile(sys.argv[1])
    table = orc_file.read()
    
    # Convert to CSV
    column_names = table.column_names
    with open(sys.argv[2], 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(column_names)
        for i in range(table.num_rows):
            row = [table.column(j)[i].as_py() for j in range(len(column_names))]
            writer.writerow(row)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "orc-to-csv-$(Get-Random).py"
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
            Write-Error "Failed to convert ORC to CSV: $_"
            throw
        }
    } -Force

    # ORC to Parquet
    Set-Item -Path Function:Global:_ConvertFrom-OrcToParquet -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.orc$', '.parquet' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pyarrow package to use ORC conversions."
            }
            $pythonScript = @"
import sys
try:
    import pyarrow.orc as orc
    import pyarrow.parquet as pq
except ImportError:
    print('Error: pyarrow package is not installed. Install it with: uv pip install pyarrow', file=sys.stderr)
    sys.exit(1)

try:
    # Read ORC file
    orc_file = orc.ORCFile(sys.argv[1])
    table = orc_file.read()
    
    # Write Parquet file
    pq.write_table(table, sys.argv[2])
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "orc-to-parquet-$(Get-Random).py"
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
            Write-Error "Failed to convert ORC to Parquet: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert ORC to JSON
<#
.SYNOPSIS
    Converts Apache ORC file to JSON format.
.DESCRIPTION
    Converts an Apache ORC (Optimized Row Columnar) file to JSON format.
    Requires Python with pyarrow package to be installed.
.PARAMETER InputPath
    The path to the ORC file (.orc extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-OrcToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-OrcToJson @PSBoundParameters
}
Set-Alias -Name orc-to-json -Value ConvertFrom-OrcToJson -ErrorAction SilentlyContinue

# Convert JSON to ORC
<#
.SYNOPSIS
    Converts JSON file to Apache ORC format.
.DESCRIPTION
    Converts a JSON file to Apache ORC (Optimized Row Columnar) format.
    Requires Python with pyarrow package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output ORC file. If not specified, uses input path with .orc extension.
#>
function ConvertTo-OrcFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-OrcFromJson @PSBoundParameters
}
Set-Alias -Name json-to-orc -Value ConvertTo-OrcFromJson -ErrorAction SilentlyContinue

# Convert ORC to CSV
<#
.SYNOPSIS
    Converts Apache ORC file to CSV format.
.DESCRIPTION
    Converts an Apache ORC file to CSV format.
    Requires Python with pyarrow package to be installed.
.PARAMETER InputPath
    The path to the ORC file (.orc extension).
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
#>
function ConvertFrom-OrcToCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-OrcToCsv @PSBoundParameters
}
Set-Alias -Name orc-to-csv -Value ConvertFrom-OrcToCsv -ErrorAction SilentlyContinue

# Convert ORC to Parquet
<#
.SYNOPSIS
    Converts Apache ORC file to Parquet format.
.DESCRIPTION
    Converts an Apache ORC file to Parquet format.
    Requires Python with pyarrow package to be installed.
.PARAMETER InputPath
    The path to the ORC file (.orc extension).
.PARAMETER OutputPath
    The path for the output Parquet file. If not specified, uses input path with .parquet extension.
#>
function ConvertFrom-OrcToParquet {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-OrcToParquet @PSBoundParameters
}
Set-Alias -Name orc-to-parquet -Value ConvertFrom-OrcToParquet -ErrorAction SilentlyContinue

