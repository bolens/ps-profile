# ConvertFrom-ToonToJson

## Synopsis

Converts TOON file to JSON format.

## Description

Converts a TOON (Token-Oriented Object Notation) file back to JSON format.

## Signature

```powershell
ConvertFrom-ToonToJson
```

## Parameters

### -InputPath

The path to the TOON file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

```powershell
ConvertFrom-ToonToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `toon-to-json` - Converts TOON file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/toon.ps1
