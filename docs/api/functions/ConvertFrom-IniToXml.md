# ConvertFrom-IniToXml

## Synopsis

Converts INI file to XML format.

## Description

Converts an INI (Initialization) file to XML format.

## Signature

```powershell
ConvertFrom-IniToXml
```

## Parameters

### -InputPath

The path to the INI file.

### -OutputPath

The path for the output XML file. If not specified, uses input path with .xml extension.


## Examples

### Example 1

```powershell
ConvertFrom-IniToXml -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `ini-to-xml` - Converts INI file to XML format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/ini.ps1
