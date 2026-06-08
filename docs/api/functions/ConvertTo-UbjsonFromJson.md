# ConvertTo-UbjsonFromJson

## Synopsis

Converts JSON file to UBJSON format.

## Description

Converts a JSON file to UBJSON (Universal Binary JSON) format. UBJSON is a binary encoding of JSON that is more compact and faster to parse. Requires Node.js and the ubjson package to be installed.

## Signature

```powershell
ConvertTo-UbjsonFromJson [String]$InputPath, [String]$OutputPath
```

## Parameters

### -InputPath

**Type:** [String]

The path to the JSON file.

### -OutputPath

**Type:** [String]

The path for the output UBJSON file. If not specified, uses input path with .ubjson extension.


## Outputs

System.String Returns the path to the output UBJSON file.


## Examples

### Example 1

`powershell
ConvertTo-UbjsonFromJson -InputPath 'data.json'
    
    Converts data.json to data.ubjson.
``

## Aliases

This function has the following aliases:

- `json-to-ubjson` - Converts JSON file to UBJSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/ubjson.ps1
