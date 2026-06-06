# ConvertFrom-OdtToLatex

## Synopsis

Converts ODT file to LaTeX.

## Description

Uses pandoc to convert an ODT file to LaTeX format.

## Signature

```powershell
ConvertFrom-OdtToLatex
```

## Parameters

### -InputPath

Path to the input ODT file.

### -OutputPath

Path for the output LaTeX file. If not specified, uses input path with .tex extension.


## Examples

### Example 1

`powershell
ConvertFrom-OdtToLatex -InputPath "document.odt" -OutputPath "document.tex"
``

## Aliases

This function has the following aliases:

- `odt-to-latex` - Converts ODT file to LaTeX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-odt.ps1
