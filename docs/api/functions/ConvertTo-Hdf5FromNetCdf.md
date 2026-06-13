# ConvertTo-Hdf5FromNetCdf

## Synopsis

Converts NetCDF file to HDF5 format.

## Description

Converts a NetCDF (Network Common Data Form) file directly to HDF5 format. Both are scientific data formats commonly used for storing large datasets. Requires Python with h5py and netCDF4 packages to be installed.

## Signature

```powershell
ConvertTo-Hdf5FromNetCdf
```

## Parameters

### -InputPath

The path to the NetCDF file.

### -OutputPath

The path for the output HDF5 file. If not specified, uses input path with .h5 extension.


## Examples

### Example 1

```powershell
ConvertTo-Hdf5FromNetCdf -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `nc-to-h5` - Converts NetCDF file to HDF5 format.
- `netcdf-to-hdf5` - Converts NetCDF file to HDF5 format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-direct.ps1
