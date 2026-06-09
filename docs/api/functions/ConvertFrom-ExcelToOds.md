# ConvertFrom-ExcelToOds

## Synopsis

Converts Excel file to ODS.

## Description

Uses pandoc to convert an Excel file to ODS (OpenDocument Spreadsheet) format.

## Signature

```powershell
ConvertFrom-ExcelToOds
```

## Parameters

### -InputPath

Path to the input Excel file.

### -OutputPath

Path for the output ODS file. If not specified, uses input path with .ods extension.

### -SheetName

Optional sheet name to convert. If not specified, converts the first sheet.


## Examples

### Example 1

```powershell
ConvertFrom-ExcelToOds -InputPath "spreadsheet.xlsx" -OutputPath "spreadsheet.ods"
```

## Aliases

This function has the following aliases:

- `excel-to-ods` - Converts Excel file to ODS.
- `xls-to-ods` - Converts Excel file to ODS.
- `xlsx-to-ods` - Converts Excel file to ODS.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-excel.ps1
