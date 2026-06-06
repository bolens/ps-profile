# ConvertFrom-OdpToPdf

## Synopsis

Converts ODP file to PDF.

## Description

Uses pandoc or LibreOffice to convert an ODP file to PDF format.

## Signature

```powershell
ConvertFrom-OdpToPdf
```

## Parameters

### -InputPath

Path to the input ODP file.

### -OutputPath

Path for the output PDF file. If not specified, uses input path with .pdf extension.


## Examples

### Example 1

`powershell
ConvertFrom-OdpToPdf -InputPath "presentation.odp" -OutputPath "presentation.pdf"
``

## Aliases

This function has the following aliases:

- `odp-to-pdf` - Converts ODP file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-odp.ps1
