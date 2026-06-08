# ConvertFrom-UbjsonToJson

## Synopsis

Converts UBJSON file to JSON format.

## Description

Converts a UBJSON (Universal Binary JSON) file to JSON format. UBJSON is a binary encoding of JSON that is more compact and faster to parse. Requires Node.js and the ubjson package to be installed.

## Signature

```powershell
ConvertFrom-UbjsonToJson [String]$InputPath, [String]$OutputPath
```

## Parameters

### -InputPath

**Type:** [String]

The path to the UBJSON file (.ubjson or .ubj extension).

### -OutputPath

**Type:** [String]

The path for the output JSON file. If not specified, uses input path with .json extension.


## Outputs

System.String Returns the path to the output JSON file.


## Examples

### Example 1

```powershell
ConvertFrom-UbjsonToJson -InputPath 'data.ubjson'
```

Converts data.ubjson to data.json.

## Aliases

This function has the following aliases:

- `ubjson-to-json` - Converts UBJSON file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/ubjson.ps1
