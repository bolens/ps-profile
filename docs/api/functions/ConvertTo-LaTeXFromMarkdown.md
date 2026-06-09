# ConvertTo-LaTeXFromMarkdown

## Synopsis

Converts Markdown file to LaTeX.

## Description

Uses pandoc to convert a Markdown file to LaTeX format.

## Signature

```powershell
ConvertTo-LaTeXFromMarkdown
```

## Parameters

### -InputPath

The path to the Markdown file.

### -OutputPath

The path for the output LaTeX file. If not specified, uses input path with .tex extension.


## Examples

### Example 1

```powershell
ConvertTo-LaTeXFromMarkdown -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `markdown-to-latex` - Converts Markdown file to LaTeX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown.ps1
