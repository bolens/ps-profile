# ConvertFrom-IniToYaml

## Synopsis

Converts INI file to YAML format.

## Description

Converts an INI (Initialization) file to YAML format.

## Signature

```powershell
ConvertFrom-IniToYaml
```

## Parameters

### -InputPath

The path to the INI file.

### -OutputPath

The path for the output YAML file. If not specified, uses input path with .yaml extension.


## Examples

### Example 1

```powershell
ConvertFrom-IniToYaml -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `ini-to-yaml` - Converts INI file to YAML format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/ini.ps1
