# ConvertTo-SuperJsonFromYaml

## Synopsis

Converts YAML file to SuperJSON format.

## Description

Converts a YAML file to SuperJSON format. Requires Node.js, superjson package, and yq command.

## Signature

```powershell
ConvertTo-SuperJsonFromYaml
```

## Parameters

### -InputPath

The path to the YAML file.

### -OutputPath

The path for the output SuperJSON file. If not specified, uses input path with .superjson extension.


## Examples

### Example 1

```powershell
ConvertTo-SuperJsonFromYaml -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `yaml-to-superjson` - Converts YAML file to SuperJSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/superjson.ps1
