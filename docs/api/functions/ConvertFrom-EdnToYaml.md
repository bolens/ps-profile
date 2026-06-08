# ConvertFrom-EdnToYaml

## Synopsis

Converts EDN file to YAML format.

## Description

Converts an EDN (Extensible Data Notation) file to YAML format. Converts through JSON as an intermediate format.

## Signature

```powershell
ConvertFrom-EdnToYaml
```

## Parameters

### -InputPath

The path to the EDN file (.edn extension).

### -OutputPath

The path for the output YAML file. If not specified, uses input path with .yaml extension.


## Examples

### Example 1

```powershell
ConvertFrom-EdnToYaml -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `edn-to-yaml` - Converts EDN file to YAML format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/edn.ps1
