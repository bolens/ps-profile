# ConvertFrom-DeltaToParquet

## Synopsis

Converts Delta Lake table to Parquet format.

## Description

Converts a Delta Lake table to Parquet format. Requires Python with delta-spark or deltalake and pyarrow packages to be installed.

## Signature

```powershell
ConvertFrom-DeltaToParquet
```

## Parameters

### -InputPath

The path to the Delta Lake table directory.

### -OutputPath

The path for the output Parquet file. If not specified, uses input path with .parquet extension.


## Examples

### Example 1

`powershell
ConvertFrom-DeltaToParquet -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `delta-to-parquet` - Converts Delta Lake table to Parquet format.
- `deltalake-to-parquet` - Converts Delta Lake table to Parquet format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-protocol-delta.ps1
