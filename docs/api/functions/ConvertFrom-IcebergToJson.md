# ConvertFrom-IcebergToJson

## Synopsis

Converts Apache Iceberg table to JSON format.

## Description

Converts an Apache Iceberg table to JSON format. Note: Full Iceberg support requires catalog configuration. This is a simplified implementation. Requires Python with pyiceberg package to be installed.

## Signature

```powershell
ConvertFrom-IcebergToJson
```

## Parameters

### -InputPath

The path to the Iceberg table directory or metadata file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

```powershell
ConvertFrom-IcebergToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `iceberg-to-json` - Converts Apache Iceberg table to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-protocol-iceberg.ps1
