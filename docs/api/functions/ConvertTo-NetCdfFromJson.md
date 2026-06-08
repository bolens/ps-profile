# ConvertTo-NetCdfFromJson

## Synopsis

Converts JSON file to NetCDF format.

## Description

Converts a JSON file to NetCDF (Network Common Data Form) format. Requires Python with netCDF4 package to be installed.

## Signature

```powershell
ConvertTo-NetCdfFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output NetCDF file. If not specified, uses input path with .nc extension.


## Examples

### Example 1

```powershell
ConvertTo-NetCdfFromJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `json-to-nc` - Converts JSON file to NetCDF format.
- `json-to-netcdf` - Converts JSON file to NetCDF format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-netcdf.ps1
