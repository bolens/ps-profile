# ConvertFrom-CborToCsv

## Synopsis

Converts CBOR file to CSV format.

## Description

Converts a CBOR (Concise Binary Object Representation) file to CSV format for easy inspection and debugging. Requires Node.js and the cbor package to be installed.

## Signature

```powershell
ConvertFrom-CborToCsv
```

## Parameters

### -InputPath

The path to the CBOR file.

### -OutputPath

The path for the output CSV file. If not specified, uses input path with .csv extension.


## Examples

### Example 1

`powershell
ConvertFrom-CborToCsv -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `cbor-to-csv` - Converts CBOR file to CSV format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-to-text.ps1
