# ConvertFrom-YamlToXml

## Synopsis

Converts YAML file to XML format.

## Description

Converts a YAML file directly to XML format using yq. This direct conversion is more efficient than converting through JSON. Requires yq to be installed.

## Signature

```powershell
ConvertFrom-YamlToXml
```

## Parameters

### -InputPath

The path to the YAML file.

### -OutputPath

The path for the output XML file. If not specified, uses input path with .xml extension.


## Examples

### Example 1

`powershell
ConvertFrom-YamlToXml -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `yaml-to-xml` - Converts YAML file to XML format.


## Source

Defined in: ../profile.d/conversion-modules/data/core/json-extended.ps1
