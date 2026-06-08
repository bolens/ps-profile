# ConvertTo-PdfFromRst

## Synopsis

Converts RST file to PDF.

## Description

Uses pandoc to convert a reStructuredText (RST) file to PDF format.

## Signature

```powershell
ConvertTo-PdfFromRst
```

## Parameters

### -InputPath

The path to the RST file.

### -OutputPath

The path for the output PDF file. If not specified, uses input path with .pdf extension.


## Examples

### Example 1

```powershell
ConvertTo-PdfFromRst -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `rst-to-pdf` - Converts RST file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-rst.ps1
