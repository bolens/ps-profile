# ===============================================
# Delta Lake format conversion utilities
# Delta Lake ↔ JSON, Parquet
# ========================================

<#
.SYNOPSIS
    Initializes Delta Lake format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Delta Lake format conversions.
    Delta Lake is an open-source storage layer that brings ACID transactions to Apache Spark and big data workloads.
    Supports bidirectional conversions between Delta Lake tables and JSON, and conversions to Parquet.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Python with delta-spark or delta-rs package to be installed.
#>
function Initialize-FileConversion-BinaryProtocolDelta {
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

    # Delta Lake to JSON
    Set-Item -Path Function:Global:_ConvertFrom-DeltaToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(delta|delta_table)$', '.json' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with delta-spark or delta-rs package to use Delta Lake conversions."
            }
            $pythonScript = @"
import json
import sys
try:
    from delta import DeltaTable
    import pyarrow as pa
except ImportError:
    try:
        from deltalake import DeltaTable
    except ImportError:
        print('Error: delta-spark or deltalake package is not installed. Install with: uv pip install delta-spark or uv pip install deltalake', file=sys.stderr)
        sys.exit(1)

try:
    # Read Delta Lake table
    # Note: Delta Lake tables are directories containing _delta_log and data files
    delta_table = DeltaTable(sys.argv[1])
    
    # Convert to PyArrow table
    table = delta_table.to_pyarrow_table()
    
    # Convert to JSON
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
            $tempScript = Join-Path $env:TEMP "delta-to-json-$(Get-Random).py"
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
            Write-Error "Failed to convert Delta Lake to JSON: $_"
            throw
        }
    } -Force

    # JSON to Delta Lake
    Set-Item -Path Function:Global:_ConvertTo-DeltaFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.delta' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with delta-spark or delta-rs package to use Delta Lake conversions."
            }
            $pythonScript = @"
import json
import sys
import os
try:
    from delta import DeltaTable
    import pyarrow as pa
    from pyarrow import parquet as pq
except ImportError:
    try:
        from deltalake import write_deltalake
        import pyarrow as pa
    except ImportError:
        print('Error: delta-spark or deltalake package is not installed. Install with: uv pip install delta-spark or uv pip install deltalake', file=sys.stderr)
        sys.exit(1)

try:
    # Read JSON file
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    if not data:
        raise ValueError("JSON file is empty")
    
    # Convert to PyArrow table
    if isinstance(data, list) and len(data) > 0:
        arrays = []
        column_names = list(data[0].keys())
        for col_name in column_names:
            col_data = [row.get(col_name) for row in data]
            arrays.append(col_data)
        table = pa.Table.from_arrays(arrays, names=column_names)
    else:
        raise ValueError("JSON must contain a list of objects")
    
    # Write Delta Lake table
    # Create output directory if it doesn't exist
    os.makedirs(sys.argv[2], exist_ok=True)
    
    try:
        # Try delta-spark first
        from delta import DeltaTable
        # Write as Parquet first, then convert to Delta
        parquet_path = os.path.join(sys.argv[2], 'data.parquet')
        pq.write_table(table, parquet_path)
        # Note: Full Delta Lake creation requires Spark - this is a simplified approach
        print('Warning: Full Delta Lake creation requires Spark. Parquet file created instead.', file=sys.stderr)
    except:
        # Try deltalake
        from deltalake import write_deltalake
        write_deltalake(sys.argv[2], table)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "json-to-delta-$(Get-Random).py"
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
            Write-Error "Failed to convert JSON to Delta Lake: $_"
            throw
        }
    } -Force

    # Delta Lake to Parquet
    Set-Item -Path Function:Global:_ConvertFrom-DeltaToParquet -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(delta|delta_table)$', '.parquet' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with delta-spark or delta-rs and pyarrow packages to use Delta Lake conversions."
            }
            $pythonScript = @"
import sys
try:
    from delta import DeltaTable
    import pyarrow.parquet as pq
except ImportError:
    try:
        from deltalake import DeltaTable
        import pyarrow.parquet as pq
    except ImportError:
        print('Error: delta-spark or deltalake and pyarrow packages are not installed. Install with: uv pip install delta-spark pyarrow or uv pip install deltalake pyarrow', file=sys.stderr)
        sys.exit(1)

try:
    # Read Delta Lake table
    delta_table = DeltaTable(sys.argv[1])
    table = delta_table.to_pyarrow_table()
    
    # Write Parquet file
    pq.write_table(table, sys.argv[2])
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "delta-to-parquet-$(Get-Random).py"
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
            Write-Error "Failed to convert Delta Lake to Parquet: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert Delta Lake to JSON
<#
.SYNOPSIS
    Converts Delta Lake table to JSON format.
.DESCRIPTION
    Converts a Delta Lake table to JSON format.
    Requires Python with delta-spark or deltalake package to be installed.
.PARAMETER InputPath
    The path to the Delta Lake table directory.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-DeltaToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-DeltaToJson @PSBoundParameters
}
Set-Alias -Name delta-to-json -Value ConvertFrom-DeltaToJson -ErrorAction SilentlyContinue
Set-Alias -Name deltalake-to-json -Value ConvertFrom-DeltaToJson -ErrorAction SilentlyContinue

# Convert JSON to Delta Lake
<#
.SYNOPSIS
    Converts JSON file to Delta Lake table format.
.DESCRIPTION
    Converts a JSON file to Delta Lake table format.
    Note: Full Delta Lake creation may require Spark. This implementation uses simplified approach.
    Requires Python with delta-spark or deltalake package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output Delta Lake table directory. If not specified, uses input path with .delta extension.
#>
function ConvertTo-DeltaFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-DeltaFromJson @PSBoundParameters
}
Set-Alias -Name json-to-delta -Value ConvertTo-DeltaFromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-deltalake -Value ConvertTo-DeltaFromJson -ErrorAction SilentlyContinue

# Convert Delta Lake to Parquet
<#
.SYNOPSIS
    Converts Delta Lake table to Parquet format.
.DESCRIPTION
    Converts a Delta Lake table to Parquet format.
    Requires Python with delta-spark or deltalake and pyarrow packages to be installed.
.PARAMETER InputPath
    The path to the Delta Lake table directory.
.PARAMETER OutputPath
    The path for the output Parquet file. If not specified, uses input path with .parquet extension.
#>
function ConvertFrom-DeltaToParquet {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-DeltaToParquet @PSBoundParameters
}
Set-Alias -Name delta-to-parquet -Value ConvertFrom-DeltaToParquet -ErrorAction SilentlyContinue
Set-Alias -Name deltalake-to-parquet -Value ConvertFrom-DeltaToParquet -ErrorAction SilentlyContinue

