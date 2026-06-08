# ConvertFrom-PdfToText

## Synopsis

Extracts text from PDF file.

## Description

Uses pdftotext to extract plain text from a PDF file.

## Signature

```powershell
ConvertFrom-PdfToText
```

## Parameters

### -InputPath

The path to the PDF file.

### -OutputPath

The path for the output text file. If not specified, uses input path with .txt extension.


## Examples

### Example 1

`powershell
ConvertFrom-PdfToText -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `pdf-to-text` - Extracts text from PDF file.


## Source

Defined in: ../profile.d/conversion-modules/media/pdf.ps1
