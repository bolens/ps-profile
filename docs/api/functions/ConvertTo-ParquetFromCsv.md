# ConvertTo-ParquetFromCsv

## Synopsis

Converts CSV file to Parquet format.

## Description

Converts a CSV file to Parquet columnar format for efficient storage and querying. Requires Node.js and the parquetjs package to be installed.

## Signature

```powershell
ConvertTo-ParquetFromCsv
```

## Parameters

### -InputPath

The path to the CSV file.

### -OutputPath

The path for the output Parquet file. If not specified, uses input path with .parquet extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `csv-to-parquet` - Converts CSV file to Parquet format.


## Source

Defined in: ../profile.d/conversion-modules/data/columnar/columnar-to-csv.ps1
