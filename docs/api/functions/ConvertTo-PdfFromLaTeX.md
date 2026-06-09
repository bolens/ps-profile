# ConvertTo-PdfFromLaTeX

## Synopsis

Converts LaTeX file to PDF.

## Description

Uses pandoc to convert a LaTeX file to PDF format.

## Signature

```powershell
ConvertTo-PdfFromLaTeX
```

## Parameters

### -InputPath

The path to the LaTeX file.

### -OutputPath

The path for the output PDF file. If not specified, uses input path with .pdf extension.


## Examples

### Example 1

```powershell
ConvertTo-PdfFromLaTeX -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `latex-to-pdf` - Converts LaTeX file to PDF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-latex.ps1
