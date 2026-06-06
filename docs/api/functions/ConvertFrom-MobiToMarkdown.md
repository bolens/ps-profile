# ConvertFrom-MobiToMarkdown

## Synopsis

Converts MOBI/AZW file to Markdown.

## Description

Uses pandoc to convert a MOBI/AZW file to Markdown format.

## Signature

```powershell
ConvertFrom-MobiToMarkdown
```

## Parameters

### -InputPath

Path to the input MOBI/AZW file.

### -OutputPath

Path for the output Markdown file. If not specified, uses input path with .md extension.


## Examples

### Example 1

`powershell
ConvertFrom-MobiToMarkdown -InputPath "book.mobi" -OutputPath "book.md"
``

## Aliases

This function has the following aliases:

- `azw-to-markdown` - Converts MOBI/AZW file to Markdown.
- `azw3-to-markdown` - Converts MOBI/AZW file to Markdown.
- `mobi-to-markdown` - Converts MOBI/AZW file to Markdown.


## Source

Defined in: ../profile.d/conversion-modules/document/document-ebook-mobi.ps1
