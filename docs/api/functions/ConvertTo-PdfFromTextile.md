# ConvertTo-PdfFromTextile

## Synopsis

Converts Textile file to PDF.

## Description

Uses pandoc to convert a Textile file to PDF format.

## Signature

```powershell
ConvertTo-PdfFromTextile
```

## Parameters

### -InputPath

The path to the Textile file (.textile or .tx extension).

### -OutputPath

The path for the output PDF file. If not specified, uses input path with .pdf extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertTo-PdfFromTextile -InputPath "document.textile"
    
    Converts document.textile to document.pdf.
``

## Aliases

This function has the following aliases:

- `textile-to-pdf` - Converts Textile file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-textile.ps1
