# ConvertFrom-MobiToPdf

## Synopsis

Converts MOBI/AZW file to PDF.

## Description

Uses Calibre or pandoc to convert a MOBI/AZW file to PDF format.

## Signature

```powershell
ConvertFrom-MobiToPdf
```

## Parameters

### -InputPath

Path to the input MOBI/AZW file.

### -OutputPath

Path for the output PDF file. If not specified, uses input path with .pdf extension.


## Examples

### Example 1

`powershell
ConvertFrom-MobiToPdf -InputPath "book.mobi" -OutputPath "book.pdf"
``

## Aliases

This function has the following aliases:

- `azw-to-pdf` - Converts MOBI/AZW file to PDF.
- `azw3-to-pdf` - Converts MOBI/AZW file to PDF.
- `mobi-to-pdf` - Converts MOBI/AZW file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-ebook-mobi.ps1
