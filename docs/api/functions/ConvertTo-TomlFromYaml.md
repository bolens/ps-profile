# ConvertTo-TomlFromYaml

## Synopsis

Converts YAML file to TOML format.

## Description

Converts a YAML file to TOML (Tom's Obvious, Minimal Language) format using yq.

## Signature

```powershell
ConvertTo-TomlFromYaml
```

## Parameters

### -InputPath

The path to the YAML file.

### -OutputPath

The path for the output TOML file. If not specified, uses input path with .toml extension.


## Examples

### Example 1

`powershell
ConvertTo-TomlFromYaml -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `yaml-to-toml` - Converts YAML file to TOML format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/toml.ps1
