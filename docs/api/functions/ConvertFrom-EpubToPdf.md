# ConvertFrom-EpubToPdf

## Synopsis

Converts EPUB file to PDF.

## Description

Uses pandoc to convert an EPUB file to PDF format.

## Signature

```powershell
ConvertFrom-EpubToPdf
```

## Parameters

### -InputPath

The path to the EPUB file.

### -OutputPath

The path for the output PDF file. If not specified, uses input path with .pdf extension.


## Examples

### Example 1

```powershell
ConvertFrom-EpubToPdf -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `epub-to-pdf` - Converts EPUB file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-common-epub.ps1
