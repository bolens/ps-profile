# ConvertFrom-OrgmodeToDocx

## Synopsis

Converts Org-mode file to DOCX.

## Description

Uses pandoc to convert an Org-mode file to Microsoft Word DOCX format.

## Signature

```powershell
ConvertFrom-OrgmodeToDocx
```

## Parameters

### -InputPath

Path to the input Org-mode file.

### -OutputPath

Path for the output DOCX file. If not specified, uses input path with .docx extension.


## Examples

### Example 1

`powershell
ConvertFrom-OrgmodeToDocx -InputPath "document.org" -OutputPath "document.docx"
``

## Aliases

This function has the following aliases:

- `org-to-docx` - Converts Org-mode file to DOCX.
- `orgmode-to-docx` - Converts Org-mode file to DOCX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-orgmode.ps1
