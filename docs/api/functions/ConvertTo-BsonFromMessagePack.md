# ConvertTo-BsonFromMessagePack

## Synopsis

Converts MessagePack file to BSON format.

## Description

Converts a MessagePack binary file directly to BSON format without going through JSON. This direct conversion is more efficient than converting through JSON. Requires Node.js, the bson package, and the @msgpack/msgpack package to be installed.

## Signature

```powershell
ConvertTo-BsonFromMessagePack
```

## Parameters

### -InputPath

The path to the MessagePack file.

### -OutputPath

The path for the output BSON file. If not specified, uses input path with .bson extension.


## Examples

### Example 1

`powershell
ConvertTo-BsonFromMessagePack -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `messagepack-to-bson` - Converts MessagePack file to BSON format.
- `msgpack-to-bson` - Converts MessagePack file to BSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-direct.ps1
