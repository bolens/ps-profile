# ConvertTo-XmlFromYaml

## Synopsis

Converts a YAML file to XML format.

## Description

Uses yq to transform YAML input into XML output.

## Signature

```powershell
ConvertTo-XmlFromYaml
```

## Parameters

### -InputPath

Path to the YAML source file.

### -OutputPath

Optional destination XML path.


## Examples

### Example 1

```powershell
ConvertTo-XmlFromYaml -InputPath ./config.yaml
```

## Aliases

This function has the following aliases:

- `yaml-to-xml` - Converts a YAML file to XML format.


## Source

Defined in: ../profile.d/conversion-modules/data/core/text-gaps.ps1
