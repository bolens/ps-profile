# ConvertTo-ParquetFromNetCdf

## Synopsis

Converts NetCDF file to Parquet format.

## Description

Converts a NetCDF (Network Common Data Form) file to Parquet columnar format. Useful for converting scientific data formats to analytics-friendly columnar storage. Requires Python with netCDF4 package and Node.js with parquetjs package to be installed.

## Signature

```powershell
ConvertTo-ParquetFromNetCdf
```

## Parameters

### -InputPath

The path to the NetCDF file.

### -OutputPath

The path for the output Parquet file. If not specified, uses input path with .parquet extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `nc-to-parquet` - Converts NetCDF file to Parquet format.
- `netcdf-to-parquet` - Converts NetCDF file to Parquet format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-to-columnar.ps1
