# ConvertTo-CborFromJson

## Synopsis

Converts JSON file to CBOR format.

## Description

Converts a JSON file to CBOR (Concise Binary Object Representation) format. Requires Node.js and the cbor package to be installed.

## Signature

```powershell
ConvertTo-CborFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output CBOR file. If not specified, uses input path with .cbor extension.


## Examples

### Example 1

`powershell
ConvertTo-CborFromJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `json-to-cbor` - Converts JSON file to CBOR format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-simple.ps1
