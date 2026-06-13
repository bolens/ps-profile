# ConvertTo-LaTeXFromRst

## Synopsis

Converts RST file to LaTeX.

## Description

Uses pandoc to convert a reStructuredText (RST) file to LaTeX format.

## Signature

```powershell
ConvertTo-LaTeXFromRst
```

## Parameters

### -InputPath

The path to the RST file.

### -OutputPath

The path for the output LaTeX file. If not specified, uses input path with .tex extension.


## Examples

### Example 1

```powershell
ConvertTo-LaTeXFromRst -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `rst-to-latex` - Converts RST file to LaTeX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-rst.ps1
