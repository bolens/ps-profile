# ===============================================
# Direct scientific format conversion utilities
# HDF5 ↔ NetCDF
# ===============================================

<#
.SYNOPSIS
    Initializes direct scientific format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for direct conversions between HDF5 and NetCDF.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Python with h5py and netCDF4 packages to be installed.
#>
function Initialize-FileConversion-ScientificDirect {
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
    # HDF5 to NetCDF (direct scientific conversion)
    Set-Item -Path Function:Global:_ConvertTo-NetCdfFromHdf5 -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.h5$', '.nc' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with h5py and netCDF4 packages to use scientific format conversions."
            }
            # Convert HDF5 to JSON first, then JSON to NetCDF
            $tempJson = Join-Path ([System.IO.Path]::GetTempPath()) "hdf5-to-netcdf-$(Get-Random).json"
            try {
                _ConvertFrom-Hdf5ToJson -InputPath $InputPath -OutputPath $tempJson -ErrorAction Stop
                if ($tempJson -and -not [string]::IsNullOrWhiteSpace($tempJson) -and -not (Test-Path -LiteralPath $tempJson)) {
                    throw "HDF5 to JSON conversion failed - output file not created"
                }
                _ConvertTo-NetCdfFromJson -InputPath $tempJson -OutputPath $OutputPath -ErrorAction Stop
            }
            catch {
                $errorMsg = if ($_.Exception.Message -match 'h5py.*not installed|h5py package') {
                    Resolve-PythonInstallHintMessage -Message "h5py package is not installed. Install it with: __PYTHON_INSTALL_CMD__" -PackageNames 'h5py' -Global
                }
                elseif ($_.Exception.Message -match 'netCDF4.*not installed|netCDF4 package') {
                    Resolve-PythonInstallHintMessage -Message "netCDF4 package is not installed. Install it with: __PYTHON_INSTALL_CMD__" -PackageNames 'netCDF4' -Global
                }
                else {
                    "Failed to convert HDF5 to NetCDF: $_"
                }
                Write-Error $errorMsg
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert HDF5 to NetCDF: $_"
        }
    } -Force

    # NetCDF to HDF5 (direct scientific conversion)
    Set-Item -Path Function:Global:_ConvertTo-Hdf5FromNetCdf -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.nc$', '.h5' }
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python with h5py and netCDF4 packages to use scientific format conversions."
            }
            # Convert NetCDF to JSON first, then JSON to HDF5
            $tempJson = Join-Path ([System.IO.Path]::GetTempPath()) "netcdf-to-hdf5-$(Get-Random).json"
            try {
                _ConvertFrom-NetCdfToJson -InputPath $InputPath -OutputPath $tempJson -ErrorAction Stop
                if ($tempJson -and -not [string]::IsNullOrWhiteSpace($tempJson) -and -not (Test-Path -LiteralPath $tempJson)) {
                    throw "NetCDF to JSON conversion failed - output file not created"
                }
                _ConvertTo-Hdf5FromJson -InputPath $tempJson -OutputPath $OutputPath -ErrorAction Stop
            }
            catch {
                $errorMsg = if ($_.Exception.Message -match 'h5py.*not installed|h5py package') {
                    Resolve-PythonInstallHintMessage -Message "h5py package is not installed. Install it with: __PYTHON_INSTALL_CMD__" -PackageNames 'h5py' -Global
                }
                elseif ($_.Exception.Message -match 'netCDF4.*not installed|netCDF4 package') {
                    Resolve-PythonInstallHintMessage -Message "netCDF4 package is not installed. Install it with: __PYTHON_INSTALL_CMD__" -PackageNames 'netCDF4' -Global
                }
                else {
                    "Failed to convert NetCDF to HDF5: $_"
                }
                Write-Error $errorMsg
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert NetCDF to HDF5: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert HDF5 to NetCDF
<#
.SYNOPSIS
    Converts HDF5 file to NetCDF format.
.DESCRIPTION
    Converts an HDF5 (Hierarchical Data Format version 5) file directly to NetCDF format.
    Both are scientific data formats commonly used for storing large datasets.
    Requires Python with h5py and netCDF4 packages to be installed.
.PARAMETER InputPath
    The path to the HDF5 file.
.PARAMETER OutputPath
    The path for the output NetCDF file. If not specified, uses input path with .nc extension.
.EXAMPLE
    ConvertTo-NetCdfFromHdf5 -InputPath ./input.file

#>
function ConvertTo-NetCdfFromHdf5 {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-NetCdfFromHdf5 @PSBoundParameters
}
Set-AgentModeAlias -Name 'hdf5-to-netcdf' -Target 'ConvertTo-NetCdfFromHdf5'
Set-AgentModeAlias -Name 'h5-to-nc' -Target 'ConvertTo-NetCdfFromHdf5'
# Convert NetCDF to HDF5
<#
.SYNOPSIS
    Converts NetCDF file to HDF5 format.
.DESCRIPTION
    Converts a NetCDF (Network Common Data Form) file directly to HDF5 format.
    Both are scientific data formats commonly used for storing large datasets.
    Requires Python with h5py and netCDF4 packages to be installed.
.PARAMETER InputPath
    The path to the NetCDF file.
.PARAMETER OutputPath
    The path for the output HDF5 file. If not specified, uses input path with .h5 extension.
.EXAMPLE
    ConvertTo-Hdf5FromNetCdf -InputPath ./input.file

#>
function ConvertTo-Hdf5FromNetCdf {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-Hdf5FromNetCdf @PSBoundParameters
}
Set-AgentModeAlias -Name 'netcdf-to-hdf5' -Target 'ConvertTo-Hdf5FromNetCdf'
Set-AgentModeAlias -Name 'nc-to-h5' -Target 'ConvertTo-Hdf5FromNetCdf'