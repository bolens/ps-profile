# ConvertFrom-OdtToMarkdown

## Synopsis

Converts ODT file to Markdown.

## Description

Uses pandoc to convert an ODT (OpenDocument Text) file to Markdown format.

## Signature

```powershell
ConvertFrom-OdtToMarkdown
```

## Parameters

### -InputPath

Path to the input ODT file.

### -OutputPath

Path for the output Markdown file. If not specified, uses input path with .md extension.


## Examples

### Example 1

```powershell
ConvertFrom-OdtToMarkdown -InputPath "document.odt" -OutputPath "document.md"
```

## Aliases

This function has the following aliases:

- `odt-to-markdown` - Converts ODT file to Markdown.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-odt.ps1
