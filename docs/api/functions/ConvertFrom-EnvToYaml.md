# ConvertFrom-EnvToYaml

## Synopsis

Converts a .env file to YAML format.

## Description

Converts a .env file to YAML format via JSON intermediate conversion.

## Signature

```powershell
ConvertFrom-EnvToYaml
```

## Parameters

### -InputPath

The path to the .env file.

### -OutputPath

The path for the output YAML file. If not specified, uses input path with .yaml extension.


## Outputs

System.String Returns the path to the output YAML file.


## Examples

### Example 1

```powershell
ConvertFrom-EnvToYaml -InputPath '.env'
```

Converts .env to .env.yaml.

## Aliases

This function has the following aliases:

- `env-to-yaml` - Converts a .env file to YAML format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/env.ps1
