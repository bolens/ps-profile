# ConvertTo-IniFromXml

## Synopsis

Converts XML file to INI format.

## Description

Converts an XML file to INI (Initialization) format.

## Signature

```powershell
ConvertTo-IniFromXml
```

## Parameters

### -InputPath

The path to the XML file.

### -OutputPath

The path for the output INI file. If not specified, uses input path with .ini extension.


## Examples

### Example 1

```powershell
ConvertTo-IniFromXml -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `xml-to-ini` - Converts XML file to INI format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/ini.ps1
