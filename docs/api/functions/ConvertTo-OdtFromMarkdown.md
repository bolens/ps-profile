# ConvertTo-OdtFromMarkdown

## Synopsis

Converts Markdown file to ODT.

## Description

Uses pandoc to convert a Markdown file to ODT (OpenDocument Text) format.

## Signature

```powershell
ConvertTo-OdtFromMarkdown
```

## Parameters

### -InputPath

Path to the input Markdown file.

### -OutputPath

Path for the output ODT file. If not specified, uses input path with .odt extension.


## Examples

### Example 1

```powershell
ConvertTo-OdtFromMarkdown -InputPath "document.md" -OutputPath "document.odt"
```

## Aliases

This function has the following aliases:

- `markdown-to-odt` - Converts Markdown file to ODT.
- `md-to-odt` - Converts Markdown file to ODT.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-odt.ps1
