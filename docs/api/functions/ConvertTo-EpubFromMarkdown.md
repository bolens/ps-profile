# ConvertTo-EpubFromMarkdown

## Synopsis

Converts Markdown file to EPUB.

## Description

Uses pandoc to convert a Markdown file to EPUB (e-book) format.

## Signature

```powershell
ConvertTo-EpubFromMarkdown
```

## Parameters

### -InputPath

The path to the Markdown file.

### -OutputPath

The path for the output EPUB file. If not specified, uses input path with .epub extension.


## Examples

### Example 1

`powershell
ConvertTo-EpubFromMarkdown -InputPath "book.md" -OutputPath "book.epub"
``

## Aliases

This function has the following aliases:

- `markdown-to-epub` - Converts Markdown file to EPUB.
- `md-to-epub` - Converts Markdown file to EPUB.


## Source

Defined in: ../profile.d/conversion-modules/document/document-common-epub.ps1
