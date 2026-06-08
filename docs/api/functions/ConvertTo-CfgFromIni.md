# ConvertTo-CfgFromIni

## Synopsis

Converts INI file to CFG/ConfigParser format.

## Description

Converts an INI file to CFG/ConfigParser format. CFG and INI formats are very similar, so this is mostly a format conversion. Requires Python with configparser module (part of standard library).

## Signature

```powershell
ConvertTo-CfgFromIni
```

## Parameters

### -InputPath

The path to the INI file.

### -OutputPath

The path for the output CFG file. If not specified, uses input path with .cfg extension.


## Examples

### Example 1

`powershell
ConvertTo-CfgFromIni -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `ini-to-cfg` - Converts INI file to CFG/ConfigParser format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/cfg.ps1
