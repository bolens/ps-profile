# ConvertFrom-StataToJson

## Synopsis

Converts Stata file to JSON format.

## Description

Converts a Stata data file (.dta) to JSON format. Requires Python with pandas/polars and pyreadstat packages to be installed.

## Signature

```powershell
ConvertFrom-StataToJson
```

## Parameters

### -InputPath

The path to the Stata file (.dta extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `dta-to-json` - Converts Stata file to JSON format.
- `stata-to-json` - Converts Stata file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-stata.ps1
