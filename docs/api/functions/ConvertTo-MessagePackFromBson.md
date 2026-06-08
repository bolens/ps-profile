# ConvertTo-MessagePackFromBson

## Synopsis

Converts BSON file to MessagePack format.

## Description

Converts a BSON (Binary JSON) file directly to MessagePack format without going through JSON. This direct conversion is more efficient than converting through JSON. Requires Node.js, the bson package, and the @msgpack/msgpack package to be installed.

## Signature

```powershell
ConvertTo-MessagePackFromBson
```

## Parameters

### -InputPath

The path to the BSON file.

### -OutputPath

The path for the output MessagePack file. If not specified, uses input path with .msgpack extension.


## Examples

### Example 1

`powershell
ConvertTo-MessagePackFromBson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `bson-to-messagepack` - Converts BSON file to MessagePack format.
- `bson-to-msgpack` - Converts BSON file to MessagePack format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-direct.ps1
