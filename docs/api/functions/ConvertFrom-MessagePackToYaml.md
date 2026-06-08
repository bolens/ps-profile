# ConvertFrom-MessagePackToYaml

## Synopsis

Converts MessagePack file to YAML format.

## Description

Converts a MessagePack binary file to YAML format for easy inspection and debugging. Requires Node.js, the @msgpack/msgpack package, and yq to be installed.

## Signature

```powershell
ConvertFrom-MessagePackToYaml
```

## Parameters

### -InputPath

The path to the MessagePack file.

### -OutputPath

The path for the output YAML file. If not specified, uses input path with .yaml extension.


## Examples

### Example 1

`powershell
ConvertFrom-MessagePackToYaml -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `messagepack-to-yaml` - Converts MessagePack file to YAML format.
- `msgpack-to-yaml` - Converts MessagePack file to YAML format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-to-text.ps1
