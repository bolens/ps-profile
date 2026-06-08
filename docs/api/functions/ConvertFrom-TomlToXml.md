# ConvertFrom-TomlToXml

## Synopsis

Converts TOML file to XML format.

## Description

Converts a TOML (Tom's Obvious, Minimal Language) file to XML format.

## Signature

```powershell
ConvertFrom-TomlToXml
```

## Parameters

### -InputPath

The path to the TOML file.

### -OutputPath

The path for the output XML file. If not specified, uses input path with .xml extension.


## Examples

### Example 1

`powershell
ConvertFrom-TomlToXml -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `toml-to-xml` - Converts TOML file to XML format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/toml.ps1
