# ConvertTo-NetCdfFromParquet

## Synopsis

Converts Parquet file to NetCDF format.

## Description

Converts a Parquet columnar file to NetCDF (Network Common Data Form) format. Useful for converting analytics data to scientific data formats. Requires Node.js with parquetjs package and Python with netCDF4 package to be installed.

## Signature

```powershell
ConvertTo-NetCdfFromParquet
```

## Parameters

### -InputPath

The path to the Parquet file.

### -OutputPath

The path for the output NetCDF file. If not specified, uses input path with .nc extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `parquet-to-nc` - Converts Parquet file to NetCDF format.
- `parquet-to-netcdf` - Converts Parquet file to NetCDF format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-to-columnar.ps1
