# ConvertFrom-IcebergToParquet

## Synopsis

Converts Apache Iceberg table to Parquet format.

## Description

Converts an Apache Iceberg table to Parquet format. Note: Full Iceberg support requires catalog configuration. This is a simplified implementation. Requires Python with pyiceberg and pyarrow packages to be installed.

## Signature

```powershell
ConvertFrom-IcebergToParquet
```

## Parameters

### -InputPath

The path to the Iceberg table directory or metadata file.

### -OutputPath

The path for the output Parquet file. If not specified, uses input path with .parquet extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `iceberg-to-parquet` - Converts Apache Iceberg table to Parquet format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-protocol-iceberg.ps1
