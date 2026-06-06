# ConvertFrom-JsoncToJson

## Synopsis

Converts a JSONC file to JSON format.

## Description

Converts a JSONC (JSON with Comments) file to standard JSON format. Removes C-style comments (// and /* */) from the file.

## Signature

```powershell
ConvertFrom-JsoncToJson
```

## Parameters

### -InputPath

The path to the JSONC file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Outputs

System.String Returns the path to the output JSON file.


## Examples

### Example 1

`powershell
ConvertFrom-JsoncToJson -InputPath 'settings.jsonc'
    
    Converts settings.jsonc to settings.json.
``

## Aliases

This function has the following aliases:

- `jsonc-to-json` - Converts a JSONC file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/jsonc.ps1
