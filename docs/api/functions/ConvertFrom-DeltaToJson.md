# ConvertFrom-DeltaToJson

## Synopsis

Converts Delta Lake table to JSON format.

## Description

Converts a Delta Lake table to JSON format. Requires Python with delta-spark or deltalake package to be installed.

## Signature

```powershell
ConvertFrom-DeltaToJson
```

## Parameters

### -InputPath

The path to the Delta Lake table directory.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `delta-to-json` - Converts Delta Lake table to JSON format.
- `deltalake-to-json` - Converts Delta Lake table to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-protocol-delta.ps1
