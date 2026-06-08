# ConvertTo-TomlFromJson

## Synopsis

Converts JSON file to TOML format.

## Description

Converts a JSON file to TOML (Tom's Obvious, Minimal Language) format using yq.

## Signature

```powershell
ConvertTo-TomlFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output TOML file. If not specified, uses input path with .toml extension.


## Examples

### Example 1

`powershell
ConvertTo-TomlFromJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `json-to-toml` - Converts JSON file to TOML format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/toml.ps1
