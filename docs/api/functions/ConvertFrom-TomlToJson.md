# ConvertFrom-TomlToJson

## Synopsis

Converts TOML file to JSON format.

## Description

Converts a TOML (Tom's Obvious, Minimal Language) file to JSON format using yq.

## Signature

```powershell
ConvertFrom-TomlToJson
```

## Parameters

### -InputPath

The path to the TOML file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

`powershell
ConvertFrom-TomlToJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `toml-to-json` - Converts TOML file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/toml.ps1
