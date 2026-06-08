# ConvertFrom-SasToJson

## Synopsis

Converts SAS file to JSON format.

## Description

Converts a SAS data file (.sas7bdat or .xpt) to JSON format. Requires Python with pandas/polars and pyreadstat packages to be installed.

## Signature

```powershell
ConvertFrom-SasToJson
```

## Parameters

### -InputPath

The path to the SAS file (.sas7bdat or .xpt extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

`powershell
ConvertFrom-SasToJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `sas-to-json` - Converts SAS file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-sas.ps1
