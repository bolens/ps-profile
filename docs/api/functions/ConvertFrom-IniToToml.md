# ConvertFrom-IniToToml

## Synopsis

Converts INI file to TOML format.

## Description

Converts an INI (Initialization) file to TOML format.

## Signature

```powershell
ConvertFrom-IniToToml
```

## Parameters

### -InputPath

The path to the INI file.

### -OutputPath

The path for the output TOML file. If not specified, uses input path with .toml extension.


## Examples

### Example 1

```powershell
ConvertFrom-IniToToml -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `ini-to-toml` - Converts INI file to TOML format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/ini.ps1
