# ConvertTo-IcebergFromJson

## Synopsis

Converts JSON file to Apache Iceberg table format.

## Description

Converts a JSON file to Apache Iceberg table format. Note: Full Iceberg support requires catalog configuration. This is a simplified implementation. Requires Python with pyiceberg package to be installed.

## Signature

```powershell
ConvertTo-IcebergFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output Iceberg table directory. If not specified, uses input path with .iceberg extension.


## Examples

### Example 1

`powershell
ConvertTo-IcebergFromJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `json-to-iceberg` - Converts JSON file to Apache Iceberg table format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-protocol-iceberg.ps1
