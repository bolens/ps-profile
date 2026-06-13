# ConvertFrom-JsonLToJson

## Synopsis

Converts JSONL file to JSON format.

## Description

Converts a JSONL (JSON Lines) file to a JSON array format.

## Signature

```powershell
ConvertFrom-JsonLToJson
```

## Parameters

### -InputPath

The path to the JSONL file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

```powershell
ConvertFrom-JsonLToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `jsonl-to-json` - Converts JSONL file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/core/json-extended.ps1
