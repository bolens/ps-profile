# ConvertTo-ToonFromCsv

## Synopsis

Converts CSV file to TOON format.

## Description

Converts a CSV file to TOON (Token-Oriented Object Notation) format.

## Signature

```powershell
ConvertTo-ToonFromCsv
```

## Parameters

### -InputPath

The path to the CSV file.

### -OutputPath

The path for the output TOON file. If not specified, uses input path with .toon extension.


## Examples

### Example 1

```powershell
ConvertTo-ToonFromCsv -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `csv-to-toon` - Converts CSV file to TOON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/toon.ps1
