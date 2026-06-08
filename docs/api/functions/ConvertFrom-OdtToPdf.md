# ConvertFrom-OdtToPdf

## Synopsis

Converts ODT file to PDF.

## Description

Uses pandoc to convert an ODT file to PDF format.

## Signature

```powershell
ConvertFrom-OdtToPdf
```

## Parameters

### -InputPath

Path to the input ODT file.

### -OutputPath

Path for the output PDF file. If not specified, uses input path with .pdf extension.


## Examples

### Example 1

```powershell
ConvertFrom-OdtToPdf -InputPath "document.odt" -OutputPath "document.pdf"
```

## Aliases

This function has the following aliases:

- `odt-to-pdf` - Converts ODT file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-odt.ps1
