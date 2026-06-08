# ConvertFrom-MessagePackToJson

## Synopsis

Converts MessagePack file to JSON format.

## Description

Converts a MessagePack binary file back to JSON format. Requires Node.js and the @msgpack/msgpack package to be installed.

## Signature

```powershell
ConvertFrom-MessagePackToJson
```

## Parameters

### -InputPath

The path to the MessagePack file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

```powershell
ConvertFrom-MessagePackToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `messagepack-to-json` - Converts MessagePack file to JSON format.
- `msgpack-to-json` - Converts MessagePack file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-simple.ps1
