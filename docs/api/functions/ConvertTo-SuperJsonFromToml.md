# ConvertTo-SuperJsonFromToml

## Synopsis

Converts TOML file to SuperJSON format.

## Description

Converts a TOML (Tom's Obvious, Minimal Language) file to SuperJSON format. Requires Node.js, superjson package, and yq command.

## Signature

```powershell
ConvertTo-SuperJsonFromToml
```

## Parameters

### -InputPath

The path to the TOML file.

### -OutputPath

The path for the output SuperJSON file. If not specified, uses input path with .superjson extension.


## Examples

### Example 1

`powershell
ConvertTo-SuperJsonFromToml -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `toml-to-superjson` - Converts TOML file to SuperJSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/superjson.ps1
