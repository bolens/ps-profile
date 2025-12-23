# ===============================================
# DBF (dBase) format conversion utilities
# DBF ↔ JSON, CSV
# ===============================================

<#
.SYNOPSIS
    Initializes DBF (dBase) format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for DBF (dBase) file format.
    DBF is a database file format used by dBase and other database systems.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Python with dbfread or dbf package to be installed.
#>
function Initialize-FileConversion-DatabaseDbf {
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
    # DBF to JSON
    Set-Item -Path Function:Global:_ConvertFrom-DbfToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.dbf$', '.json' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with dbfread or dbf package to use DBF conversions."
            }
            $pythonScript = @"
import json
import sys

try:
    # Try dbfread first (more reliable)
    try:
        from dbfread import DBF
        dbf = DBF(sys.argv[1], encoding='utf-8')
        records = []
        for record in dbf:
            records.append(dict(record))
        result = {
            'data': records,
            'columns': list(dbf.field_names) if hasattr(dbf, 'field_names') else (list(records[0].keys()) if records else [])
        }
    except ImportError:
        # Fallback to dbf package
        try:
            import dbf
            table = dbf.Table(sys.argv[1])
            table.open()
            records = []
            for record in table:
                records.append(dict(record))
            table.close()
            result = {
                'data': records,
                'columns': list(table.field_names) if hasattr(table, 'field_names') else (list(records[0].keys()) if records else [])
            }
        except ImportError:
            raise ImportError("Neither dbfread nor dbf package is available")
    
    with open(sys.argv[2], 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, default=str, ensure_ascii=False)
except ImportError as e:
    if 'dbfread' in str(e) or 'dbf' in str(e):
        print('Error: dbfread or dbf package is not installed. Install with: uv pip install dbfread', file=sys.stderr)
    else:
        print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "dbf-decode-$(Get-Random).py"
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
            Write-Error "Failed to convert DBF to JSON: $_"
            throw
        }
    } -Force

    # JSON to DBF
    Set-Item -Path Function:Global:_ConvertTo-DbfFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.dbf' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with dbf package to use DBF conversions."
            }
            $pythonScript = @"
import json
import sys

try:
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Extract data and columns
    if isinstance(data, dict) and 'data' in data:
        records = data['data']
        columns = data.get('columns', list(records[0].keys()) if records else [])
    elif isinstance(data, list):
        records = data
        columns = list(records[0].keys()) if records else []
    else:
        raise ValueError("JSON must contain a 'data' array or be a list of records")
    
    # Use dbf package for writing
    try:
        import dbf
        
        # Create table structure
        field_defs = []
        if records:
            first_record = records[0]
            for col in columns:
                # Infer field type from first value
                val = first_record.get(col, '')
                if isinstance(val, (int, float)):
                    field_defs.append(f"{col} N(10,2)")
                elif isinstance(val, bool):
                    field_defs.append(f"{col} L")
                elif isinstance(val, str):
                    max_len = max([len(str(r.get(col, ''))) for r in records] + [len(col), 10])
                    field_defs.append(f"{col} C({min(max_len, 254)})")
                else:
                    field_defs.append(f"{col} C(100)")
        
        if field_defs:
            table = dbf.Table(sys.argv[2], field_defs, codepage='utf8')
            table.open(mode=dbf.READ_WRITE)
            for record in records:
                row = tuple(record.get(col, '') for col in columns)
                table.append(row)
            table.close()
        else:
            raise ValueError("No data to write")
    except ImportError:
        raise ImportError("dbf package is required for writing DBF files. Install with: uv pip install dbf")
except ImportError as e:
    if 'dbf' in str(e):
        print('Error: dbf package is not installed. Install with: uv pip install dbf', file=sys.stderr)
    else:
        print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "dbf-encode-$(Get-Random).py"
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
            Write-Error "Failed to convert JSON to DBF: $_"
            throw
        }
    } -Force

    # DBF to CSV
    Set-Item -Path Function:Global:_ConvertFrom-DbfToCsv -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.dbf$', '.csv' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with dbfread or dbf package to use DBF conversions."
            }
            $pythonScript = @"
import sys
import csv

try:
    # Try dbfread first
    try:
        from dbfread import DBF
        dbf = DBF(sys.argv[1], encoding='utf-8')
        with open(sys.argv[2], 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            # Write header
            if hasattr(dbf, 'field_names'):
                writer.writerow(dbf.field_names)
            else:
                # Get field names from first record
                first_record = next(iter(dbf), None)
                if first_record:
                    writer.writerow(list(first_record.keys()))
                    # Reset iterator
                    dbf = DBF(sys.argv[1], encoding='utf-8')
            
            # Write rows
            for record in dbf:
                writer.writerow([record.get(field, '') for field in (dbf.field_names if hasattr(dbf, 'field_names') else list(record.keys()))])
    except ImportError:
        # Fallback to dbf package
        try:
            import dbf
            table = dbf.Table(sys.argv[1])
            table.open()
            with open(sys.argv[2], 'w', newline='', encoding='utf-8') as f:
                writer = csv.writer(f)
                # Write header
                writer.writerow(table.field_names)
                # Write rows
                for record in table:
                    writer.writerow(list(record))
            table.close()
        except ImportError:
            raise ImportError("Neither dbfread nor dbf package is available")
except ImportError as e:
    if 'dbfread' in str(e) or 'dbf' in str(e):
        print('Error: dbfread or dbf package is not installed. Install with: uv pip install dbfread', file=sys.stderr)
    else:
        print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "dbf-to-csv-$(Get-Random).py"
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
            Write-Error "Failed to convert DBF to CSV: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert DBF to JSON
<#
.SYNOPSIS
    Converts DBF file to JSON format.
.DESCRIPTION
    Converts a DBF (dBase) file to JSON format.
    Requires Python with dbfread or dbf package to be installed.
.PARAMETER InputPath
    The path to the DBF file (.dbf extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-DbfToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-DbfToJson @PSBoundParameters
}
Set-Alias -Name dbf-to-json -Value ConvertFrom-DbfToJson -ErrorAction SilentlyContinue

# Convert JSON to DBF
<#
.SYNOPSIS
    Converts JSON file to DBF format.
.DESCRIPTION
    Converts a JSON file to DBF (dBase) format.
    Requires Python with dbf package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output DBF file. If not specified, uses input path with .dbf extension.
#>
function ConvertTo-DbfFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-DbfFromJson @PSBoundParameters
}
Set-Alias -Name json-to-dbf -Value ConvertTo-DbfFromJson -ErrorAction SilentlyContinue

# Convert DBF to CSV
<#
.SYNOPSIS
    Converts DBF file to CSV format.
.DESCRIPTION
    Converts a DBF (dBase) file to CSV format.
    Requires Python with dbfread or dbf package to be installed.
.PARAMETER InputPath
    The path to the DBF file (.dbf extension).
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
#>
function ConvertFrom-DbfToCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-DbfToCsv @PSBoundParameters
}
Set-Alias -Name dbf-to-csv -Value ConvertFrom-DbfToCsv -ErrorAction SilentlyContinue

