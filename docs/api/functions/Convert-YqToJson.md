# Convert-YqToJson

## Synopsis

Converts YAML to JSON format using yq.

## Description

Uses yq to convert YAML files to JSON format.

## Signature

```powershell
Convert-YqToJson
```

## Parameters

### -File

Path to the YAML file to convert.


## Examples

### Example 1

`powershell
Convert-YqToJson -File "config.yaml"
``

### Example 2

`powershell
Convert-YqToJson -File "data.yaml"
``

## Aliases

This function has the following aliases:

- `yq2json` - Converts YAML to JSON format using yq.


## Source

Defined in: ..\profile.d\jq-yq.ps1
