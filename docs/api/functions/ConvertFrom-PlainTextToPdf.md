# ConvertFrom-PlainTextToPdf

## Synopsis

Converts Plain Text file to PDF.

## Description

Uses pandoc to convert a Plain Text file to PDF format.

## Signature

```powershell
ConvertFrom-PlainTextToPdf
```

## Parameters

### -InputPath

Path to the input Plain Text file.

### -OutputPath

Path for the output PDF file. If not specified, uses input path with .pdf extension.

### -Encoding

Text encoding of the input file (default: UTF8).


## Examples

### Example 1

```powershell
ConvertFrom-PlainTextToPdf -InputPath "document.txt" -OutputPath "document.pdf"
```

## Aliases

This function has the following aliases:

- `text-to-pdf` - Converts Plain Text file to PDF.
- `txt-to-pdf` - Converts Plain Text file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-plaintext.ps1
