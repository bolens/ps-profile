# ConvertFrom-RtfToDocx

## Synopsis

Converts RTF file to DOCX.

## Description

Uses pandoc to convert an RTF file to Microsoft Word DOCX format.

## Signature

```powershell
ConvertFrom-RtfToDocx
```

## Parameters

### -InputPath

Path to the input RTF file.

### -OutputPath

Path for the output DOCX file. If not specified, uses input path with .docx extension.


## Examples

### Example 1

```powershell
ConvertFrom-RtfToDocx -InputPath "document.rtf" -OutputPath "document.docx"
```

## Aliases

This function has the following aliases:

- `rtf-to-docx` - Converts RTF file to DOCX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-rtf.ps1
