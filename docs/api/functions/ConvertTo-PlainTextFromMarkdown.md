# ConvertTo-PlainTextFromMarkdown

## Synopsis

Converts Markdown file to Plain Text.

## Description

Uses pandoc to convert a Markdown file to Plain Text format.

## Signature

```powershell
ConvertTo-PlainTextFromMarkdown
```

## Parameters

### -InputPath

Path to the input Markdown file.

### -OutputPath

Path for the output Plain Text file. If not specified, uses input path with .txt extension.

### -Encoding

Text encoding for the output file (default: UTF8).


## Examples

### Example 1

```powershell
ConvertTo-PlainTextFromMarkdown -InputPath "document.md" -OutputPath "document.txt" -Encoding UTF8
```

## Aliases

This function has the following aliases:

- `markdown-to-text` - Converts Markdown file to Plain Text.
- `markdown-to-txt` - Converts Markdown file to Plain Text.
- `md-to-text` - Converts Markdown file to Plain Text.
- `md-to-txt` - Converts Markdown file to Plain Text.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-plaintext.ps1
