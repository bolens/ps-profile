# ConvertFrom-OdsToPdf

## Synopsis

Converts ODS file to PDF.

## Description

Uses pandoc or LibreOffice to convert an ODS file to PDF format.

## Signature

```powershell
ConvertFrom-OdsToPdf
```

## Parameters

### -InputPath

Path to the input ODS file.

### -OutputPath

Path for the output PDF file. If not specified, uses input path with .pdf extension.


## Examples

### Example 1

`powershell
ConvertFrom-OdsToPdf -InputPath "spreadsheet.ods" -OutputPath "spreadsheet.pdf"
``

## Aliases

This function has the following aliases:

- `ods-to-pdf` - Converts ODS file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-ods.ps1
