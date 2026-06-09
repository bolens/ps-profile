# ConvertFrom-ExcelToCsv

## Synopsis

Converts Excel file to CSV.

## Description

Uses ImportExcel module or pandoc to convert an Excel (XLSX/XLS) file to CSV format.

## Signature

```powershell
ConvertFrom-ExcelToCsv
```

## Parameters

### -InputPath

Path to the input Excel file.

### -OutputPath

Path for the output CSV file. If not specified, uses input path with .csv extension.

### -SheetName

Optional sheet name to convert. If not specified, converts the first sheet.


## Examples

### Example 1

```powershell
ConvertFrom-ExcelToCsv -InputPath "spreadsheet.xlsx" -OutputPath "spreadsheet.csv"
```

## Aliases

This function has the following aliases:

- `excel-to-csv` - Converts Excel file to CSV.
- `xls-to-csv` - Converts Excel file to CSV.
- `xlsx-to-csv` - Converts Excel file to CSV.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-excel.ps1
