# ConvertTo-CfgFromJson

## Synopsis

Converts JSON file to CFG/ConfigParser format.

## Description

Converts a JSON file to CFG/ConfigParser (Python configuration) format. Requires Python with configparser module (part of standard library).

## Signature

```powershell
ConvertTo-CfgFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output CFG file. If not specified, uses input path with .cfg extension.


## Examples

### Example 1

```powershell
ConvertTo-CfgFromJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `json-to-cfg` - Converts JSON file to CFG/ConfigParser format.
- `json-to-configparser` - Converts JSON file to CFG/ConfigParser format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/cfg.ps1
