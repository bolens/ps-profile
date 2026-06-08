# ConvertTo-SasFromJson

## Synopsis

Converts JSON file to SAS format.

## Description

Converts a JSON file to SAS .sas7bdat format. Requires Python with pandas/polars and pyreadstat packages to be installed.

## Signature

```powershell
ConvertTo-SasFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output SAS file. If not specified, uses input path with .sas7bdat extension.


## Examples

### Example 1

`powershell
ConvertTo-SasFromJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `json-to-sas` - Converts JSON file to SAS format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-sas.ps1
