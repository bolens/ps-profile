# ConvertTo-IniFromJson

## Synopsis

Converts JSON file to INI format.

## Description

Converts a JSON file to INI (Initialization) format.

## Signature

```powershell
ConvertTo-IniFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output INI file. If not specified, uses input path with .ini extension.


## Examples

### Example 1

`powershell
ConvertTo-IniFromJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `json-to-ini` - Converts JSON file to INI format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/ini.ps1
