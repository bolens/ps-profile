# ConvertFrom-RtfToPdf

## Synopsis

Converts RTF file to PDF.

## Description

Uses pandoc to convert an RTF file to PDF format.

## Signature

```powershell
ConvertFrom-RtfToPdf
```

## Parameters

### -InputPath

Path to the input RTF file.

### -OutputPath

Path for the output PDF file. If not specified, uses input path with .pdf extension.


## Examples

### Example 1

`powershell
ConvertFrom-RtfToPdf -InputPath "document.rtf" -OutputPath "document.pdf"
``

## Aliases

This function has the following aliases:

- `rtf-to-pdf` - Converts RTF file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-rtf.ps1
