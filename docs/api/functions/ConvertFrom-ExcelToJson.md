# ConvertFrom-ExcelToJson

## Synopsis

Converts Excel file to JSON.

## Description

Uses ImportExcel module to convert an Excel file to JSON format.

## Signature

```powershell
ConvertFrom-ExcelToJson
```

## Parameters

### -InputPath

Path to the input Excel file.

### -OutputPath

Path for the output JSON file. If not specified, uses input path with .json extension.

### -SheetName

Optional sheet name to convert. If not specified, converts the first sheet.


## Examples

### Example 1

```powershell
ConvertFrom-ExcelToJson -InputPath "spreadsheet.xlsx" -OutputPath "spreadsheet.json"
```

## Aliases

This function has the following aliases:

- `excel-to-json` - Converts Excel file to JSON.
- `xls-to-json` - Converts Excel file to JSON.
- `xlsx-to-json` - Converts Excel file to JSON.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-excel.ps1
