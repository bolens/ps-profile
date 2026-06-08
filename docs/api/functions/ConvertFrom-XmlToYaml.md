# ConvertFrom-XmlToYaml

## Synopsis

Converts XML file to YAML format.

## Description

Converts an XML file directly to YAML format using yq. This direct conversion is more efficient than converting through JSON. Requires yq to be installed.

## Signature

```powershell
ConvertFrom-XmlToYaml
```

## Parameters

### -InputPath

The path to the XML file.

### -OutputPath

The path for the output YAML file. If not specified, uses input path with .yaml extension.


## Examples

### Example 1

```powershell
ConvertFrom-XmlToYaml -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `xml-to-yaml` - Converts XML file to YAML format.


## Source

Defined in: ../profile.d/conversion-modules/data/core/json-extended.ps1
