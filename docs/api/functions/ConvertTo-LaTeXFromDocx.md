# ConvertTo-LaTeXFromDocx

## Synopsis

Converts DOCX file to LaTeX.

## Description

Uses pandoc to convert a Microsoft Word DOCX file to LaTeX format.

## Signature

```powershell
ConvertTo-LaTeXFromDocx
```

## Parameters

### -InputPath

The path to the DOCX file.

### -OutputPath

The path for the output LaTeX file. If not specified, uses input path with .tex extension.


## Examples

### Example 1

`powershell
ConvertTo-LaTeXFromDocx -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `docx-to-latex` - Converts DOCX file to LaTeX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-common-docx.ps1
