# ConvertFrom-SuperJsonToYaml

## Synopsis

Converts SuperJSON file to YAML format.

## Description

Converts a SuperJSON file to YAML format. Requires Node.js, superjson package, and yq command.

## Signature

```powershell
ConvertFrom-SuperJsonToYaml
```

## Parameters

### -InputPath

The path to the SuperJSON file.

### -OutputPath

The path for the output YAML file. If not specified, uses input path with .yaml extension.


## Examples

### Example 1

`powershell
ConvertFrom-SuperJsonToYaml -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `superjson-to-yaml` - Converts SuperJSON file to YAML format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/superjson.ps1
