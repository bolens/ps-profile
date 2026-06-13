# ConvertFrom-ParquetToJson

## Synopsis

Converts Parquet file to JSON format.

## Description

Converts a Parquet columnar file back to JSON format. Requires Node.js and the parquetjs package to be installed.

## Signature

```powershell
ConvertFrom-ParquetToJson
```

## Parameters

### -InputPath

The path to the Parquet file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

```powershell
ConvertFrom-ParquetToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `parquet-to-json` - Converts Parquet file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/columnar/columnar-parquet.ps1
