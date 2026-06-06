# ConvertTo-JsoncFromJson

## Synopsis

Converts a JSON file to JSONC format.

## Description

Converts a standard JSON file to JSONC format. Note: Comments are not automatically added - the output is valid JSONC without comments.

## Signature

```powershell
ConvertTo-JsoncFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output JSONC file. If not specified, uses input path with .jsonc extension.


## Outputs

System.String Returns the path to the output JSONC file.


## Examples

### Example 1

`powershell
ConvertTo-JsoncFromJson -InputPath 'settings.json'
    
    Converts settings.json to settings.jsonc.
``

## Aliases

This function has the following aliases:

- `json-to-jsonc` - Converts a JSON file to JSONC format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/jsonc.ps1
