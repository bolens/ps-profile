# ConvertFrom-BsonToCsv

## Synopsis

Converts BSON file to CSV format.

## Description

Converts a BSON (Binary JSON) file to CSV format for easy inspection and debugging. Requires Node.js and the bson package to be installed.

## Signature

```powershell
ConvertFrom-BsonToCsv
```

## Parameters

### -InputPath

The path to the BSON file.

### -OutputPath

The path for the output CSV file. If not specified, uses input path with .csv extension.


## Examples

### Example 1

`powershell
ConvertFrom-BsonToCsv -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `bson-to-csv` - Converts BSON file to CSV format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-to-text.ps1
