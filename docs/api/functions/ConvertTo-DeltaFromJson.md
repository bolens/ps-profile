# ConvertTo-DeltaFromJson

## Synopsis

Converts JSON file to Delta Lake table format.

## Description

Converts a JSON file to Delta Lake table format. Note: Full Delta Lake creation may require Spark. This implementation uses simplified approach. Requires Python with delta-spark or deltalake package to be installed.

## Signature

```powershell
ConvertTo-DeltaFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output Delta Lake table directory. If not specified, uses input path with .delta extension.


## Examples

### Example 1

```powershell
ConvertTo-DeltaFromJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `json-to-delta` - Converts JSON file to Delta Lake table format.
- `json-to-deltalake` - Converts JSON file to Delta Lake table format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-protocol-delta.ps1
