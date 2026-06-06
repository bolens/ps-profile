# ConvertTo-CborFromMessagePack

## Synopsis

Converts MessagePack file to CBOR format.

## Description

Converts a MessagePack binary file directly to CBOR format without going through JSON. This direct conversion is more efficient than converting through JSON. Requires Node.js, the @msgpack/msgpack package, and the cbor package to be installed.

## Signature

```powershell
ConvertTo-CborFromMessagePack
```

## Parameters

### -InputPath

The path to the MessagePack file.

### -OutputPath

The path for the output CBOR file. If not specified, uses input path with .cbor extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `messagepack-to-cbor` - Converts MessagePack file to CBOR format.
- `msgpack-to-cbor` - Converts MessagePack file to CBOR format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-direct.ps1
