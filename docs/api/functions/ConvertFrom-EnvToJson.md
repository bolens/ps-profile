# ConvertFrom-EnvToJson

## Synopsis

Converts a .env file to JSON format.

## Description

Converts a .env file (environment variables) to JSON format. Parses key=value pairs and converts them to a JSON object.

## Signature

```powershell
ConvertFrom-EnvToJson
```

## Parameters

### -InputPath

The path to the .env file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Outputs

System.String Returns the path to the output JSON file.


## Examples

### Example 1

`powershell
ConvertFrom-EnvToJson -InputPath '.env'
    
    Converts .env to .env.json.
``

## Aliases

This function has the following aliases:

- `env-to-json` - Converts a .env file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/env.ps1
