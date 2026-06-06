# ConvertTo-JsonLFromCsv

## Synopsis

Converts CSV file to JSONL format.

## Description

Converts a CSV file to JSONL (JSON Lines) format by converting each row to a JSON object and writing it as a separate line. Each row in the CSV becomes a line in the JSONL file.

## Signature

```powershell
ConvertTo-JsonLFromCsv
```

## Parameters

### -InputPath

The path to the CSV file.

### -OutputPath

The path for the output JSONL file. If not specified, uses input path with .jsonl extension.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `csv-to-jsonl` - Converts CSV file to JSONL format.


## Source

Defined in: ../profile.d/conversion-modules/data/core/text-gaps.ps1
