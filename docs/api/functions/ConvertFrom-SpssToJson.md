# ConvertFrom-SpssToJson

## Synopsis

Converts SPSS file to JSON format.

## Description

Converts a SPSS data file (.sav, .zsav, or .por) to JSON format. Requires Python with pandas/polars and pyreadstat packages to be installed.

## Signature

```powershell
ConvertFrom-SpssToJson
```

## Parameters

### -InputPath

The path to the SPSS file (.sav, .zsav, or .por extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

```powershell
ConvertFrom-SpssToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `sav-to-json` - Converts SPSS file to JSON format.
- `spss-to-json` - Converts SPSS file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-spss.ps1
