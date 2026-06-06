# ConvertTo-NetCdfFromHdf5

## Synopsis

Converts HDF5 file to NetCDF format.

## Description

Converts an HDF5 (Hierarchical Data Format version 5) file directly to NetCDF format. Both are scientific data formats commonly used for storing large datasets. Requires Python with h5py and netCDF4 packages to be installed.

## Signature

```powershell
ConvertTo-NetCdfFromHdf5
```

## Parameters

### -InputPath

The path to the HDF5 file.

### -OutputPath

The path for the output NetCDF file. If not specified, uses input path with .nc extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `h5-to-nc` - Converts HDF5 file to NetCDF format.
- `hdf5-to-netcdf` - Converts HDF5 file to NetCDF format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-direct.ps1
