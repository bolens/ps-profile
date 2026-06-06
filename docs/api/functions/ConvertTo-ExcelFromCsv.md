# ConvertTo-ExcelFromCsv

## Synopsis

Converts CSV file to Excel.

## Description

Uses ImportExcel module or pandoc to convert a CSV file to Excel (XLSX) format.

## Signature

```powershell
ConvertTo-ExcelFromCsv
```

## Parameters

### -InputPath

Path to the input CSV file.

### -OutputPath

Path for the output Excel file. If not specified, uses input path with .xlsx extension.

### -SheetName

Name for the Excel sheet (default: Sheet1).


## Examples

### Example 1

`powershell
ConvertTo-ExcelFromCsv -InputPath "data.csv" -OutputPath "data.xlsx" -SheetName "Data"
``

## Aliases

This function has the following aliases:

- `csv-to-excel` - Converts CSV file to Excel.
- `csv-to-xlsx` - Converts CSV file to Excel.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-excel.ps1
