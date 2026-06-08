# ConvertFrom-AsciidocToHtml

## Synopsis

Converts AsciiDoc file to HTML.

## Description

Uses pandoc or asciidoc to convert an AsciiDoc file to HTML format.

## Signature

```powershell
ConvertFrom-AsciidocToHtml
```

## Parameters

### -InputPath

Path to the input AsciiDoc file.

### -OutputPath

Path for the output HTML file. If not specified, uses input path with .html extension.


## Examples

### Example 1

```powershell
ConvertFrom-AsciidocToHtml -InputPath "document.adoc" -OutputPath "document.html"
```

## Aliases

This function has the following aliases:

- `adoc-to-html` - Converts AsciiDoc file to HTML.
- `asciidoc-to-html` - Converts AsciiDoc file to HTML.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-asciidoc.ps1
