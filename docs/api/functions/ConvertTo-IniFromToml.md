# ConvertTo-IniFromToml

## Synopsis

Converts TOML file to INI format.

## Description

Converts a TOML file to INI (Initialization) format.

## Signature

```powershell
ConvertTo-IniFromToml
```

## Parameters

### -InputPath

The path to the TOML file.

### -OutputPath

The path for the output INI file. If not specified, uses input path with .ini extension.


## Examples

### Example 1

```powershell
ConvertTo-IniFromToml -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `toml-to-ini` - Converts TOML file to INI format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/ini.ps1
