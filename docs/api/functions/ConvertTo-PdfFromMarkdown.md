# ConvertTo-PdfFromMarkdown

## Synopsis

Converts Markdown file to PDF.

## Description

Uses pandoc to convert a Markdown file to PDF format.

## Signature

```powershell
ConvertTo-PdfFromMarkdown
```

## Parameters

### -InputPath

The path to the Markdown file.

### -OutputPath

The path for the output PDF file. If not specified, uses input path with .pdf extension.


## Examples

### Example 1

`powershell
ConvertTo-PdfFromMarkdown -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `markdown-to-pdf` - Converts Markdown file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown.ps1
