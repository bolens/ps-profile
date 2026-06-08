# ConvertTo-DocxFromLaTeX

## Synopsis

Converts LaTeX file to DOCX.

## Description

Uses pandoc to convert a LaTeX file to Microsoft Word DOCX format.

## Signature

```powershell
ConvertTo-DocxFromLaTeX
```

## Parameters

### -InputPath

The path to the LaTeX file.

### -OutputPath

The path for the output DOCX file. If not specified, uses input path with .docx extension.


## Examples

### Example 1

`powershell
ConvertTo-DocxFromLaTeX -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `latex-to-docx` - Converts LaTeX file to DOCX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-latex.ps1
