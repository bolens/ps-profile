# ConvertTo-Hdf5FromParquet

## Synopsis

Converts Parquet file to HDF5 format.

## Description

Converts a Parquet columnar file to HDF5 (Hierarchical Data Format version 5) format. Useful for converting analytics data to scientific data formats. Requires Node.js with parquetjs package and Python with h5py package to be installed.

## Signature

```powershell
ConvertTo-Hdf5FromParquet
```

## Parameters

### -InputPath

The path to the Parquet file.

### -OutputPath

The path for the output HDF5 file. If not specified, uses input path with .h5 extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `parquet-to-h5` - Converts Parquet file to HDF5 format.
- `parquet-to-hdf5` - Converts Parquet file to HDF5 format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-to-columnar.ps1
