# ConvertFrom-CfgToJson

## Synopsis

Converts CFG/ConfigParser file to JSON format.

## Description

Converts a CFG/ConfigParser (Python configuration) file to JSON format. Requires Python with configparser module (part of standard library).

## Signature

```powershell
ConvertFrom-CfgToJson
```

## Parameters

### -InputPath

The path to the CFG file (.cfg, .conf, or .config extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

`powershell
ConvertFrom-CfgToJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `cfg-to-json` - Converts CFG/ConfigParser file to JSON format.
- `configparser-to-json` - Converts CFG/ConfigParser file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/cfg.ps1
