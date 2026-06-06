# ConvertFrom-ParquetToCsv

## Synopsis

Converts Parquet file to CSV format.

## Description

Converts a Parquet columnar file to CSV format for easy inspection and analysis. Requires Node.js and the parquetjs package to be installed.

## Signature

```powershell
ConvertFrom-ParquetToCsv
```

## Parameters

### -InputPath

The path to the Parquet file.

### -OutputPath

The path for the output CSV file. If not specified, uses input path with .csv extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `parquet-to-csv` - Converts Parquet file to CSV format.


## Source

Defined in: ../profile.d/conversion-modules/data/columnar/columnar-to-csv.ps1
