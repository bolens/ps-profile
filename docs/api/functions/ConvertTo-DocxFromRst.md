# ConvertTo-DocxFromRst

## Synopsis

Converts RST file to DOCX.

## Description

Uses pandoc to convert a reStructuredText (RST) file to Microsoft Word DOCX format.

## Signature

```powershell
ConvertTo-DocxFromRst
```

## Parameters

### -InputPath

The path to the RST file.

### -OutputPath

The path for the output DOCX file. If not specified, uses input path with .docx extension.


## Examples

### Example 1

```powershell
ConvertTo-DocxFromRst -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `rst-to-docx` - Converts RST file to DOCX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-rst.ps1
