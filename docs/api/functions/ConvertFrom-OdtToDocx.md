# ConvertFrom-OdtToDocx

## Synopsis

Converts ODT file to DOCX.

## Description

Uses pandoc to convert an ODT file to Microsoft Word DOCX format.

## Signature

```powershell
ConvertFrom-OdtToDocx
```

## Parameters

### -InputPath

Path to the input ODT file.

### -OutputPath

Path for the output DOCX file. If not specified, uses input path with .docx extension.


## Examples

### Example 1

```powershell
ConvertFrom-OdtToDocx -InputPath "document.odt" -OutputPath "document.docx"
```

## Aliases

This function has the following aliases:

- `odt-to-docx` - Converts ODT file to DOCX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-odt.ps1
