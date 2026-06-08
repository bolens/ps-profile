# ConvertFrom-BsonToYaml

## Synopsis

Converts BSON file to YAML format.

## Description

Converts a BSON (Binary JSON) file to YAML format for easy inspection and debugging. Requires Node.js, the bson package, and yq to be installed.

## Signature

```powershell
ConvertFrom-BsonToYaml
```

## Parameters

### -InputPath

The path to the BSON file.

### -OutputPath

The path for the output YAML file. If not specified, uses input path with .yaml extension.


## Examples

### Example 1

```powershell
ConvertFrom-BsonToYaml -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `bson-to-yaml` - Converts BSON file to YAML format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-to-text.ps1
