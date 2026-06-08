# ConvertFrom-EpubToLatex

## Synopsis

Converts EPUB file to LaTeX.

## Description

Uses pandoc to convert an EPUB file to LaTeX format.

## Signature

```powershell
ConvertFrom-EpubToLatex
```

## Parameters

### -InputPath

The path to the EPUB file.

### -OutputPath

The path for the output LaTeX file. If not specified, uses input path with .tex extension.


## Examples

### Example 1

`powershell
ConvertFrom-EpubToLatex -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `epub-to-latex` - Converts EPUB file to LaTeX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-common-epub.ps1
