# ConvertTo-OrcFromJson

## Synopsis

Converts JSON file to Apache ORC format.

## Description

Converts a JSON file to Apache ORC (Optimized Row Columnar) format. Requires Python with pyarrow package to be installed.

## Signature

```powershell
ConvertTo-OrcFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output ORC file. If not specified, uses input path with .orc extension.


## Examples

### Example 1

```powershell
ConvertTo-OrcFromJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `json-to-orc` - Converts JSON file to Apache ORC format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-protocol-orc.ps1
