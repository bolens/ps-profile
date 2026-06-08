# ConvertTo-SuperJsonFromJson

## Synopsis

Converts JSON file to SuperJSON format.

## Description

Converts a JSON file to SuperJSON format, which extends JSON to support additional types like Date, Map, Set, etc. Requires Node.js and the superjson package to be installed.

## Signature

```powershell
ConvertTo-SuperJsonFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output SuperJSON file. If not specified, uses input path with .superjson extension.


## Examples

### Example 1

`powershell
ConvertTo-SuperJsonFromJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `json-to-superjson` - Converts JSON file to SuperJSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/superjson.ps1
