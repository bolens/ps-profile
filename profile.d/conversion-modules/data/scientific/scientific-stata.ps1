# ===============================================
# Stata format conversion utilities
# Stata ↔ JSON, CSV
# ===============================================

<#
.SYNOPSIS
    Initializes Stata format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Stata data formats (.dta).
    Stata is a statistical software package.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Python with pandas/polars and pyreadstat packages to be installed.
    Alternatively, requires Stata software to be installed for native conversions.
#>
function Initialize-FileConversion-ScientificStata {
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
    # Stata to JSON
    Set-Item -Path Function:Global:_ConvertFrom-StataToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.dta$', '.json' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pandas/polars and pyreadstat packages to use Stata conversions."
            }
            
            # Get preferred data frame library
            $libInfo = Get-DataFrameLibraryPreference -PythonCmd $pythonCmd
            if (-not $libInfo.Available) {
                throw "Neither pandas nor polars is available. Install at least one: uv pip install pandas or uv pip install polars"
            }
            $usePolars = ($libInfo.Library -eq 'polars')
            
            $pythonScript = @"
import json
import sys

try:
    # Use pyreadstat for Stata files (better support than pandas)
    try:
        import pyreadstat
        df_pandas, meta = pyreadstat.read_dta(sys.argv[1])
    except ImportError:
        # Fallback to pandas
        try:
            import pandas as pd
            df_pandas = pd.read_stata(sys.argv[1])
            meta = None
        except ImportError:
            raise ImportError("Neither pyreadstat nor pandas with Stata support is available")
    
    # Convert to preferred library if needed
    use_polars = sys.argv[3].lower() == 'true'
    if use_polars:
        try:
            import polars as pl
            # Convert pandas DataFrame to polars DataFrame
            df = pl.from_pandas(df_pandas)
            # Get data as records
            data = df.to_dicts()
            columns = df.columns
            shape = [df.height, df.width]
        except ImportError:
            # Fallback to pandas if polars not available
            import pandas as pd
            data = df_pandas.to_dict(orient='records')
            columns = df_pandas.columns.tolist()
            shape = list(df_pandas.shape)
    else:
        import pandas as pd
        data = df_pandas.to_dict(orient='records')
        columns = df_pandas.columns.tolist()
        shape = list(df_pandas.shape)
    
    # Convert DataFrame to JSON
    result = {
        'data': data,
        'columns': columns,
        'shape': shape
    }
    
    # Add metadata if available
    if meta:
        result['metadata'] = {
            'column_names': meta.column_names if hasattr(meta, 'column_names') else None,
            'number_rows': meta.number_rows if hasattr(meta, 'number_rows') else None,
            'number_columns': meta.number_columns if hasattr(meta, 'number_columns') else None,
            'variable_labels': meta.variable_labels if hasattr(meta, 'variable_labels') else None
        }
    
    with open(sys.argv[2], 'w') as f:
        json.dump(result, f, indent=2, default=str)
except ImportError as e:
    if 'pyreadstat' in str(e) or 'pandas' in str(e) or 'polars' in str(e):
        print('Error: pyreadstat and pandas/polars packages are required. Install with: uv pip install pyreadstat pandas polars', file=sys.stderr)
    else:
        print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "stata-decode-$(Get-Random).py"
            Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
            try {
                $result = & $pythonCmd $tempScript $InputPath $OutputPath $usePolars 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Python script failed: $result"
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert Stata to JSON: $_"
            throw
        }
    } -Force

    # JSON to Stata
    Set-Item -Path Function:Global:_ConvertTo-StataFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.dta' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pandas/polars and pyreadstat packages to use Stata conversions."
            }
            # Get preferred data frame library
            $libInfo = Get-DataFrameLibraryPreference -PythonCmd $pythonCmd
            if (-not $libInfo.Available) {
                throw "Neither pandas nor polars is available. Install at least one: uv pip install pandas or uv pip install polars"
            }
            $usePolars = ($libInfo.Library -eq 'polars')
            
            $pythonScript = @"
import json
import sys

try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
    
    # Extract data and columns
    use_polars = sys.argv[3].lower() == 'true'
    if use_polars:
        try:
            import polars as pl
            if isinstance(data, dict) and 'data' in data:
                df_polars = pl.DataFrame(data['data'])
            elif isinstance(data, list):
                df_polars = pl.DataFrame(data)
            else:
                raise ValueError("JSON must contain a 'data' array or be a list of records")
            # Convert polars to pandas for pyreadstat (it requires pandas)
            import pandas as pd
            df = df_polars.to_pandas()
        except ImportError:
            # Fallback to pandas
            import pandas as pd
            if isinstance(data, dict) and 'data' in data:
                df = pd.DataFrame(data['data'])
            elif isinstance(data, list):
                df = pd.DataFrame(data)
            else:
                raise ValueError("JSON must contain a 'data' array or be a list of records")
    else:
        import pandas as pd
        if isinstance(data, dict) and 'data' in data:
            df = pd.DataFrame(data['data'])
        elif isinstance(data, list):
            df = pd.DataFrame(data)
        else:
            raise ValueError("JSON must contain a 'data' array or be a list of records")
    
    # Try pyreadstat first (better support)
    try:
        import pyreadstat
        pyreadstat.write_dta(df, sys.argv[2])
    except ImportError:
        # Fallback to pandas
        try:
            df.to_stata(sys.argv[2], write_index=False)
        except AttributeError:
            raise ImportError("pandas version may not support to_stata. Install pyreadstat: uv pip install pyreadstat")
except ImportError as e:
    if 'pyreadstat' in str(e) or 'pandas' in str(e) or 'polars' in str(e):
        print('Error: pyreadstat and pandas/polars packages are required. Install with: uv pip install pyreadstat pandas polars', file=sys.stderr)
    else:
        print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "stata-encode-$(Get-Random).py"
            Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
            try {
                $result = & $pythonCmd $tempScript $InputPath $OutputPath $usePolars 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Python script failed: $result"
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert JSON to Stata: $_"
            throw
        }
    } -Force

    # Stata to CSV
    Set-Item -Path Function:Global:_ConvertFrom-StataToCsv -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.dta$', '.csv' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pandas/polars and pyreadstat packages to use Stata conversions."
            }
            # Get preferred data frame library
            $libInfo = Get-DataFrameLibraryPreference -PythonCmd $pythonCmd
            if (-not $libInfo.Available) {
                throw "Neither pandas nor polars is available. Install at least one: uv pip install pandas or uv pip install polars"
            }
            $usePolars = ($libInfo.Library -eq 'polars')
            
            $pythonScript = @"
import sys

try:
    # Use pyreadstat first (better support)
    try:
        import pyreadstat
        df_pandas, meta = pyreadstat.read_dta(sys.argv[1])
    except ImportError:
        # Fallback to pandas
        try:
            import pandas as pd
            df_pandas = pd.read_stata(sys.argv[1])
        except ImportError:
            raise ImportError("Neither pyreadstat nor pandas with Stata support is available")
    
    # Convert to preferred library if needed
    use_polars = sys.argv[3].lower() == 'true'
    if use_polars:
        try:
            import polars as pl
            df = pl.from_pandas(df_pandas)
            df.write_csv(sys.argv[2])
        except ImportError:
            # Fallback to pandas if polars not available
            import pandas as pd
            df_pandas.to_csv(sys.argv[2], index=False)
    else:
        import pandas as pd
        df_pandas.to_csv(sys.argv[2], index=False)
except ImportError as e:
    if 'pyreadstat' in str(e) or 'pandas' in str(e) or 'polars' in str(e):
        print('Error: pyreadstat and pandas/polars packages are required. Install with: uv pip install pyreadstat pandas polars', file=sys.stderr)
    else:
        print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "stata-to-csv-$(Get-Random).py"
            Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
            try {
                $result = & $pythonCmd $tempScript $InputPath $OutputPath $usePolars 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Python script failed: $result"
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert Stata to CSV: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert Stata to JSON
<#
.SYNOPSIS
    Converts Stata file to JSON format.
.DESCRIPTION
    Converts a Stata data file (.dta) to JSON format.
    Requires Python with pandas/polars and pyreadstat packages to be installed.
.PARAMETER InputPath
    The path to the Stata file (.dta extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-StataToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-StataToJson @PSBoundParameters
}
Set-Alias -Name stata-to-json -Value ConvertFrom-StataToJson -ErrorAction SilentlyContinue
Set-Alias -Name dta-to-json -Value ConvertFrom-StataToJson -ErrorAction SilentlyContinue

# Convert JSON to Stata
<#
.SYNOPSIS
    Converts JSON file to Stata format.
.DESCRIPTION
    Converts a JSON file to Stata .dta format.
    Requires Python with pandas/polars and pyreadstat packages to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output Stata file. If not specified, uses input path with .dta extension.
#>
function ConvertTo-StataFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-StataFromJson @PSBoundParameters
}
Set-Alias -Name json-to-stata -Value ConvertTo-StataFromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-dta -Value ConvertTo-StataFromJson -ErrorAction SilentlyContinue

# Convert Stata to CSV
<#
.SYNOPSIS
    Converts Stata file to CSV format.
.DESCRIPTION
    Converts a Stata data file (.dta) to CSV format.
    Requires Python with pandas/polars and pyreadstat packages to be installed.
.PARAMETER InputPath
    The path to the Stata file (.dta extension).
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
#>
function ConvertFrom-StataToCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-StataToCsv @PSBoundParameters
}
Set-Alias -Name stata-to-csv -Value ConvertFrom-StataToCsv -ErrorAction SilentlyContinue
Set-Alias -Name dta-to-csv -Value ConvertFrom-StataToCsv -ErrorAction SilentlyContinue

