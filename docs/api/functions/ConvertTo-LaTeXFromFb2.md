# ConvertTo-LaTeXFromFb2

## Synopsis

Converts FB2 file to LaTeX.

## Description

Uses pandoc to convert a FictionBook (FB2) e-book file to LaTeX format.

## Signature

```powershell
ConvertTo-LaTeXFromFb2
```

## Parameters

### -InputPath

The path to the FB2 file (.fb2 or .fbz extension).

### -OutputPath

The path for the output LaTeX file. If not specified, uses input path with .tex extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertTo-LaTeXFromFb2 -InputPath "book.fb2"
```

Converts book.fb2 to book.tex.

## Aliases

This function has the following aliases:

- `fb2-to-latex` - Converts FB2 file to LaTeX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-fb2.ps1
