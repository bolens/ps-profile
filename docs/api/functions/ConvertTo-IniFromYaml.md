# ConvertTo-IniFromYaml

## Synopsis

Converts YAML file to INI format.

## Description

Converts a YAML file to INI (Initialization) format.

## Signature

```powershell
ConvertTo-IniFromYaml
```

## Parameters

### -InputPath

The path to the YAML file.

### -OutputPath

The path for the output INI file. If not specified, uses input path with .ini extension.


## Examples

### Example 1

`powershell
ConvertTo-IniFromYaml -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `yaml-to-ini` - Converts YAML file to INI format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/ini.ps1
