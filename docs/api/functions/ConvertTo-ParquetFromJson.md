# ConvertTo-ParquetFromJson

## Synopsis

Converts JSON file to Parquet format.

## Description

Converts a JSON file to Parquet columnar format. Requires Node.js and the parquetjs package to be installed. Note: Parquet conversion requires schema definition.

## Signature

```powershell
ConvertTo-ParquetFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output Parquet file. If not specified, uses input path with .parquet extension.


## Examples

### Example 1

`powershell
ConvertTo-ParquetFromJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `json-to-parquet` - Converts JSON file to Parquet format.


## Source

Defined in: ../profile.d/conversion-modules/data/columnar/columnar-parquet.ps1
