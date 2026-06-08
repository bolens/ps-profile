# ConvertFrom-SuperJsonToJson

## Synopsis

Converts SuperJSON file to JSON format.

## Description

Converts a SuperJSON file back to standard JSON format. Requires Node.js and the superjson package to be installed.

## Signature

```powershell
ConvertFrom-SuperJsonToJson
```

## Parameters

### -InputPath

The path to the SuperJSON file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

```powershell
ConvertFrom-SuperJsonToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `superjson-to-json` - Converts SuperJSON file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/superjson.ps1
