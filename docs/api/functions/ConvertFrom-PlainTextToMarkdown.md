# ConvertFrom-PlainTextToMarkdown

## Synopsis

Converts Plain Text file to Markdown.

## Description

Converts a Plain Text file to Markdown format, preserving content.

## Signature

```powershell
ConvertFrom-PlainTextToMarkdown
```

## Parameters

### -InputPath

Path to the input Plain Text file.

### -OutputPath

Path for the output Markdown file. If not specified, uses input path with .md extension.

### -Encoding

Text encoding of the input file (default: UTF8). Supports UTF8, UTF16, ASCII, etc.


## Examples

### Example 1

```powershell
ConvertFrom-PlainTextToMarkdown -InputPath "document.txt" -OutputPath "document.md" -Encoding UTF8
```

## Aliases

This function has the following aliases:

- `text-to-markdown` - Converts Plain Text file to Markdown.
- `txt-to-markdown` - Converts Plain Text file to Markdown.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-plaintext.ps1
