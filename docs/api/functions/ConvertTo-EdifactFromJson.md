# ConvertTo-EdifactFromJson

## Synopsis

Converts JSON file to EDIFACT format.

## Description

Converts a structured JSON file (with EDIFACT segment structure) to EDIFACT format. The JSON should have an Interchange.Segments structure with Tag and Elements.

## Signature

```powershell
ConvertTo-EdifactFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output EDIFACT file. If not specified, uses input path with .edifact extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertTo-EdifactFromJson -InputPath "message.json"
    
    Converts message.json to message.edifact.
``

## Aliases

This function has the following aliases:

- `json-to-edifact` - Converts JSON file to EDIFACT format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/edifact.ps1
