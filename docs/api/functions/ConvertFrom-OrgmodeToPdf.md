# ConvertFrom-OrgmodeToPdf

## Synopsis

Converts Org-mode file to PDF.

## Description

Uses pandoc to convert an Org-mode file to PDF format.

## Signature

```powershell
ConvertFrom-OrgmodeToPdf
```

## Parameters

### -InputPath

Path to the input Org-mode file.

### -OutputPath

Path for the output PDF file. If not specified, uses input path with .pdf extension.


## Examples

### Example 1

```powershell
ConvertFrom-OrgmodeToPdf -InputPath "document.org" -OutputPath "document.pdf"
```

## Aliases

This function has the following aliases:

- `org-to-pdf` - Converts Org-mode file to PDF.
- `orgmode-to-pdf` - Converts Org-mode file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-orgmode.ps1
