# ConvertTo-ParquetFromHdf5

## Synopsis

Converts HDF5 file to Parquet format.

## Description

Converts an HDF5 (Hierarchical Data Format version 5) file to Parquet columnar format. Useful for converting scientific data formats to analytics-friendly columnar storage. Requires Python with h5py package and Node.js with parquetjs package to be installed.

## Signature

```powershell
ConvertTo-ParquetFromHdf5
```

## Parameters

### -InputPath

The path to the HDF5 file.

### -OutputPath

The path for the output Parquet file. If not specified, uses input path with .parquet extension.


## Examples

### Example 1

`powershell
ConvertTo-ParquetFromHdf5 -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `h5-to-parquet` - Converts HDF5 file to Parquet format.
- `hdf5-to-parquet` - Converts HDF5 file to Parquet format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-to-columnar.ps1
