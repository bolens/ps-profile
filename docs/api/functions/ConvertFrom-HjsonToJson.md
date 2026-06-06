# ConvertFrom-HjsonToJson

## Synopsis

Converts an HJSON file to JSON format.

## Description

Converts an HJSON (Human JSON) file to standard JSON format. Removes comments, normalizes unquoted keys, and removes trailing commas.

## Signature

```powershell
ConvertFrom-HjsonToJson
```

## Parameters

### -InputPath

The path to the HJSON file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Outputs

System.String Returns the path to the output JSON file.


## Examples

### Example 1

`powershell
ConvertFrom-HjsonToJson -InputPath 'config.hjson'
    
    Converts config.hjson to config.json.
``

## Aliases

This function has the following aliases:

- `hjson-to-json` - Converts an HJSON file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/hjson.ps1
