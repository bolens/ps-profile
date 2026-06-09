# ConvertFrom-NetCdfToJson

## Synopsis

Converts NetCDF file to JSON format.

## Description

Converts a NetCDF (Network Common Data Form) file back to JSON format. Requires Python with netCDF4 package to be installed.

## Signature

```powershell
ConvertFrom-NetCdfToJson
```

## Parameters

### -InputPath

The path to the NetCDF file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

```powershell
ConvertFrom-NetCdfToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `nc-to-json` - Converts NetCDF file to JSON format.
- `netcdf-to-json` - Converts NetCDF file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-netcdf.ps1
