# ConvertTo-RtfFromMarkdown

## Synopsis

Converts Markdown file to RTF.

## Description

Uses pandoc to convert a Markdown file to RTF (Rich Text Format).

## Signature

```powershell
ConvertTo-RtfFromMarkdown
```

## Parameters

### -InputPath

Path to the input Markdown file.

### -OutputPath

Path for the output RTF file. If not specified, uses input path with .rtf extension.


## Examples

### Example 1

`powershell
ConvertTo-RtfFromMarkdown -InputPath "document.md" -OutputPath "document.rtf"
``

## Aliases

This function has the following aliases:

- `markdown-to-rtf` - Converts Markdown file to RTF.
- `md-to-rtf` - Converts Markdown file to RTF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-rtf.ps1
