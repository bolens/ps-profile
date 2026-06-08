# ConvertFrom-IonToJson

## Synopsis

Converts Ion file to JSON format.

## Description

Converts an Ion file (text or binary) to JSON format. Ion is a richly-typed, self-describing, hierarchical data serialization format. Requires Python and the ion-python package to be installed.

## Signature

```powershell
ConvertFrom-IonToJson [String]$InputPath, [String]$OutputPath
```

## Parameters

### -InputPath

**Type:** [String]

The path to the Ion file (.ion for text, .10n for binary).

### -OutputPath

**Type:** [String]

The path for the output JSON file. If not specified, uses input path with .json extension.


## Outputs

System.String Returns the path to the output JSON file.


## Examples

### Example 1

`powershell
ConvertFrom-IonToJson -InputPath 'data.ion'
    
    Converts data.ion to data.json.
``

## Aliases

This function has the following aliases:

- `ion-to-json` - Converts Ion file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/ion.ps1
