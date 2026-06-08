# ConvertFrom-CborToJson

## Synopsis

Converts CBOR file to JSON format.

## Description

Converts a CBOR (Concise Binary Object Representation) file back to JSON format. Requires Node.js and the cbor package to be installed.

## Signature

```powershell
ConvertFrom-CborToJson
```

## Parameters

### -InputPath

The path to the CBOR file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

`powershell
ConvertFrom-CborToJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `cbor-to-json` - Converts CBOR file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-simple.ps1
