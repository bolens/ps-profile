# ConvertTo-ParquetFromArrow

## Synopsis

Converts Arrow file to Parquet format.

## Description

Converts an Arrow columnar file directly to Parquet format. Requires Node.js, the apache-arrow package, and the parquetjs package to be installed. Note: Direct conversion requires Arrow Table API - currently uses JSON as intermediate.

## Signature

```powershell
ConvertTo-ParquetFromArrow
```

## Parameters

### -InputPath

The path to the Arrow file.

### -OutputPath

The path for the output Parquet file. If not specified, uses input path with .parquet extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `arrow-to-parquet` - Converts Arrow file to Parquet format.


## Source

Defined in: ../profile.d/conversion-modules/data/columnar/columnar-direct.ps1
