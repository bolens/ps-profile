# ConvertFrom-DbfToJson

## Synopsis

Converts DBF file to JSON format.

## Description

Converts a DBF (dBase) file to JSON format. Requires Python with dbfread or dbf package to be installed.

## Signature

```powershell
ConvertFrom-DbfToJson
```

## Parameters

### -InputPath

The path to the DBF file (.dbf extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

```powershell
ConvertFrom-DbfToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `dbf-to-json` - Converts DBF file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/database/database-dbf.ps1
