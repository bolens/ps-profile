# ConvertFrom-AsciidocToLatex

## Synopsis

Converts AsciiDoc file to LaTeX.

## Description

Uses pandoc to convert an AsciiDoc file to LaTeX format.

## Signature

```powershell
ConvertFrom-AsciidocToLatex
```

## Parameters

### -InputPath

Path to the input AsciiDoc file.

### -OutputPath

Path for the output LaTeX file. If not specified, uses input path with .tex extension.


## Examples

### Example 1

```powershell
ConvertFrom-AsciidocToLatex -InputPath "document.adoc" -OutputPath "document.tex"
```

## Aliases

This function has the following aliases:

- `adoc-to-latex` - Converts AsciiDoc file to LaTeX.
- `asciidoc-to-latex` - Converts AsciiDoc file to LaTeX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-asciidoc.ps1
