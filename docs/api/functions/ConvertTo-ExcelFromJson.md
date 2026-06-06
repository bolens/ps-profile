# ConvertTo-ExcelFromJson

## Synopsis

Converts JSON file to Excel.

## Description

Uses ImportExcel module to convert a JSON file to Excel (XLSX) format.

## Signature

```powershell
ConvertTo-ExcelFromJson
```

## Parameters

### -InputPath

Path to the input JSON file.

### -OutputPath

Path for the output Excel file. If not specified, uses input path with .xlsx extension.

### -SheetName

Name for the Excel sheet (default: Sheet1).


## Examples

### Example 1

`powershell
ConvertTo-ExcelFromJson -InputPath "data.json" -OutputPath "data.xlsx" -SheetName "Data"
``

## Aliases

This function has the following aliases:

- `json-to-excel` - Converts JSON file to Excel.
- `json-to-xlsx` - Converts JSON file to Excel.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-excel.ps1
