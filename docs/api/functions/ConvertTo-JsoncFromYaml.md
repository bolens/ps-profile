# ConvertTo-JsoncFromYaml

## Synopsis

Converts a YAML file to JSONC format.

## Description

Converts a YAML file to JSONC format via JSON intermediate conversion.

## Signature

```powershell
ConvertTo-JsoncFromYaml
```

## Parameters

### -InputPath

The path to the YAML file.

### -OutputPath

The path for the output JSONC file. If not specified, uses input path with .jsonc extension.


## Outputs

System.String Returns the path to the output JSONC file.


## Examples

### Example 1

```powershell
ConvertTo-JsoncFromYaml -InputPath 'settings.yaml'
```

Converts settings.yaml to settings.jsonc.

## Aliases

This function has the following aliases:

- `yaml-to-jsonc` - Converts a YAML file to JSONC format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/jsonc.ps1
