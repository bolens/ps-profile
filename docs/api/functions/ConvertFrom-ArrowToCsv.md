# ConvertFrom-ArrowToCsv

## Synopsis

Converts Arrow file to CSV format.

## Description

Converts an Arrow columnar file to CSV format for easy inspection and analysis. Requires Node.js and the apache-arrow package to be installed.

## Signature

```powershell
ConvertFrom-ArrowToCsv
```

## Parameters

### -InputPath

The path to the Arrow file.

### -OutputPath

The path for the output CSV file. If not specified, uses input path with .csv extension.


## Examples

### Example 1

```powershell
ConvertFrom-ArrowToCsv -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `arrow-to-csv` - Converts Arrow file to CSV format.


## Source

Defined in: ../profile.d/conversion-modules/data/columnar/columnar-to-csv.ps1
