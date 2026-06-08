# ConvertFrom-IniToJson

## Synopsis

Converts INI file to JSON format.

## Description

Converts an INI (Initialization) file to JSON format.

## Signature

```powershell
ConvertFrom-IniToJson
```

## Parameters

### -InputPath

The path to the INI file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

`powershell
ConvertFrom-IniToJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `ini-to-json` - Converts INI file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/ini.ps1
