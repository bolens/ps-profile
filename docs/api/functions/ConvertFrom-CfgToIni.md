# ConvertFrom-CfgToIni

## Synopsis

Converts CFG/ConfigParser file to INI format.

## Description

Converts a CFG/ConfigParser file to INI format. CFG and INI formats are very similar, so this is mostly a format conversion. Requires Python with configparser module (part of standard library).

## Signature

```powershell
ConvertFrom-CfgToIni
```

## Parameters

### -InputPath

The path to the CFG file (.cfg, .conf, or .config extension).

### -OutputPath

The path for the output INI file. If not specified, uses input path with .ini extension.


## Examples

### Example 1

```powershell
ConvertFrom-CfgToIni -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `cfg-to-ini` - Converts CFG/ConfigParser file to INI format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/cfg.ps1
