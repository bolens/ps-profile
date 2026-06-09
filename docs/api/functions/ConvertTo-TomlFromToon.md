# ConvertTo-TomlFromToon

## Synopsis

Converts TOON file to TOML format.

## Description

Converts a TOON (Token-Oriented Object Notation) file to TOML (Tom's Obvious, Minimal Language) format.

## Signature

```powershell
ConvertTo-TomlFromToon
```

## Parameters

### -InputPath

The path to the TOON file.

### -OutputPath

The path for the output TOML file. If not specified, uses input path with .toml extension.


## Examples

### Example 1

```powershell
ConvertTo-TomlFromToon -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `toon-to-toml` - Converts TOON file to TOML format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/toml.ps1
