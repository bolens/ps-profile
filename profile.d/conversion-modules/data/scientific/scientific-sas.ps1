# ===============================================
# SAS format conversion utilities
# SAS ↔ JSON, CSV
# ===============================================

<#
.SYNOPSIS
    Initializes SAS format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for SAS data formats (.sas7bdat, .xpt).
    SAS is a statistical software package.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Python with pandas/polars and pyreadstat packages to be installed.
    Alternatively, requires SAS software to be installed for native conversions.
#>
function Initialize-FileConversion-ScientificSas {
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
    # SAS to JSON
    Set-Item -Path Function:Global:_ConvertFrom-SasToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(sas7bdat|xpt)$', '.json' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pandas/polars and pyreadstat packages to use SAS conversions."
            }
            
            # Get preferred data frame library
            $libInfo = Get-DataFrameLibraryPreference -PythonCmd $pythonCmd
            if (-not $libInfo.Available) {
                $installCmd = Get-PythonPackageInstallRecommendation -PackageNames 'pandas', 'polars' -PythonCmd $pythonCmd
                throw "Neither pandas nor polars is available. Install at least one: $installCmd"
            }
            $usePolars = ($libInfo.Library -eq 'polars')
            
            $installCmd = Get-PythonPackageInstallRecommendation -PackageNames 'pyreadstat', 'pandas', 'polars' -PythonCmd $pythonCmd
            $pythonScript = @"
import json
import sys

try:
    # Try pyreadstat first (better support for SAS formats)
    try:
        import pyreadstat
        df_pandas, meta = pyreadstat.read_sas7bdat(sys.argv[1])
    except ImportError:
        # Fallback to pandas
        try:
            import pandas as pd
            df_pandas = pd.read_sas(sys.argv[1])
            meta = None
        except ImportError:
            raise ImportError("Neither pyreadstat nor pandas with SAS support is available")
    
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
            'number_columns': meta.number_columns if hasattr(meta, 'number_columns') else None
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
            $installCmd = Get-PythonPackageInstallRecommendation -PackageNames 'pyreadstat', 'pandas', 'polars' -PythonCmd $pythonCmd
            $tempScript = Join-Path $env:TEMP "sas-decode-$(Get-Random).py"
            Set-Content -LiteralPath $tempScript -Value ($pythonScript -replace 'sys\.argv\[4\]', "'$installCmd'") -Encoding UTF8
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
            Write-Error "Failed to convert SAS to JSON: $_"
            throw
        }
    } -Force

    # JSON to SAS
    Set-Item -Path Function:Global:_ConvertTo-SasFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.sas7bdat' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pandas/polars and pyreadstat packages to use SAS conversions."
            }
            # Get preferred data frame library
            $libInfo = Get-DataFrameLibraryPreference -PythonCmd $pythonCmd
            if (-not $libInfo.Available) {
                $installCmd = Get-PythonPackageInstallRecommendation -PackageNames 'pandas', 'polars' -PythonCmd $pythonCmd
                throw "Neither pandas nor polars is available. Install at least one: $installCmd"
            }
            $usePolars = ($libInfo.Library -eq 'polars')
            
            $installCmd = Get-PythonPackageInstallRecommendation -PackageNames 'pyreadstat', 'pandas', 'polars' -PythonCmd $pythonCmd
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
    
    # Try pyreadstat first
    try:
        import pyreadstat
        pyreadstat.write_sas7bdat(df, sys.argv[2])
    except ImportError:
        # Fallback: pandas doesn't have write_sas, so we'll save as CSV and suggest using SAS
        install_cmd = sys.argv[4] if len(sys.argv) > 4 else 'uv pip install pyreadstat'
        raise ImportError(f"pyreadstat is required for writing SAS files. Install with: {install_cmd}")
except ImportError as e:
    if 'pyreadstat' in str(e) or 'pandas' in str(e) or 'polars' in str(e):
        install_cmd = sys.argv[4] if len(sys.argv) > 4 else 'uv pip install pyreadstat pandas polars'
        print(f'Error: pyreadstat and pandas/polars packages are required. Install with: {install_cmd}', file=sys.stderr)
    else:
        print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "sas-encode-$(Get-Random).py"
            Set-Content -LiteralPath $tempScript -Value ($pythonScript -replace 'sys\.argv\[4\]', "'$installCmd'") -Encoding UTF8
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
            Write-Error "Failed to convert JSON to SAS: $_"
            throw
        }
    } -Force

    # SAS to CSV
    Set-Item -Path Function:Global:_ConvertFrom-SasToCsv -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(sas7bdat|xpt)$', '.csv' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pandas/polars and pyreadstat packages to use SAS conversions."
            }
            # Get preferred data frame library
            $libInfo = Get-DataFrameLibraryPreference -PythonCmd $pythonCmd
            if (-not $libInfo.Available) {
                $installCmd = Get-PythonPackageInstallRecommendation -PackageNames 'pandas', 'polars' -PythonCmd $pythonCmd
                throw "Neither pandas nor polars is available. Install at least one: $installCmd"
            }
            $usePolars = ($libInfo.Library -eq 'polars')
            
            $installCmd = Get-PythonPackageInstallRecommendation -PackageNames 'pyreadstat', 'pandas', 'polars' -PythonCmd $pythonCmd
            $pythonScript = @"
import sys

try:
    # Try pyreadstat first
    try:
        import pyreadstat
        df_pandas, meta = pyreadstat.read_sas7bdat(sys.argv[1])
    except ImportError:
        # Fallback to pandas
        try:
            import pandas as pd
            df_pandas = pd.read_sas(sys.argv[1])
        except ImportError:
            raise ImportError("Neither pyreadstat nor pandas with SAS support is available")
    
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
        install_cmd = sys.argv[4] if len(sys.argv) > 4 else 'uv pip install pyreadstat pandas polars'
        print(f'Error: pyreadstat and pandas/polars packages are required. Install with: {install_cmd}', file=sys.stderr)
    else:
        print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "sas-to-csv-$(Get-Random).py"
            Set-Content -LiteralPath $tempScript -Value ($pythonScript -replace 'sys\.argv\[4\]', "'$installCmd'") -Encoding UTF8
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
            Write-Error "Failed to convert SAS to CSV: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert SAS to JSON
<#
.SYNOPSIS
    Converts SAS file to JSON format.
.DESCRIPTION
    Converts a SAS data file (.sas7bdat or .xpt) to JSON format.
    Requires Python with pandas/polars and pyreadstat packages to be installed.
.PARAMETER InputPath
    The path to the SAS file (.sas7bdat or .xpt extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-SasToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-SasToJson @PSBoundParameters
}
Set-Alias -Name sas-to-json -Value ConvertFrom-SasToJson -ErrorAction SilentlyContinue

# Convert JSON to SAS
<#
.SYNOPSIS
    Converts JSON file to SAS format.
.DESCRIPTION
    Converts a JSON file to SAS .sas7bdat format.
    Requires Python with pandas/polars and pyreadstat packages to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output SAS file. If not specified, uses input path with .sas7bdat extension.
#>
function ConvertTo-SasFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-SasFromJson @PSBoundParameters
}
Set-Alias -Name json-to-sas -Value ConvertTo-SasFromJson -ErrorAction SilentlyContinue

# Convert SAS to CSV
<#
.SYNOPSIS
    Converts SAS file to CSV format.
.DESCRIPTION
    Converts a SAS data file (.sas7bdat or .xpt) to CSV format.
    Requires Python with pandas/polars and pyreadstat packages to be installed.
.PARAMETER InputPath
    The path to the SAS file (.sas7bdat or .xpt extension).
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
#>
function ConvertFrom-SasToCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-SasToCsv @PSBoundParameters
}
Set-Alias -Name sas-to-csv -Value ConvertFrom-SasToCsv -ErrorAction SilentlyContinue

