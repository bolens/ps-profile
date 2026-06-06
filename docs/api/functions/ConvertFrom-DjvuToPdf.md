# ConvertFrom-DjvuToPdf

## Synopsis

Converts DjVu file to PDF.

## Description

Converts a DjVu document file to PDF format using ImageMagick or djvulibre tools.

## Signature

```powershell
ConvertFrom-DjvuToPdf
```

## Parameters

### -InputPath

The path to the DjVu file (.djvu or .djv extension).

### -OutputPath

The path for the output PDF file. If not specified, uses input path with .pdf extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertFrom-DjvuToPdf -InputPath "document.djvu"
    
    Converts document.djvu to document.pdf.
``

## Aliases

This function has the following aliases:

- `djvu-to-pdf` - Converts DjVu file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-djvu.ps1
