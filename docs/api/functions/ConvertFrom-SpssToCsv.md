# ConvertFrom-SpssToCsv

## Synopsis

Converts SPSS file to CSV format.

## Description

Converts a SPSS data file (.sav, .zsav, or .por) to CSV format. Requires Python with pandas/polars and pyreadstat packages to be installed.

## Signature

```powershell
ConvertFrom-SpssToCsv
```

## Parameters

### -InputPath

The path to the SPSS file (.sav, .zsav, or .por extension).

### -OutputPath

The path for the output CSV file. If not specified, uses input path with .csv extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `sav-to-csv` - Converts SPSS file to CSV format.
- `spss-to-csv` - Converts SPSS file to CSV format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-spss.ps1
