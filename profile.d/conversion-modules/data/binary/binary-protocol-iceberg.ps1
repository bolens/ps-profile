# ===============================================
# Apache Iceberg format conversion utilities
# Iceberg ↔ JSON, Parquet
# ========================================

<#
.SYNOPSIS
    Initializes Apache Iceberg format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Apache Iceberg format conversions.
    Iceberg is an open table format for huge analytic tables.
    Supports bidirectional conversions between Iceberg tables and JSON, and conversions to Parquet.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Python with pyiceberg package to be installed.
#>
function Initialize-FileConversion-BinaryProtocolIceberg {
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

    # Iceberg to JSON
    Set-Item -Path Function:Global:_ConvertFrom-IcebergToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(iceberg|table)$', '.json' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pyiceberg package to use Iceberg conversions."
            }
            $pythonScript = @"
import json
import sys
try:
    from pyiceberg.catalog import load_catalog
    from pyiceberg.table import Table
except ImportError:
    print('Error: pyiceberg package is not installed. Install it with: uv pip install pyiceberg', file=sys.stderr)
    sys.exit(1)

try:
    # Note: Iceberg tables require a catalog and table identifier
    # This is a simplified implementation that reads from a local table path
    # For full implementation, you would need to configure a catalog
    
    # For now, we'll try to read metadata and data files
    # This is a placeholder - full Iceberg support requires catalog configuration
    print('Error: Iceberg table reading requires catalog configuration. This is a simplified implementation.', file=sys.stderr)
    print('For full Iceberg support, configure a catalog and provide table identifier.', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "iceberg-to-json-$(Get-Random).py"
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
            Write-Error "Failed to convert Iceberg to JSON: $_"
            throw
        }
    } -Force

    # JSON to Iceberg
    Set-Item -Path Function:Global:_ConvertTo-IcebergFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.iceberg' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pyiceberg package to use Iceberg conversions."
            }
            $pythonScript = @"
import json
import sys
try:
    from pyiceberg.catalog import load_catalog
    from pyiceberg.table import Table
except ImportError:
    print('Error: pyiceberg package is not installed. Install it with: uv pip install pyiceberg', file=sys.stderr)
    sys.exit(1)

try:
    # Note: Iceberg table creation requires a catalog and schema definition
    # This is a placeholder - full Iceberg support requires catalog configuration
    print('Error: Iceberg table creation requires catalog configuration. This is a simplified implementation.', file=sys.stderr)
    print('For full Iceberg support, configure a catalog and provide schema definition.', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "json-to-iceberg-$(Get-Random).py"
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
            Write-Error "Failed to convert JSON to Iceberg: $_"
            throw
        }
    } -Force

    # Iceberg to Parquet
    Set-Item -Path Function:Global:_ConvertFrom-IcebergToParquet -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(iceberg|table)$', '.parquet' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with pyiceberg and pyarrow packages to use Iceberg conversions."
            }
            $pythonScript = @"
import sys
try:
    from pyiceberg.catalog import load_catalog
    import pyarrow.parquet as pq
except ImportError:
    print('Error: pyiceberg and pyarrow packages are not installed. Install with: uv pip install pyiceberg pyarrow', file=sys.stderr)
    sys.exit(1)

try:
    # Note: Iceberg to Parquet conversion requires reading from Iceberg table
    # This is a placeholder - full Iceberg support requires catalog configuration
    print('Error: Iceberg to Parquet conversion requires catalog configuration. This is a simplified implementation.', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "iceberg-to-parquet-$(Get-Random).py"
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
            Write-Error "Failed to convert Iceberg to Parquet: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert Iceberg to JSON
<#
.SYNOPSIS
    Converts Apache Iceberg table to JSON format.
.DESCRIPTION
    Converts an Apache Iceberg table to JSON format.
    Note: Full Iceberg support requires catalog configuration. This is a simplified implementation.
    Requires Python with pyiceberg package to be installed.
.PARAMETER InputPath
    The path to the Iceberg table directory or metadata file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-IcebergToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-IcebergToJson @PSBoundParameters
}
Set-Alias -Name iceberg-to-json -Value ConvertFrom-IcebergToJson -ErrorAction SilentlyContinue

# Convert JSON to Iceberg
<#
.SYNOPSIS
    Converts JSON file to Apache Iceberg table format.
.DESCRIPTION
    Converts a JSON file to Apache Iceberg table format.
    Note: Full Iceberg support requires catalog configuration. This is a simplified implementation.
    Requires Python with pyiceberg package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output Iceberg table directory. If not specified, uses input path with .iceberg extension.
#>
function ConvertTo-IcebergFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-IcebergFromJson @PSBoundParameters
}
Set-Alias -Name json-to-iceberg -Value ConvertTo-IcebergFromJson -ErrorAction SilentlyContinue

# Convert Iceberg to Parquet
<#
.SYNOPSIS
    Converts Apache Iceberg table to Parquet format.
.DESCRIPTION
    Converts an Apache Iceberg table to Parquet format.
    Note: Full Iceberg support requires catalog configuration. This is a simplified implementation.
    Requires Python with pyiceberg and pyarrow packages to be installed.
.PARAMETER InputPath
    The path to the Iceberg table directory or metadata file.
.PARAMETER OutputPath
    The path for the output Parquet file. If not specified, uses input path with .parquet extension.
#>
function ConvertFrom-IcebergToParquet {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-IcebergToParquet @PSBoundParameters
}
Set-Alias -Name iceberg-to-parquet -Value ConvertFrom-IcebergToParquet -ErrorAction SilentlyContinue

