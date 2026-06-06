# ConvertTo-LaTeXFromTextile

## Synopsis

Converts Textile file to LaTeX.

## Description

Uses pandoc to convert a Textile file to LaTeX format.

## Signature

```powershell
ConvertTo-LaTeXFromTextile
```

## Parameters

### -InputPath

The path to the Textile file (.textile or .tx extension).

### -OutputPath

The path for the output LaTeX file. If not specified, uses input path with .tex extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertTo-LaTeXFromTextile -InputPath "document.textile"
    
    Converts document.textile to document.tex.
``

## Aliases

This function has the following aliases:

- `textile-to-latex` - Converts Textile file to LaTeX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-textile.ps1
