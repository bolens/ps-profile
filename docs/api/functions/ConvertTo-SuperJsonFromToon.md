# ConvertTo-SuperJsonFromToon

## Synopsis

Converts TOON file to SuperJSON format.

## Description

Converts a TOON (Token-Oriented Object Notation) file to SuperJSON format. Requires Node.js and superjson package.

## Signature

```powershell
ConvertTo-SuperJsonFromToon
```

## Parameters

### -InputPath

The path to the TOON file.

### -OutputPath

The path for the output SuperJSON file. If not specified, uses input path with .superjson extension.


## Examples

### Example 1

`powershell
ConvertTo-SuperJsonFromToon -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `toon-to-superjson` - Converts TOON file to SuperJSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/superjson.ps1
