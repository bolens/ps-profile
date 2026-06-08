# ConvertTo-MessagePackFromCbor

## Synopsis

Converts CBOR file to MessagePack format.

## Description

Converts a CBOR (Concise Binary Object Representation) file directly to MessagePack format without going through JSON. This direct conversion is more efficient than converting through JSON. Requires Node.js, the @msgpack/msgpack package, and the cbor package to be installed.

## Signature

```powershell
ConvertTo-MessagePackFromCbor
```

## Parameters

### -InputPath

The path to the CBOR file.

### -OutputPath

The path for the output MessagePack file. If not specified, uses input path with .msgpack extension.


## Examples

### Example 1

```powershell
ConvertTo-MessagePackFromCbor -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `cbor-to-messagepack` - Converts CBOR file to MessagePack format.
- `cbor-to-msgpack` - Converts CBOR file to MessagePack format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-direct.ps1
