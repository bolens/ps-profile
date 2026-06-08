# ConvertFrom-ExcelToHtml

## Synopsis

Converts Excel file to HTML.

## Description

Uses pandoc to convert an Excel file to HTML format.

## Signature

```powershell
ConvertFrom-ExcelToHtml
```

## Parameters

### -InputPath

Path to the input Excel file.

### -OutputPath

Path for the output HTML file. If not specified, uses input path with .html extension.

### -SheetName

Optional sheet name to convert. If not specified, converts the first sheet.


## Examples

### Example 1

```powershell
ConvertFrom-ExcelToHtml -InputPath "spreadsheet.xlsx" -OutputPath "spreadsheet.html"
```

## Aliases

This function has the following aliases:

- `excel-to-html` - Converts Excel file to HTML.
- `xls-to-html` - Converts Excel file to HTML.
- `xlsx-to-html` - Converts Excel file to HTML.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-excel.ps1
