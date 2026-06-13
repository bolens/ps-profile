# ConvertFrom-MobiToHtml

## Synopsis

Converts MOBI/AZW file to HTML.

## Description

Uses Calibre or pandoc to convert a MOBI/AZW file to HTML format.

## Signature

```powershell
ConvertFrom-MobiToHtml
```

## Parameters

### -InputPath

Path to the input MOBI/AZW file.

### -OutputPath

Path for the output HTML file. If not specified, uses input path with .html extension.


## Examples

### Example 1

```powershell
ConvertFrom-MobiToHtml -InputPath "book.mobi" -OutputPath "book.html"
```

## Aliases

This function has the following aliases:

- `azw-to-html` - Converts MOBI/AZW file to HTML.
- `azw3-to-html` - Converts MOBI/AZW file to HTML.
- `mobi-to-html` - Converts MOBI/AZW file to HTML.


## Source

Defined in: ../profile.d/conversion-modules/document/document-ebook-mobi.ps1
