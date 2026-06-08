# ConvertTo-EnvFromYaml

## Synopsis

Converts a YAML file to .env format.

## Description

Converts a YAML file to .env format via JSON intermediate conversion.

## Signature

```powershell
ConvertTo-EnvFromYaml
```

## Parameters

### -InputPath

The path to the YAML file.

### -OutputPath

The path for the output .env file. If not specified, uses input path with .env extension.


## Outputs

System.String Returns the path to the output .env file.


## Examples

### Example 1

```powershell
ConvertTo-EnvFromYaml -InputPath 'config.yaml'
```

Converts config.yaml to config.env.

## Aliases

This function has the following aliases:

- `yaml-to-env` - Converts a YAML file to .env format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/env.ps1
