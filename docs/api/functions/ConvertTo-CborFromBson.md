# ConvertTo-CborFromBson

## Synopsis

Converts BSON file to CBOR format.

## Description

Converts a BSON (Binary JSON) file directly to CBOR format without going through JSON. This direct conversion is more efficient than converting through JSON. Requires Node.js, the bson package, and the cbor package to be installed.

## Signature

```powershell
ConvertTo-CborFromBson
```

## Parameters

### -InputPath

The path to the BSON file.

### -OutputPath

The path for the output CBOR file. If not specified, uses input path with .cbor extension.


## Examples

### Example 1

```powershell
ConvertTo-CborFromBson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `bson-to-cbor` - Converts BSON file to CBOR format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-direct.ps1
