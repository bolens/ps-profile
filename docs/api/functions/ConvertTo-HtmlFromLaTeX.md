# ConvertTo-HtmlFromLaTeX

## Synopsis

Converts LaTeX file to HTML.

## Description

Uses pandoc to convert a LaTeX file to HTML format.

## Signature

```powershell
ConvertTo-HtmlFromLaTeX
```

## Parameters

### -InputPath

The path to the LaTeX file.

### -OutputPath

The path for the output HTML file. If not specified, uses input path with .html extension.


## Examples

### Example 1

```powershell
ConvertTo-HtmlFromLaTeX -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `latex-to-html` - Converts LaTeX file to HTML.


## Source

Defined in: ../profile.d/conversion-modules/document/document-latex.ps1
