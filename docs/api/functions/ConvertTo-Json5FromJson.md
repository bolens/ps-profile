# ConvertTo-Json5FromJson

## Synopsis

Converts JSON file to JSON5 format.

## Description

Converts a JSON file to JSON5 format (JSON with comments and trailing commas support). Requires Node.js and the json5 package to be installed.

## Signature

```powershell
ConvertTo-Json5FromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output JSON5 file. If not specified, uses input path with .json5 extension.


## Examples

### Example 1

`powershell
ConvertTo-Json5FromJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `json-to-json5` - Converts JSON file to JSON5 format.


## Source

Defined in: ../profile.d/conversion-modules/data/core/json-extended.ps1
