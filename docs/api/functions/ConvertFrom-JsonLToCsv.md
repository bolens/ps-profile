# ConvertFrom-JsonLToCsv

## Synopsis

Converts JSONL file to CSV format.

## Description

Converts a JSONL (JSON Lines) file to CSV format by parsing each line as a JSON object and combining them into a CSV file. Each line in the JSONL file becomes a row in the CSV.

## Signature

```powershell
ConvertFrom-JsonLToCsv
```

## Parameters

### -InputPath

The path to the JSONL file.

### -OutputPath

The path for the output CSV file. If not specified, uses input path with .csv extension.


## Examples

### Example 1

`powershell
ConvertFrom-JsonLToCsv -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `jsonl-to-csv` - Converts JSONL file to CSV format.


## Source

Defined in: ../profile.d/conversion-modules/data/core/text-gaps.ps1
