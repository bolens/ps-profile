# ConvertTo-JsonLFromYaml

## Synopsis

Converts YAML file to JSONL format.

## Description

Converts a YAML file to JSONL (JSON Lines) format by first converting to JSON, then splitting into individual lines if the data is an array.

## Signature

```powershell
ConvertTo-JsonLFromYaml
```

## Parameters

### -InputPath

The path to the YAML file.

### -OutputPath

The path for the output JSONL file. If not specified, uses input path with .jsonl extension.


## Examples

### Example 1

```powershell
ConvertTo-JsonLFromYaml -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `yaml-to-jsonl` - Converts YAML file to JSONL format.


## Source

Defined in: ../profile.d/conversion-modules/data/core/text-gaps.ps1
