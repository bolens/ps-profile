# ConvertTo-RtfFromDocx

## Synopsis

Converts DOCX file to RTF.

## Description

Uses pandoc to convert a Microsoft Word DOCX file to RTF (Rich Text Format).

## Signature

```powershell
ConvertTo-RtfFromDocx
```

## Parameters

### -InputPath

Path to the input DOCX file.

### -OutputPath

Path for the output RTF file. If not specified, uses input path with .rtf extension.


## Examples

### Example 1

`powershell
ConvertTo-RtfFromDocx -InputPath "document.docx" -OutputPath "document.rtf"
``

## Aliases

This function has the following aliases:

- `docx-to-rtf` - Converts DOCX file to RTF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-rtf.ps1
