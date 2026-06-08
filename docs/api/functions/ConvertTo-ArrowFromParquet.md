# ConvertTo-ArrowFromParquet

## Synopsis

Converts Parquet file to Arrow format.

## Description

Converts a Parquet columnar file directly to Arrow format. Requires Node.js, the parquetjs package, and the apache-arrow package to be installed. Note: Direct conversion requires Arrow Table API - currently uses JSON as intermediate.

## Signature

```powershell
ConvertTo-ArrowFromParquet
```

## Parameters

### -InputPath

The path to the Parquet file.

### -OutputPath

The path for the output Arrow file. If not specified, uses input path with .arrow extension.


## Examples

### Example 1

```powershell
ConvertTo-ArrowFromParquet -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `parquet-to-arrow` - Converts Parquet file to Arrow format.


## Source

Defined in: ../profile.d/conversion-modules/data/columnar/columnar-direct.ps1
