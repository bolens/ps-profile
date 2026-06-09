# ConvertFrom-TomlToToon

## Synopsis

Converts TOML file to TOON format.

## Description

Converts a TOML (Tom's Obvious, Minimal Language) file to TOON (Token-Oriented Object Notation) format.

## Signature

```powershell
ConvertFrom-TomlToToon
```

## Parameters

### -InputPath

The path to the TOML file.

### -OutputPath

The path for the output TOON file. If not specified, uses input path with .toon extension.


## Examples

### Example 1

```powershell
ConvertFrom-TomlToToon -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `toml-to-toon` - Converts TOML file to TOON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/toml.ps1
