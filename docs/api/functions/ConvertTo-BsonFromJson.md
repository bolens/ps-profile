# ConvertTo-BsonFromJson

## Synopsis

Converts JSON file to BSON format.

## Description

Converts a JSON file to BSON (Binary JSON) format. Requires Node.js and the bson package to be installed.

## Signature

```powershell
ConvertTo-BsonFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output BSON file. If not specified, uses input path with .bson extension.


## Examples

### Example 1

```powershell
ConvertTo-BsonFromJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `json-to-bson` - Converts JSON file to BSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-simple.ps1
