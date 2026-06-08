# ConvertTo-HtmlFromMarkdown

## Synopsis

Converts Markdown file to HTML.

## Description

Uses pandoc to convert a Markdown file to HTML format.

## Signature

```powershell
ConvertTo-HtmlFromMarkdown
```

## Parameters

### -InputPath

The path to the Markdown file.

### -OutputPath

The path for the output HTML file. If not specified, uses input path with .html extension.


## Examples

### Example 1

`powershell
ConvertTo-HtmlFromMarkdown -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `markdown-to-html` - Converts Markdown file to HTML.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown.ps1
