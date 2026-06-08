# ConvertTo-OdsFromCsv

## Synopsis

Converts CSV file to ODS.

## Description

Uses pandoc to convert a CSV file to ODS (OpenDocument Spreadsheet) format.

## Signature

```powershell
ConvertTo-OdsFromCsv
```

## Parameters

### -InputPath

Path to the input CSV file.

### -OutputPath

Path for the output ODS file. If not specified, uses input path with .ods extension.


## Examples

### Example 1

```powershell
ConvertTo-OdsFromCsv -InputPath "spreadsheet.csv" -OutputPath "spreadsheet.ods"
```

## Aliases

This function has the following aliases:

- `csv-to-ods` - Converts CSV file to ODS.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-ods.ps1
