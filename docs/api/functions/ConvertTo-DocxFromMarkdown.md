# ConvertTo-DocxFromMarkdown

## Synopsis

Converts Markdown file to DOCX.

## Description

Uses pandoc to convert a Markdown file to Microsoft Word DOCX format.

## Signature

```powershell
ConvertTo-DocxFromMarkdown
```

## Parameters

### -InputPath

The path to the Markdown file.

### -OutputPath

The path for the output DOCX file. If not specified, uses input path with .docx extension.


## Examples

### Example 1

`powershell
ConvertTo-DocxFromMarkdown -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `markdown-to-docx` - Converts Markdown file to DOCX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown.ps1
