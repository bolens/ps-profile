# ConvertTo-HjsonFromJson

## Synopsis

Converts a JSON file to HJSON format.

## Description

Converts a standard JSON file to HJSON (Human JSON) format. Removes quotes from simple keys to make it more human-readable.

## Signature

```powershell
ConvertTo-HjsonFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output HJSON file. If not specified, uses input path with .hjson extension.


## Outputs

System.String Returns the path to the output HJSON file.


## Examples

### Example 1

`powershell
ConvertTo-HjsonFromJson -InputPath 'config.json'
    
    Converts config.json to config.hjson.
``

## Aliases

This function has the following aliases:

- `json-to-hjson` - Converts a JSON file to HJSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/hjson.ps1
