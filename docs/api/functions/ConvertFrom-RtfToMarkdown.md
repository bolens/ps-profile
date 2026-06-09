# ConvertFrom-RtfToMarkdown

## Synopsis

Converts RTF file to Markdown.

## Description

Uses pandoc to convert an RTF (Rich Text Format) file to Markdown format.

## Signature

```powershell
ConvertFrom-RtfToMarkdown
```

## Parameters

### -InputPath

Path to the input RTF file.

### -OutputPath

Path for the output Markdown file. If not specified, uses input path with .md extension.


## Examples

### Example 1

```powershell
ConvertFrom-RtfToMarkdown -InputPath "document.rtf" -OutputPath "document.md"
```

## Aliases

This function has the following aliases:

- `rtf-to-markdown` - Converts RTF file to Markdown.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-rtf.ps1
