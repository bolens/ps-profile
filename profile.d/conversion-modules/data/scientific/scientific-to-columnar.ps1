# ===============================================
# Scientific to columnar format conversion utilities
# HDF5 ↔ Parquet, NetCDF ↔ Parquet
# ===============================================

<#
.SYNOPSIS
    Initializes scientific to columnar format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for converting between scientific formats (HDF5, NetCDF)
    and columnar formats (Parquet). This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Python with h5py/netCDF4 packages and Node.js with parquetjs package to be installed.
#>
function Initialize-FileConversion-ScientificToColumnar {
    # Ensure Python module is imported
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
    # Ensure NodeJs module is imported (for Parquet conversions)
    if (-not (Get-Command Invoke-NodeScript -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Variable -Name 'RepoRoot' -Scope Script -ErrorAction SilentlyContinue) {
            $script:RepoRoot
        }
        elseif (Get-Variable -Name 'BootstrapRoot' -Scope Script -ErrorAction SilentlyContinue) {
            Split-Path -Parent $script:BootstrapRoot
        }
        else {
            Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
        }
        $nodeJsModulePath = Join-Path $repoRoot 'scripts' 'lib' 'runtime' 'NodeJs.psm1'
        if ($nodeJsModulePath -and -not [string]::IsNullOrWhiteSpace($nodeJsModulePath) -and (Test-Path -LiteralPath $nodeJsModulePath)) {
            Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
        }
    }

    # HDF5 to Parquet (scientific to columnar)
    Set-Item -Path Function:Global:_ConvertTo-ParquetFromHdf5 -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.h5$', '.parquet' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with h5py package to use HDF5 conversions."
            }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Parquet conversions."
            }
            # Convert HDF5 to JSON first, then JSON to Parquet
            $tempJson = Join-Path $env:TEMP "hdf5-to-parquet-$(Get-Random).json"
            try {
                _ConvertFrom-Hdf5ToJson -InputPath $InputPath -OutputPath $tempJson -ErrorAction Stop
                if ($tempJson -and -not [string]::IsNullOrWhiteSpace($tempJson) -and -not (Test-Path -LiteralPath $tempJson)) {
                    throw "HDF5 to JSON conversion failed - output file not created"
                }
                # Use columnar module function
                if (Get-Command _ConvertTo-ParquetFromJson -ErrorAction SilentlyContinue) {
                    _ConvertTo-ParquetFromJson -InputPath $tempJson -OutputPath $OutputPath -ErrorAction Stop
                }
                else {
                    throw "Parquet conversion function not available. Ensure columnar module is initialized."
                }
            }
            catch {
                $errorMsg = if ($_.Exception.Message -match 'h5py.*not installed|h5py package') {
                    "h5py package is not installed. Install it with: uv pip install h5py"
                }
                elseif ($_.Exception.Message -match 'parquetjs.*not installed|parquetjs package|MODULE_NOT_FOUND') {
                    "parquetjs package is not installed. Install it with: pnpm add -g parquetjs"
                }
                else {
                    "Failed to convert HDF5 to Parquet: $_"
                }
                Write-Error $errorMsg
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert HDF5 to Parquet: $_"
        }
    } -Force

    # Parquet to HDF5 (columnar to scientific)
    Set-Item -Path Function:Global:_ConvertTo-Hdf5FromParquet -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.parquet$', '.h5' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Parquet conversions."
            }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with h5py package to use HDF5 conversions."
            }
            # Convert Parquet to JSON first, then JSON to HDF5
            $tempJson = Join-Path $env:TEMP "parquet-to-hdf5-$(Get-Random).json"
            try {
                # Use columnar module function
                if (Get-Command _ConvertFrom-ParquetToJson -ErrorAction SilentlyContinue) {
                    _ConvertFrom-ParquetToJson -InputPath $InputPath -OutputPath $tempJson -ErrorAction Stop
                    if ($tempJson -and -not [string]::IsNullOrWhiteSpace($tempJson) -and -not (Test-Path -LiteralPath $tempJson)) {
                        throw "Parquet to JSON conversion failed - output file not created"
                    }
                    _ConvertTo-Hdf5FromJson -InputPath $tempJson -OutputPath $OutputPath -ErrorAction Stop
                }
                else {
                    throw "Parquet conversion function not available. Ensure columnar module is initialized."
                }
            }
            catch {
                $errorMsg = if ($_.Exception.Message -match 'parquetjs.*not installed|parquetjs package|MODULE_NOT_FOUND') {
                    "parquetjs package is not installed. Install it with: pnpm add -g parquetjs"
                }
                elseif ($_.Exception.Message -match 'h5py.*not installed|h5py package') {
                    "h5py package is not installed. Install it with: uv pip install h5py"
                }
                else {
                    "Failed to convert Parquet to HDF5: $_"
                }
                Write-Error $errorMsg
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert Parquet to HDF5: $_"
        }
    } -Force

    # NetCDF to Parquet (scientific to columnar)
    Set-Item -Path Function:Global:_ConvertTo-ParquetFromNetCdf -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.nc$', '.parquet' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with netCDF4 package to use NetCDF conversions."
            }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Parquet conversions."
            }
            # Convert NetCDF to JSON first, then JSON to Parquet
            $tempJson = Join-Path $env:TEMP "netcdf-to-parquet-$(Get-Random).json"
            try {
                _ConvertFrom-NetCdfToJson -InputPath $InputPath -OutputPath $tempJson -ErrorAction Stop
                if ($tempJson -and -not [string]::IsNullOrWhiteSpace($tempJson) -and -not (Test-Path -LiteralPath $tempJson)) {
                    throw "NetCDF to JSON conversion failed - output file not created"
                }
                # Use columnar module function
                if (Get-Command _ConvertTo-ParquetFromJson -ErrorAction SilentlyContinue) {
                    _ConvertTo-ParquetFromJson -InputPath $tempJson -OutputPath $OutputPath -ErrorAction Stop
                }
                else {
                    throw "Parquet conversion function not available. Ensure columnar module is initialized."
                }
            }
            catch {
                $errorMsg = if ($_.Exception.Message -match 'netCDF4.*not installed|netCDF4 package') {
                    "netCDF4 package is not installed. Install it with: uv pip install netCDF4"
                }
                elseif ($_.Exception.Message -match 'parquetjs.*not installed|parquetjs package|MODULE_NOT_FOUND') {
                    "parquetjs package is not installed. Install it with: pnpm add -g parquetjs"
                }
                else {
                    "Failed to convert NetCDF to Parquet: $_"
                }
                Write-Error $errorMsg
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert NetCDF to Parquet: $_"
        }
    } -Force

    # Parquet to NetCDF (columnar to scientific)
    Set-Item -Path Function:Global:_ConvertTo-NetCdfFromParquet -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.parquet$', '.nc' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Parquet conversions."
            }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with netCDF4 package to use NetCDF conversions."
            }
            # Convert Parquet to JSON first, then JSON to NetCDF
            $tempJson = Join-Path $env:TEMP "parquet-to-netcdf-$(Get-Random).json"
            try {
                # Use columnar module function
                if (Get-Command _ConvertFrom-ParquetToJson -ErrorAction SilentlyContinue) {
                    _ConvertFrom-ParquetToJson -InputPath $InputPath -OutputPath $tempJson -ErrorAction Stop
                    if ($tempJson -and -not [string]::IsNullOrWhiteSpace($tempJson) -and -not (Test-Path -LiteralPath $tempJson)) {
                        throw "Parquet to JSON conversion failed - output file not created"
                    }
                    _ConvertTo-NetCdfFromJson -InputPath $tempJson -OutputPath $OutputPath -ErrorAction Stop
                }
                else {
                    throw "Parquet conversion function not available. Ensure columnar module is initialized."
                }
            }
            catch {
                $errorMsg = if ($_.Exception.Message -match 'parquetjs.*not installed|parquetjs package|MODULE_NOT_FOUND') {
                    "parquetjs package is not installed. Install it with: pnpm add -g parquetjs"
                }
                elseif ($_.Exception.Message -match 'netCDF4.*not installed|netCDF4 package') {
                    "netCDF4 package is not installed. Install it with: uv pip install netCDF4"
                }
                else {
                    "Failed to convert Parquet to NetCDF: $_"
                }
                Write-Error $errorMsg
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert Parquet to NetCDF: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert HDF5 to Parquet
<#
.SYNOPSIS
    Converts HDF5 file to Parquet format.
.DESCRIPTION
    Converts an HDF5 (Hierarchical Data Format version 5) file to Parquet columnar format.
    Useful for converting scientific data formats to analytics-friendly columnar storage.
    Requires Python with h5py package and Node.js with parquetjs package to be installed.
.PARAMETER InputPath
    The path to the HDF5 file.
.PARAMETER OutputPath
    The path for the output Parquet file. If not specified, uses input path with .parquet extension.
#>
function ConvertTo-ParquetFromHdf5 {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-ParquetFromHdf5 @PSBoundParameters
}
Set-Alias -Name hdf5-to-parquet -Value ConvertTo-ParquetFromHdf5 -ErrorAction SilentlyContinue
Set-Alias -Name h5-to-parquet -Value ConvertTo-ParquetFromHdf5 -ErrorAction SilentlyContinue

# Convert Parquet to HDF5
<#
.SYNOPSIS
    Converts Parquet file to HDF5 format.
.DESCRIPTION
    Converts a Parquet columnar file to HDF5 (Hierarchical Data Format version 5) format.
    Useful for converting analytics data to scientific data formats.
    Requires Node.js with parquetjs package and Python with h5py package to be installed.
.PARAMETER InputPath
    The path to the Parquet file.
.PARAMETER OutputPath
    The path for the output HDF5 file. If not specified, uses input path with .h5 extension.
#>
function ConvertTo-Hdf5FromParquet {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-Hdf5FromParquet @PSBoundParameters
}
Set-Alias -Name parquet-to-hdf5 -Value ConvertTo-Hdf5FromParquet -ErrorAction SilentlyContinue
Set-Alias -Name parquet-to-h5 -Value ConvertTo-Hdf5FromParquet -ErrorAction SilentlyContinue

# Convert NetCDF to Parquet
<#
.SYNOPSIS
    Converts NetCDF file to Parquet format.
.DESCRIPTION
    Converts a NetCDF (Network Common Data Form) file to Parquet columnar format.
    Useful for converting scientific data formats to analytics-friendly columnar storage.
    Requires Python with netCDF4 package and Node.js with parquetjs package to be installed.
.PARAMETER InputPath
    The path to the NetCDF file.
.PARAMETER OutputPath
    The path for the output Parquet file. If not specified, uses input path with .parquet extension.
#>
function ConvertTo-ParquetFromNetCdf {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-ParquetFromNetCdf @PSBoundParameters
}
Set-Alias -Name netcdf-to-parquet -Value ConvertTo-ParquetFromNetCdf -ErrorAction SilentlyContinue
Set-Alias -Name nc-to-parquet -Value ConvertTo-ParquetFromNetCdf -ErrorAction SilentlyContinue

# Convert Parquet to NetCDF
<#
.SYNOPSIS
    Converts Parquet file to NetCDF format.
.DESCRIPTION
    Converts a Parquet columnar file to NetCDF (Network Common Data Form) format.
    Useful for converting analytics data to scientific data formats.
    Requires Node.js with parquetjs package and Python with netCDF4 package to be installed.
.PARAMETER InputPath
    The path to the Parquet file.
.PARAMETER OutputPath
    The path for the output NetCDF file. If not specified, uses input path with .nc extension.
#>
function ConvertTo-NetCdfFromParquet {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-NetCdfFromParquet @PSBoundParameters
}
Set-Alias -Name parquet-to-netcdf -Value ConvertTo-NetCdfFromParquet -ErrorAction SilentlyContinue
Set-Alias -Name parquet-to-nc -Value ConvertTo-NetCdfFromParquet -ErrorAction SilentlyContinue
