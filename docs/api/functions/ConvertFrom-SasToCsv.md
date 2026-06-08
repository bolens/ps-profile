# ConvertFrom-SasToCsv

## Synopsis

Converts SAS file to CSV format.

## Description

Converts a SAS data file (.sas7bdat or .xpt) to CSV format. Requires Python with pandas/polars and pyreadstat packages to be installed.

## Signature

```powershell
ConvertFrom-SasToCsv
```

## Parameters

### -InputPath

The path to the SAS file (.sas7bdat or .xpt extension).

### -OutputPath

The path for the output CSV file. If not specified, uses input path with .csv extension.


## Examples

### Example 1

`powershell
ConvertFrom-SasToCsv -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `sas-to-csv` - Converts SAS file to CSV format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-sas.ps1
