# ConvertTo-PdfFromHtml

## Synopsis

Converts HTML file to PDF.

## Description

Uses pandoc to convert an HTML file to PDF format.

## Signature

```powershell
ConvertTo-PdfFromHtml
```

## Parameters

### -InputPath

The path to the HTML file.

### -OutputPath

The path for the output PDF file. If not specified, uses input path with .pdf extension.


## Examples

### Example 1

`powershell
ConvertTo-PdfFromHtml -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `html-to-pdf` - Converts HTML file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-common-html.ps1
