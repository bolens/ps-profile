# ConvertFrom-AsciidocToPdf

## Synopsis

Converts AsciiDoc file to PDF.

## Description

Uses pandoc or asciidoctor-pdf to convert an AsciiDoc file to PDF format.

## Signature

```powershell
ConvertFrom-AsciidocToPdf
```

## Parameters

### -InputPath

Path to the input AsciiDoc file.

### -OutputPath

Path for the output PDF file. If not specified, uses input path with .pdf extension.


## Examples

### Example 1

```powershell
ConvertFrom-AsciidocToPdf -InputPath "document.adoc" -OutputPath "document.pdf"
```

## Aliases

This function has the following aliases:

- `adoc-to-pdf` - Converts AsciiDoc file to PDF.
- `asciidoc-to-pdf` - Converts AsciiDoc file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-asciidoc.ps1
