# ConvertTo-DbfFromJson

## Synopsis

Converts JSON file to DBF format.

## Description

Converts a JSON file to DBF (dBase) format. Requires Python with dbf package to be installed.

## Signature

```powershell
ConvertTo-DbfFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output DBF file. If not specified, uses input path with .dbf extension.


## Examples

### Example 1

```powershell
ConvertTo-DbfFromJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `json-to-dbf` - Converts JSON file to DBF format.


## Source

Defined in: ../profile.d/conversion-modules/data/database/database-dbf.ps1
