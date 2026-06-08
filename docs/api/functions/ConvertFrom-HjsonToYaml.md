# ConvertFrom-HjsonToYaml

## Synopsis

Converts an HJSON file to YAML format.

## Description

Converts an HJSON file to YAML format via JSON intermediate conversion.

## Signature

```powershell
ConvertFrom-HjsonToYaml
```

## Parameters

### -InputPath

The path to the HJSON file.

### -OutputPath

The path for the output YAML file. If not specified, uses input path with .yaml extension.


## Outputs

System.String Returns the path to the output YAML file.


## Examples

### Example 1

```powershell
ConvertFrom-HjsonToYaml -InputPath 'config.hjson'
```

Converts config.hjson to config.yaml.

## Aliases

This function has the following aliases:

- `hjson-to-yaml` - Converts an HJSON file to YAML format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/hjson.ps1
