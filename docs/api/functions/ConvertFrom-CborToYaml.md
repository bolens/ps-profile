# ConvertFrom-CborToYaml

## Synopsis

Converts CBOR file to YAML format.

## Description

Converts a CBOR (Concise Binary Object Representation) file to YAML format for easy inspection and debugging. Requires Node.js, the cbor package, and yq to be installed.

## Signature

```powershell
ConvertFrom-CborToYaml
```

## Parameters

### -InputPath

The path to the CBOR file.

### -OutputPath

The path for the output YAML file. If not specified, uses input path with .yaml extension.


## Examples

### Example 1

```powershell
ConvertFrom-CborToYaml -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `cbor-to-yaml` - Converts CBOR file to YAML format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-to-text.ps1
