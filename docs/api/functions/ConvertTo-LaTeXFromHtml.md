# ConvertTo-LaTeXFromHtml

## Synopsis

Converts HTML file to LaTeX.

## Description

Uses pandoc to convert an HTML file to LaTeX format.

## Signature

```powershell
ConvertTo-LaTeXFromHtml
```

## Parameters

### -InputPath

The path to the HTML file.

### -OutputPath

The path for the output LaTeX file. If not specified, uses input path with .tex extension.


## Examples

### Example 1

`powershell
ConvertTo-LaTeXFromHtml -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `html-to-latex` - Converts HTML file to LaTeX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-common-html.ps1
