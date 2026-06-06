# ConvertFrom-OdsToCsv

## Synopsis

Converts ODS file to CSV.

## Description

Uses pandoc or LibreOffice to convert an ODS (OpenDocument Spreadsheet) file to CSV format.

## Signature

```powershell
ConvertFrom-OdsToCsv
```

## Parameters

### -InputPath

Path to the input ODS file.

### -OutputPath

Path for the output CSV file. If not specified, uses input path with .csv extension.


## Examples

### Example 1

`powershell
ConvertFrom-OdsToCsv -InputPath "spreadsheet.ods" -OutputPath "spreadsheet.csv"
``

## Aliases

This function has the following aliases:

- `ods-to-csv` - Converts ODS file to CSV.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-ods.ps1
