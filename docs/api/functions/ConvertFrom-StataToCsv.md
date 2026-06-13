# ConvertFrom-StataToCsv

## Synopsis

Converts Stata file to CSV format.

## Description

Converts a Stata data file (.dta) to CSV format. Requires Python with pandas/polars and pyreadstat packages to be installed.

## Signature

```powershell
ConvertFrom-StataToCsv
```

## Parameters

### -InputPath

The path to the Stata file (.dta extension).

### -OutputPath

The path for the output CSV file. If not specified, uses input path with .csv extension.


## Examples

### Example 1

```powershell
ConvertFrom-StataToCsv -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `dta-to-csv` - Converts Stata file to CSV format.
- `stata-to-csv` - Converts Stata file to CSV format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-stata.ps1
