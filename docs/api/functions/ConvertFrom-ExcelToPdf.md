# ConvertFrom-ExcelToPdf

## Synopsis

Converts Excel file to PDF.

## Description

Uses pandoc or LibreOffice to convert an Excel file to PDF format.

## Signature

```powershell
ConvertFrom-ExcelToPdf
```

## Parameters

### -InputPath

Path to the input Excel file.

### -OutputPath

Path for the output PDF file. If not specified, uses input path with .pdf extension.

### -SheetName

Optional sheet name to convert. If not specified, converts the first sheet.


## Examples

### Example 1

`powershell
ConvertFrom-ExcelToPdf -InputPath "spreadsheet.xlsx" -OutputPath "spreadsheet.pdf"
``

## Aliases

This function has the following aliases:

- `excel-to-pdf` - Converts Excel file to PDF.
- `xls-to-pdf` - Converts Excel file to PDF.
- `xlsx-to-pdf` - Converts Excel file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-excel.ps1
