# ConvertTo-AsciidocFromMarkdown

## Synopsis

Converts Markdown file to AsciiDoc.

## Description

Uses pandoc to convert a Markdown file to AsciiDoc format.

## Signature

```powershell
ConvertTo-AsciidocFromMarkdown
```

## Parameters

### -InputPath

Path to the input Markdown file.

### -OutputPath

Path for the output AsciiDoc file. If not specified, uses input path with .adoc extension.


## Examples

### Example 1

`powershell
ConvertTo-AsciidocFromMarkdown -InputPath "document.md" -OutputPath "document.adoc"
``

## Aliases

This function has the following aliases:

- `markdown-to-adoc` - Converts Markdown file to AsciiDoc.
- `markdown-to-asciidoc` - Converts Markdown file to AsciiDoc.
- `md-to-adoc` - Converts Markdown file to AsciiDoc.
- `md-to-asciidoc` - Converts Markdown file to AsciiDoc.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-asciidoc.ps1
