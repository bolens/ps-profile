# ConvertFrom-JsonLToYaml

## Synopsis

Converts JSONL file to YAML format.

## Description

Converts a JSONL (JSON Lines) file to YAML format by first combining all lines into a JSON array, then converting to YAML.

## Signature

```powershell
ConvertFrom-JsonLToYaml
```

## Parameters

### -InputPath

The path to the JSONL file.

### -OutputPath

The path for the output YAML file. If not specified, uses input path with .yaml extension.


## Examples

### Example 1

`powershell
ConvertFrom-JsonLToYaml -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `jsonl-to-yaml` - Converts JSONL file to YAML format.


## Source

Defined in: ../profile.d/conversion-modules/data/core/text-gaps.ps1
