# ConvertFrom-AsciidocToMarkdown

## Synopsis

Converts AsciiDoc file to Markdown.

## Description

Uses pandoc to convert an AsciiDoc file to Markdown format.

## Signature

```powershell
ConvertFrom-AsciidocToMarkdown
```

## Parameters

### -InputPath

Path to the input AsciiDoc file.

### -OutputPath

Path for the output Markdown file. If not specified, uses input path with .md extension.


## Examples

### Example 1

```powershell
ConvertFrom-AsciidocToMarkdown -InputPath "document.adoc" -OutputPath "document.md"
```

## Aliases

This function has the following aliases:

- `adoc-to-markdown` - Converts AsciiDoc file to Markdown.
- `asciidoc-to-markdown` - Converts AsciiDoc file to Markdown.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-asciidoc.ps1
