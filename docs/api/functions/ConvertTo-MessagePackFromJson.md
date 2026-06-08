# ConvertTo-MessagePackFromJson

## Synopsis

Converts JSON file to MessagePack format.

## Description

Converts a JSON file to MessagePack binary format. Requires Node.js and the @msgpack/msgpack package to be installed.

## Signature

```powershell
ConvertTo-MessagePackFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output MessagePack file. If not specified, uses input path with .msgpack extension.


## Examples

### Example 1

`powershell
ConvertTo-MessagePackFromJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `json-to-messagepack` - Converts JSON file to MessagePack format.
- `json-to-msgpack` - Converts JSON file to MessagePack format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-simple.ps1
