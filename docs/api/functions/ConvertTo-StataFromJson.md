# ConvertTo-StataFromJson

## Synopsis

Converts JSON file to Stata format.

## Description

Converts a JSON file to Stata .dta format. Requires Python with pandas/polars and pyreadstat packages to be installed.

## Signature

```powershell
ConvertTo-StataFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output Stata file. If not specified, uses input path with .dta extension.


## Examples

### Example 1

```powershell
ConvertTo-StataFromJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `json-to-dta` - Converts JSON file to Stata format.
- `json-to-stata` - Converts JSON file to Stata format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-stata.ps1
