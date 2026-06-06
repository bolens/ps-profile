# ConvertTo-MobiFromMarkdown

## Synopsis

Converts Markdown file to MOBI/AZW.

## Description

Uses Calibre or pandoc to convert a Markdown file to MOBI/AZW format.

## Signature

```powershell
ConvertTo-MobiFromMarkdown
```

## Parameters

### -InputPath

Path to the input Markdown file.

### -OutputPath

Path for the output MOBI/AZW file. If not specified, uses input path with appropriate extension.

### -Format

Output format: 'mobi', 'azw', or 'azw3' (default: 'mobi').


## Examples

### Example 1

`powershell
ConvertTo-MobiFromMarkdown -InputPath "book.md" -OutputPath "book.mobi" -Format mobi
``

## Aliases

This function has the following aliases:

- `markdown-to-azw` - Converts Markdown file to MOBI/AZW.
- `markdown-to-azw3` - Converts Markdown file to MOBI/AZW.
- `markdown-to-mobi` - Converts Markdown file to MOBI/AZW.
- `md-to-azw` - Converts Markdown file to MOBI/AZW.
- `md-to-azw3` - Converts Markdown file to MOBI/AZW.
- `md-to-mobi` - Converts Markdown file to MOBI/AZW.


## Source

Defined in: ../profile.d/conversion-modules/document/document-ebook-mobi.ps1
