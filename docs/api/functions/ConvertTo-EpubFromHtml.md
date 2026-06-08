# ConvertTo-EpubFromHtml

## Synopsis

Converts HTML file to EPUB.

## Description

Uses pandoc to convert an HTML file to EPUB (e-book) format.

## Signature

```powershell
ConvertTo-EpubFromHtml
```

## Parameters

### -InputPath

The path to the HTML file.

### -OutputPath

The path for the output EPUB file. If not specified, uses input path with .epub extension.


## Examples

### Example 1

```powershell
ConvertTo-EpubFromHtml -InputPath "book.html" -OutputPath "book.epub"
```

## Aliases

This function has the following aliases:

- `html-to-epub` - Converts HTML file to EPUB.


## Source

Defined in: ../profile.d/conversion-modules/document/document-common-epub.ps1
