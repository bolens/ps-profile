# ConvertTo-EnvFromJson

## Synopsis

Converts a JSON file to .env format.

## Description

Converts a JSON object to .env file format (key=value pairs). Each property in the JSON object becomes a key=value line in the .env file.

## Signature

```powershell
ConvertTo-EnvFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output .env file. If not specified, uses input path with .env extension.


## Outputs

System.String Returns the path to the output .env file.


## Examples

### Example 1

`powershell
ConvertTo-EnvFromJson -InputPath 'config.json'
    
    Converts config.json to config.env.
``

## Aliases

This function has the following aliases:

- `json-to-env` - Converts a JSON file to .env format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/env.ps1
