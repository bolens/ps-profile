# ConvertTo-CfgFromYaml

## Synopsis

Converts YAML file to CFG/ConfigParser format.

## Description

Converts a YAML file to CFG/ConfigParser format. Converts through JSON as an intermediate format.

## Signature

```powershell
ConvertTo-CfgFromYaml
```

## Parameters

### -InputPath

The path to the YAML file.

### -OutputPath

The path for the output CFG file. If not specified, uses input path with .cfg extension.


## Examples

### Example 1

```powershell
ConvertTo-CfgFromYaml -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `yaml-to-cfg` - Converts YAML file to CFG/ConfigParser format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/cfg.ps1
