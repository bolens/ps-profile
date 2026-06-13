# ConvertTo-ToonFromJson

## Synopsis

Converts JSON file to TOON format.

## Description

Converts a JSON file to TOON (Token-Oriented Object Notation) format, which removes redundant JSON syntax to reduce token usage in LLMs.

## Signature

```powershell
ConvertTo-ToonFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output TOON file. If not specified, uses input path with .toon extension.


## Examples

### Example 1

```powershell
ConvertTo-ToonFromJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `json-to-toon` - Converts JSON file to TOON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/toon.ps1
