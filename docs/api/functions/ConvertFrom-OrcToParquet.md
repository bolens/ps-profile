# ConvertFrom-OrcToParquet

## Synopsis

Converts Apache ORC file to Parquet format.

## Description

Converts an Apache ORC file to Parquet format. Requires Python with pyarrow package to be installed.

## Signature

```powershell
ConvertFrom-OrcToParquet
```

## Parameters

### -InputPath

The path to the ORC file (.orc extension).

### -OutputPath

The path for the output Parquet file. If not specified, uses input path with .parquet extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `orc-to-parquet` - Converts Apache ORC file to Parquet format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-protocol-orc.ps1
