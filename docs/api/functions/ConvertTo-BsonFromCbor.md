# ConvertTo-BsonFromCbor

## Synopsis

Converts CBOR file to BSON format.

## Description

Converts a CBOR (Concise Binary Object Representation) file directly to BSON format without going through JSON. This direct conversion is more efficient than converting through JSON. Requires Node.js, the bson package, and the cbor package to be installed.

## Signature

```powershell
ConvertTo-BsonFromCbor
```

## Parameters

### -InputPath

The path to the CBOR file.

### -OutputPath

The path for the output BSON file. If not specified, uses input path with .bson extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `cbor-to-bson` - Converts CBOR file to BSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-direct.ps1
