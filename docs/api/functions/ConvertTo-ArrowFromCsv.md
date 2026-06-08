# ConvertTo-ArrowFromCsv

## Synopsis

Converts CSV file to Arrow format.

## Description

Converts a CSV file to Arrow columnar format for efficient in-memory analytics. Requires Node.js and the apache-arrow package to be installed.

## Signature

```powershell
ConvertTo-ArrowFromCsv
```

## Parameters

### -InputPath

The path to the CSV file.

### -OutputPath

The path for the output Arrow file. If not specified, uses input path with .arrow extension.


## Examples

### Example 1

```powershell
ConvertTo-ArrowFromCsv -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `csv-to-arrow` - Converts CSV file to Arrow format.


## Source

Defined in: ../profile.d/conversion-modules/data/columnar/columnar-to-csv.ps1
