# ConvertTo-PdfFromFb2

## Synopsis

Converts FB2 file to PDF.

## Description

Uses pandoc to convert a FictionBook (FB2) e-book file to PDF format.

## Signature

```powershell
ConvertTo-PdfFromFb2
```

## Parameters

### -InputPath

The path to the FB2 file (.fb2 or .fbz extension).

### -OutputPath

The path for the output PDF file. If not specified, uses input path with .pdf extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertTo-PdfFromFb2 -InputPath "book.fb2"
    
    Converts book.fb2 to book.pdf.
``

## Aliases

This function has the following aliases:

- `fb2-to-pdf` - Converts FB2 file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-fb2.ps1
