# ConvertFrom-OrcToJson

## Synopsis

Converts Apache ORC file to JSON format.

## Description

Converts an Apache ORC (Optimized Row Columnar) file to JSON format. Requires Python with pyarrow package to be installed.

## Signature

```powershell
ConvertFrom-OrcToJson
```

## Parameters

### -InputPath

The path to the ORC file (.orc extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `orc-to-json` - Converts Apache ORC file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-protocol-orc.ps1
