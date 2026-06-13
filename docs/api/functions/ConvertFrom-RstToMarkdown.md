# ConvertFrom-RstToMarkdown

## Synopsis

Converts RST file to Markdown.

## Description

Uses pandoc to convert a reStructuredText (RST) file to Markdown format.

## Signature

```powershell
ConvertFrom-RstToMarkdown
```

## Parameters

### -InputPath

The path to the RST file.

### -OutputPath

The path for the output Markdown file. If not specified, uses input path with .md extension.


## Examples

### Example 1

```powershell
ConvertFrom-RstToMarkdown -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `rst-to-markdown` - Converts RST file to Markdown.


## Source

Defined in: ../profile.d/conversion-modules/document/document-rst.ps1
