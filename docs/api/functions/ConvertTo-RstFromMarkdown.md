# ConvertTo-RstFromMarkdown

## Synopsis

Converts Markdown file to RST.

## Description

Uses pandoc to convert a Markdown file to reStructuredText (RST) format.

## Signature

```powershell
ConvertTo-RstFromMarkdown
```

## Parameters

### -InputPath

The path to the Markdown file.

### -OutputPath

The path for the output RST file. If not specified, uses input path with .rst extension.


## Examples

### Example 1

`powershell
ConvertTo-RstFromMarkdown -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `markdown-to-rst` - Converts Markdown file to RST.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown.ps1
