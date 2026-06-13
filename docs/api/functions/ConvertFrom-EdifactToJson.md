# ConvertFrom-EdifactToJson

## Synopsis

Converts EDIFACT file to JSON format.

## Description

Parses an EDIFACT (Electronic Data Interchange) file and converts it to structured JSON format. EDIFACT segments are converted to a structured format with tags and elements.

## Signature

```powershell
ConvertFrom-EdifactToJson
```

## Parameters

### -InputPath

The path to the EDIFACT file (.edifact, .edi, or .edf extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertFrom-EdifactToJson -InputPath "message.edifact"
```

Converts message.edifact to message.json.

## Aliases

This function has the following aliases:

- `edifact-to-json` - Converts EDIFACT file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/edifact.ps1
