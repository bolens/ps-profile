# ConvertTo-ExcelFromOds

## Synopsis

Converts ODS file to Excel.

## Description

Uses pandoc to convert an ODS (OpenDocument Spreadsheet) file to Excel (XLSX) format.

## Signature

```powershell
ConvertTo-ExcelFromOds
```

## Parameters

### -InputPath

Path to the input ODS file.

### -OutputPath

Path for the output Excel file. If not specified, uses input path with .xlsx extension.

### -SheetName

Optional sheet name to convert. If not specified, converts the first sheet.


## Examples

### Example 1

`powershell
ConvertTo-ExcelFromOds -InputPath "spreadsheet.ods" -OutputPath "spreadsheet.xlsx"
``

## Aliases

This function has the following aliases:

- `ods-to-excel` - Converts ODS file to Excel.
- `ods-to-xlsx` - Converts ODS file to Excel.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-excel.ps1
