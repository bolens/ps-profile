# ConvertFrom-JsoncToYaml

## Synopsis

Converts a JSONC file to YAML format.

## Description

Converts a JSONC file to YAML format via JSON intermediate conversion.

## Signature

```powershell
ConvertFrom-JsoncToYaml
```

## Parameters

### -InputPath

The path to the JSONC file.

### -OutputPath

The path for the output YAML file. If not specified, uses input path with .yaml extension.


## Outputs

System.String Returns the path to the output YAML file.


## Examples

### Example 1

`powershell
ConvertFrom-JsoncToYaml -InputPath 'settings.jsonc'
    
    Converts settings.jsonc to settings.yaml.
``

## Aliases

This function has the following aliases:

- `jsonc-to-yaml` - Converts a JSONC file to YAML format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/jsonc.ps1
