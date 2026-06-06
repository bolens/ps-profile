# ConvertTo-SpssFromJson

## Synopsis

Converts JSON file to SPSS format.

## Description

Converts a JSON file to SPSS .sav format. Requires Python with pandas/polars and pyreadstat packages to be installed.

## Signature

```powershell
ConvertTo-SpssFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output SPSS file. If not specified, uses input path with .sav extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `json-to-sav` - Converts JSON file to SPSS format.
- `json-to-spss` - Converts JSON file to SPSS format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-spss.ps1
