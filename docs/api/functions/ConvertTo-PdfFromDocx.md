# ConvertTo-PdfFromDocx

## Synopsis

Converts DOCX file to PDF.

## Description

Uses pandoc to convert a Microsoft Word DOCX file to PDF format.

## Signature

```powershell
ConvertTo-PdfFromDocx
```

## Parameters

### -InputPath

The path to the DOCX file.

### -OutputPath

The path for the output PDF file. If not specified, uses input path with .pdf extension.


## Examples

### Example 1

`powershell
ConvertTo-PdfFromDocx -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `docx-to-pdf` - Converts DOCX file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-common-docx.ps1
