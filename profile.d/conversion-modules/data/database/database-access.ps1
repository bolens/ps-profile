# ===============================================
# Microsoft Access database format conversion utilities
# MDB/ACCDB ↔ JSON, CSV
# ===============================================

<#
.SYNOPSIS
    Initializes Microsoft Access database format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Microsoft Access database formats (.mdb, .accdb).
    MDB is the older Access format, ACCDB is the newer format.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Python with pyodbc or mdb-tools (for MDB) to be installed.
    On Windows, may also use Microsoft Access Database Engine (ACE).
#>
function Initialize-FileConversion-DatabaseAccess {
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
    # MDB/ACCDB to JSON
    Set-Item -Path Function:Global:_ConvertFrom-AccessToJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$TableName)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(mdb|accdb)$', '.json' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pyodbc package to use Access database conversions."
            }
            $pythonScript = @"
import json
import sys
import os

try:
    import pyodbc
    
    # Determine driver based on file extension
    file_ext = os.path.splitext(sys.argv[1])[1].lower()
    if file_ext == '.accdb':
        driver = 'Microsoft Access Driver (*.mdb, *.accdb)'
    else:
        driver = 'Microsoft Access Driver (*.mdb)'
    
    # Try different connection strings
    conn_strs = [
        f'DRIVER={{{driver}}};DBQ={sys.argv[1]};',
        f'DRIVER={{Microsoft Access Driver (*.mdb, *.accdb)}};DBQ={sys.argv[1]};',
        f'DRIVER={{Microsoft Access Driver (*.mdb)}};DBQ={sys.argv[1]};',
    ]
    
    conn = None
    for conn_str in conn_strs:
        try:
            conn = pyodbc.connect(conn_str)
            break
        except pyodbc.Error:
            continue
    
    if conn is None:
        raise Exception("Could not connect to Access database. Ensure Microsoft Access Database Engine (ACE) is installed.")
    
    cursor = conn.cursor()
    
    # Get table names
    table_query = "SELECT name FROM MSysObjects WHERE type=1 AND flags=0;"
    try:
        cursor.execute(table_query)
        tables = [row[0] for row in cursor.fetchall()]
    except:
        # Fallback: try to get tables from information_schema
        try:
            cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_type='TABLE';")
            tables = [row[0] for row in cursor.fetchall()]
        except:
            # Last resort: try common table names
            tables = []
    
    result = {}
    
    if sys.argv[3] and sys.argv[3] in tables:
        # Export specific table
        table_name = sys.argv[3]
        cursor.execute(f"SELECT * FROM [{table_name}];")
        columns = [desc[0] for desc in cursor.description]
        rows = []
        for row in cursor.fetchall():
            row_dict = {}
            for i, col in enumerate(columns):
                val = row[i]
                if val is None:
                    row_dict[col] = None
                elif isinstance(val, bytes):
                    row_dict[col] = val.hex()
                else:
                    row_dict[col] = str(val)
            rows.append(row_dict)
        result[table_name] = rows
    else:
        # Export all tables
        for table_name in tables:
            try:
                cursor.execute(f"SELECT * FROM [{table_name}];")
                columns = [desc[0] for desc in cursor.description]
                rows = []
                for row in cursor.fetchall():
                    row_dict = {}
                    for i, col in enumerate(columns):
                        val = row[i]
                        if val is None:
                            row_dict[col] = None
                        elif isinstance(val, bytes):
                            row_dict[col] = val.hex()
                        else:
                            row_dict[col] = str(val)
                    rows.append(row_dict)
                result[table_name] = rows
            except Exception as e:
                # Skip tables that can't be read
                continue
    
    cursor.close()
    conn.close()
    
    with open(sys.argv[2], 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, default=str, ensure_ascii=False)
except ImportError:
    print('Error: pyodbc package is not installed. Install with: uv pip install pyodbc', file=sys.stderr)
    print('Note: On Windows, you may also need Microsoft Access Database Engine (ACE).', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "access-decode-$(Get-Random).py"
            Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
            try {
                $args = @($InputPath, $OutputPath)
                if ($TableName) {
                    $args += $TableName
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
            Write-Error "Failed to convert Access database to JSON: $_"
            throw
        }
    } -Force

    # JSON to MDB/ACCDB
    Set-Item -Path Function:Global:_ConvertTo-AccessFromJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$Format = 'accdb')
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            $ext = if ($Format -eq 'mdb') { '.mdb' } else { '.accdb' }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', $ext }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pyodbc package to use Access database conversions."
            }
            $pythonScript = @"
import json
import sys
import os

try:
    import pyodbc
    
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Create new database (requires creating empty database first)
    # Note: Creating new Access databases programmatically is complex
    # This is a simplified approach that requires an existing template or manual creation
    raise NotImplementedError("Creating new Access databases from JSON is not fully supported. Use existing database or convert to SQLite first.")
    
except ImportError:
    print('Error: pyodbc package is not installed. Install with: uv pip install pyodbc', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "access-encode-$(Get-Random).py"
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
            Write-Error "Failed to convert JSON to Access database: $_"
            throw
        }
    } -Force

    # MDB/ACCDB to CSV
    Set-Item -Path Function:Global:_ConvertFrom-AccessToCsv -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$TableName)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(mdb|accdb)$', '.csv' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pyodbc package to use Access database conversions."
            }
            $pythonScript = @"
import sys
import csv
import os

try:
    import pyodbc
    
    # Determine driver based on file extension
    file_ext = os.path.splitext(sys.argv[1])[1].lower()
    if file_ext == '.accdb':
        driver = 'Microsoft Access Driver (*.mdb, *.accdb)'
    else:
        driver = 'Microsoft Access Driver (*.mdb)'
    
    # Try different connection strings
    conn_strs = [
        f'DRIVER={{{driver}}};DBQ={sys.argv[1]};',
        f'DRIVER={{Microsoft Access Driver (*.mdb, *.accdb)}};DBQ={sys.argv[1]};',
        f'DRIVER={{Microsoft Access Driver (*.mdb)}};DBQ={sys.argv[1]};',
    ]
    
    conn = None
    for conn_str in conn_strs:
        try:
            conn = pyodbc.connect(conn_str)
            break
        except pyodbc.Error:
            continue
    
    if conn is None:
        raise Exception("Could not connect to Access database. Ensure Microsoft Access Database Engine (ACE) is installed.")
    
    cursor = conn.cursor()
    
    # Get table names
    table_query = "SELECT name FROM MSysObjects WHERE type=1 AND flags=0;"
    try:
        cursor.execute(table_query)
        tables = [row[0] for row in cursor.fetchall()]
    except:
        tables = []
    
    if sys.argv[3] and sys.argv[3] in tables:
        table_name = sys.argv[3]
    elif tables:
        table_name = tables[0]
    else:
        raise Exception("No tables found in Access database")
    
    cursor.execute(f"SELECT * FROM [{table_name}];")
    columns = [desc[0] for desc in cursor.description]
    
    with open(sys.argv[2], 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(columns)
        for row in cursor.fetchall():
            writer.writerow([str(val) if val is not None else '' for val in row])
    
    cursor.close()
    conn.close()
except ImportError:
    print('Error: pyodbc package is not installed. Install with: uv pip install pyodbc', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "access-to-csv-$(Get-Random).py"
            Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
            try {
                $args = @($InputPath, $OutputPath)
                if ($TableName) {
                    $args += $TableName
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
            Write-Error "Failed to convert Access database to CSV: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert Access database to JSON
<#
.SYNOPSIS
    Converts Microsoft Access database to JSON format.
.DESCRIPTION
    Converts a Microsoft Access database file (.mdb or .accdb) to JSON format.
    Exports table data from Access database.
    Requires Python with pyodbc package and Microsoft Access Database Engine (ACE) to be installed.
.PARAMETER InputPath
    The path to the Access database file (.mdb or .accdb extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.PARAMETER TableName
    Optional. Name of the table to export. If not specified, exports all tables.
#>
function ConvertFrom-AccessToJson {
    param([string]$InputPath, [string]$OutputPath, [string]$TableName)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-AccessToJson @PSBoundParameters
}
Set-Alias -Name access-to-json -Value ConvertFrom-AccessToJson -ErrorAction SilentlyContinue
Set-Alias -Name mdb-to-json -Value ConvertFrom-AccessToJson -ErrorAction SilentlyContinue
Set-Alias -Name accdb-to-json -Value ConvertFrom-AccessToJson -ErrorAction SilentlyContinue

# Convert JSON to Access database
<#
.SYNOPSIS
    Converts JSON file to Microsoft Access database format.
.DESCRIPTION
    Converts a JSON file to Microsoft Access database format (.mdb or .accdb).
    Note: Creating new Access databases programmatically is complex and may not be fully supported.
    Requires Python with pyodbc package and Microsoft Access Database Engine (ACE) to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output Access database file. If not specified, uses input path with .accdb extension.
.PARAMETER Format
    Optional. Format to create: 'accdb' (default) or 'mdb'.
#>
function ConvertTo-AccessFromJson {
    param([string]$InputPath, [string]$OutputPath, [string]$Format = 'accdb')
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-AccessFromJson @PSBoundParameters
}
Set-Alias -Name json-to-access -Value ConvertTo-AccessFromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-mdb -Value ConvertTo-AccessFromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-accdb -Value ConvertTo-AccessFromJson -ErrorAction SilentlyContinue

# Convert Access database to CSV
<#
.SYNOPSIS
    Converts Microsoft Access database to CSV format.
.DESCRIPTION
    Converts a Microsoft Access database file (.mdb or .accdb) to CSV format.
    Exports table data from Access database.
    Requires Python with pyodbc package and Microsoft Access Database Engine (ACE) to be installed.
.PARAMETER InputPath
    The path to the Access database file (.mdb or .accdb extension).
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
.PARAMETER TableName
    Optional. Name of the table to export. If not specified, exports the first table.
#>
function ConvertFrom-AccessToCsv {
    param([string]$InputPath, [string]$OutputPath, [string]$TableName)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-AccessToCsv @PSBoundParameters
}
Set-Alias -Name access-to-csv -Value ConvertFrom-AccessToCsv -ErrorAction SilentlyContinue
Set-Alias -Name mdb-to-csv -Value ConvertFrom-AccessToCsv -ErrorAction SilentlyContinue
Set-Alias -Name accdb-to-csv -Value ConvertFrom-AccessToCsv -ErrorAction SilentlyContinue

