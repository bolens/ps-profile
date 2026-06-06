# ConvertTo-HjsonFromYaml

## Synopsis

Converts a YAML file to HJSON format.

## Description

Converts a YAML file to HJSON format via JSON intermediate conversion.

## Signature

```powershell
ConvertTo-HjsonFromYaml
```

## Parameters

### -InputPath

The path to the YAML file.

### -OutputPath

The path for the output HJSON file. If not specified, uses input path with .hjson extension.


## Outputs

System.String Returns the path to the output HJSON file.


## Examples

### Example 1

`powershell
ConvertTo-HjsonFromYaml -InputPath 'config.yaml'
    
    Converts config.yaml to config.hjson.
``

## Aliases

This function has the following aliases:

- `yaml-to-hjson` - Converts a YAML file to HJSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/hjson.ps1
